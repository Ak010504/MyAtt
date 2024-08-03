import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subject;

  SubjectDetailsScreen({required this.subject});

  @override
  _SubjectDetailsScreenState createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  late Map<DateTime, List<String>> _attendanceRecords = {};
  DateTime _focusedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  void _fetchAttendanceRecords() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (querySnapshot.exists) {
      String sec = querySnapshot.get('sec');
      String regno = querySnapshot.get('regno');

      DocumentSnapshot<Map<String, dynamic>> subjectSnapshot =
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(sec)
              .collection(regno)
              .doc(widget.subject)
              .get();

      Map<DateTime, List<String>> attendanceRecords = {};
      if (subjectSnapshot.exists) {
        Map<String, dynamic> subjectData = subjectSnapshot.data()!;
        subjectData.forEach((key, value) {
          if (key != "totalClasses" && key != "percentage") {
            // Split key to separate date part
            String dateString = key.split(" ")[0]; // "14-7-2024"
            DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);
            String status =
                value.toString().toLowerCase(); // Convert status to lowercase
            if (attendanceRecords[date] == null) {
              attendanceRecords[date] = [];
            }
            attendanceRecords[date]!.add(status);
          }
        });
      }

      setState(() {
        _attendanceRecords = attendanceRecords;
      });
    }
  }

  void _onPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
    _fetchAttendanceRecords(); // Fetch records again for the new month
  }

  void _onNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
    _fetchAttendanceRecords(); // Fetch records again for the new month
  }

  List<Widget> _buildDaysOfWeek() {
    List<String> daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return daysOfWeek.map((day) => Center(child: Text(day))).toList();
  }

  List<Widget> _buildCalendarDays() {
    int daysInMonth =
        DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    DateTime firstDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month, 1);
    int firstWeekday = firstDayOfMonth.weekday % 7; // Sunday is 0
    List<Widget> dayWidgets = [];

    // Fill empty slots before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Fill actual days
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(_focusedDate.year, _focusedDate.month, day);
      List<String> statuses = _attendanceRecords[date] ?? [];
      List<Widget> dots = [];

      // Create dots for each status
      for (String status in statuses) {
        Color dotColor;
        if (status == 'p') {
          dotColor = Colors.green;
        } else if (status == 'a') {
          dotColor = Colors.red;
        } else {
          dotColor = Colors.transparent;
        }
        dots.add(Container(
          margin: EdgeInsets.symmetric(horizontal: 1),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ));
      }

      dayWidgets.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(color: Colors.black),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dots,
            ),
          ],
        ),
      ));
    }

    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _onPreviousMonth,
                ),
                Text(
                  DateFormat.yMMMM().format(_focusedDate),
                  style: TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _onNextMonth,
                ),
              ],
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              children: _buildDaysOfWeek(),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              children: _buildCalendarDays(),
            ),
          ],
        ),
      ),
    );
  }
}
