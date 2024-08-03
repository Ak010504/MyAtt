import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/auth/auth_service.dart';
import 'package:attendance/auth/login_screen.dart';
import 'package:attendance/student_profile.dart';
import 'package:attendance/subjectDetailsScreen.dart';

class StudentLog extends StatefulWidget {
  const StudentLog({Key? key}) : super(key: key);

  @override
  State<StudentLog> createState() => _StudentLogState();
}

class _StudentLogState extends State<StudentLog> {
  Map<String, dynamic> _timetableData = {};
  String? _userNameInitials;
  double _totalAttendance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadUserNameInitials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "STUDENT",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        centerTitle: true,
        actions: <Widget>[
          if (_userNameInitials != null)
            GestureDetector(
              onTap: () {
                _openPopupMenu(context);
              },
              child: Container(
                margin: EdgeInsets.only(
                    right: 16, left: 1), // Adjust left margin here
                padding: EdgeInsets.all(5),
                child: CircleAvatar(
                  child: Text(
                    _userNameInitials!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAttendancePercentageCircle(),
                    const SizedBox(height: 20),
                    Text(
                      "Attendance Percent ",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timetableData.length,
              itemBuilder: (BuildContext context, int index) {
                final subject = _timetableData.keys.elementAt(index);
                final percentage = _timetableData[subject]['percentage'];
                if (subject == 'info') {
                  return Container(); // Return an empty container to avoid building
                }
                return _buildSubjectAttendanceCard(subject, percentage);
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }

  Widget _buildAttendancePercentageCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          child: CircularProgressIndicator(
            value: _totalAttendance / 100,
            strokeWidth: 8,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          width: 80,
          height: 80,
        ),
        Text(
          _totalAttendance.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectAttendanceCard(String subject, double? percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 16.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: ListTile(
          title: Text(
            subject,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            _getCurrentDate(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          trailing: _buildCircularIndicator(percentage),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubjectDetailsScreen(subject: subject),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircularIndicator(double? percentage) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: percentage != null ? percentage / 100.0 : 0,
          strokeWidth: 6,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            (percentage != null && percentage >= 75)
                ? Colors.lightGreen
                : Colors.redAccent,
          ),
        ),
        Text(
          '${(percentage != null) ? '${percentage.toStringAsFixed(0)}' : 'N/A'}',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _fetchData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (querySnapshot.exists) {
        String sec = querySnapshot.get('sec');
        String regno = querySnapshot.get('regno');

        QuerySnapshot<Map<String, dynamic>> timetableSnapshot =
            await FirebaseFirestore.instance
                .collection('classes')
                .doc(sec)
                .collection(regno)
                .get();

        Map<String, dynamic> timetableData = {};
        double totalPercentage = 0.0;
        int subjectCount = 0;

        timetableSnapshot.docs.forEach((document) {
          timetableData[document.id] = document.data();
          if (document.data().containsKey('percentage')) {
            totalPercentage += document.get('percentage');
            subjectCount++;
          }
        });

        setState(() {
          _timetableData = timetableData;
          _totalAttendance =
              subjectCount > 0 ? totalPercentage / subjectCount : 0.0;
        });
      } else {
        print('User document for $userId does not exist.');
        setState(() {
          _timetableData = {};
        });
      }
    } catch (error) {
      print('Error fetching timetable data: $error');
    }
  }

  String _getCurrentDate() {
    DateTime now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _loadUserNameInitials() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        String fullName = userSnapshot.get('name');
        if (fullName.isNotEmpty) {
          List<String> nameParts = fullName.split(' ');
          String initials = nameParts.map((e) => e[0]).join('');
          setState(() {
            _userNameInitials = initials.toUpperCase();
          });
        }
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }
  }

  void _openPopupMenu(BuildContext context) {
    final RenderBox appBarRenderBox = context.findRenderObject() as RenderBox;
    final Offset offset = appBarRenderBox.localToGlobal(
      Offset(appBarRenderBox.size.width - 40, kToolbarHeight),
      ancestor: context.findRenderObject(),
    );
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy + 50, 20, 0),
      items: [
        PopupMenuItem(
          value: 'Profile',
          child: Text('Profile'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentProfile(
                    userId: FirebaseAuth.instance.currentUser!.uid),
              ),
            );
          },
        ),
        PopupMenuItem(
          value: 'Logout',
          child: Text('Logout'),
          onTap: () {
            _logout(context);
          },
        ),
      ],
    );
  }
}
