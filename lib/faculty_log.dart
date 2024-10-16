import 'package:attendance/faculty_profile.dart';
import 'package:attendance/hod_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance/timetable.dart';
import 'package:attendance/auth/auth_service.dart';
import 'package:attendance/auth/login_screen.dart';
import 'package:attendance/report.dart';
import 'package:attendance/test.dart';
import 'package:attendance/timetable_display.dart';

class FacultyLog extends StatefulWidget {
  const FacultyLog({Key? key}) : super(key: key);

  @override
  State<FacultyLog> createState() => _FacultyLogState();
}

class _FacultyLogState extends State<FacultyLog> {
  late Map<String, dynamic> _timetableData = {}; // To store timetable data
  late DateTime _selectedDate = DateTime.now(); // To store selected date
  String? _userNameInitials;

  @override
  void initState() {
    super.initState();
    // Fetch timetable data for the current user's initials
    _fetchTimetableData(_selectedDate);
    _loadUserNameInitials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FACULTY",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 106, 141, 227),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8CC0FF), // Top color of the gradient
                  Color(0xFF3A48D5), // Bottom color of the gradient
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _timetableData.length,
                  itemBuilder: (BuildContext context, int index) {
                    // Get the key and value at the current index
                    String key = _timetableData.keys.elementAt(index);
                    List<dynamic> data = _timetableData[key]!;

                    // Create button with data
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Stack(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectDetailsWidget(
                                      subject: data[0],
                                      section: data[3],
                                      time: data[1],
                                      selectedDate: _selectedDate,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(40.0),
                                backgroundColor: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: 40),
                                      Expanded(
                                        // Add Expanded or Flexible here
                                        child: Text(
                                          'Subject: ${data[0]}',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 28, 61, 88),
                                            fontSize: 16.0,
                                          ),
                                          softWrap:
                                              true, // Allows wrapping to the next line
                                          overflow: TextOverflow
                                              .visible, // Makes sure the text is visible
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  if (data[2] != null && data[2].isNotEmpty)
                                    Row(
                                      children: [
                                        SizedBox(width: 40),
                                        Text(
                                          'Room No: ${data[2]}',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 28, 61, 88),
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      SizedBox(width: 40),
                                      Text(
                                        'Time: ${data[1]}',
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 28, 61, 88),
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      SizedBox(width: 40),
                                      Text(
                                        'Section: ${data[3]}',
                                        style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 28, 61, 88),
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  if (data[4] == 'yes')
                                    Row(
                                      children: [
                                        SizedBox(width: 40),
                                        Text(
                                          'Substitution',
                                          style: TextStyle(
                                            color:
                                                Color.fromARGB(255, 28, 61, 88),
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 50,
                              right: 8,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(
                                      context, key, data);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  String _formatDay(DateTime date) {
    return DateFormat('EEEE').format(date).toLowerCase();
  }

  // Fetch timetable data for the given date
  void _fetchTimetableData(DateTime date) async {
    try {
      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Query Firestore for timetable data for the current user's initials
      DocumentSnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('users') // Parent collection
              .doc(userId) // Document corresponding to the current user
              .get();

      // Check if the document exists
      if (querySnapshot.exists) {
        // Extract the initials from the document
        String initials = querySnapshot.get('initials');

        // Query Firestore for timetable data using the initials as the document ID
        DocumentSnapshot<Map<String, dynamic>> timetableSnapshot =
            await FirebaseFirestore.instance
                .collection('users') // Parent collection
                .doc(userId) // Document corresponding to the current user
                .collection(initials) // Subcollection using initials
                .doc(_formatDay(date)) // Use the given date's day
                .get();

        // Check if the timetable document exists
        if (timetableSnapshot.exists) {
          // Extract the timetable data from the snapshot
          Map<String, dynamic> timetableData = timetableSnapshot.data()!;

          // Store the fetched data
          DateTime currentDate = DateTime.now();
          timetableData.removeWhere((key, value) {
            if (value[4] == 'yes') {
              DateTime periodDate = DateTime.parse(value[5]);
              return !isSameDay(periodDate, _selectedDate);
            }
            return false;
          });
          setState(() {
            _timetableData = timetableData; // Store data with initials as key
          });
        } else {
          // Timetable document does not exist, handle this scenario
          print('Timetable data for $initials does not exist.');
          // You can set _timetableData to an empty Map or handle it as needed based on your app logic
          setState(() {
            _timetableData = {};
          });
        }
      } else {
        // Document does not exist, handle this scenario
        print('User document for $userId does not exist.');
        // You can set _timetableData to an empty Map or handle it as needed based on your app logic
        setState(() {
          _timetableData = {};
        });
      }
    } catch (error) {
      print('Error fetching timetable data: $error');
      // Handle any errors that occur during fetching
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      _fetchTimetableData(pickedDate);
    }
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
        PopupMenuItem<String>(
          value: 'Profile',
          height: 50,
          child: const Text('Profile'),
          onTap: () {
            Navigator.pushNamed(context, '/quotes1');
          },
        ),
        PopupMenuItem<String>(
          value: 'TimeTable',
          height: 50,
          child: Text('TimeTable'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TimetableDisplay()),
            );
          },
        ),
        PopupMenuItem<String>(
          value: 'Report',
          height: 50,
          child: Text('Report'),
          onTap: () {
            _openReport(context);
          },
        ),
        PopupMenuItem<String>(
          value: 'Add Classes',
          height: 50,
          child: const Text('Add Classes'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
        ),
        PopupMenuItem<String>(
          value: 'Previous',
          height: 50,
          child: Text('Edit Attendance'),
          onTap: () {
            _selectDate(context);
          },
        ),
        PopupMenuItem<String>(
          value: 'Logout',
          height: 50,
          child: Text('Logout'),
          onTap: () {
            _logout(context);
          },
        ),
      ],
    );
  }

  void _openReport(BuildContext context) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        String role = userSnapshot.get('role');
        if (role == 'hod') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HodReport()),
          );
        } else if (role == 'faculty') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FacultyReport()),
          );
        }
      }
    } catch (error) {
      print('Error fetching user role: $error');
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String key, List<dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Period'),
          content: Text('Do you want to delete this period?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePeriod(key);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePeriod(String key) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        String initials = userSnapshot.get('initials');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(initials)
            .doc(_formatDay(_selectedDate))
            .update({
          key: FieldValue.delete(), // Remove the specific period
        });
        setState(() {
          _timetableData.remove(key); // Update local state
        });
      }
    } catch (error) {
      print('Error deleting period: $error');
    }
  }
}
