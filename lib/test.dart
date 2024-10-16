import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/faculty_log.dart';

class SubjectDetailsWidget extends StatefulWidget {
  final String subject;
  final String section;
  final String time;
  final DateTime? selectedDate;

  const SubjectDetailsWidget({
    required this.subject,
    required this.section,
    required this.time,
    this.selectedDate,
    Key? key,
  }) : super(key: key);

  @override
  _SubjectDetailsWidgetState createState() => _SubjectDetailsWidgetState();
}

class _SubjectDetailsWidgetState extends State<SubjectDetailsWidget> {
  Map<String, bool> buttonStates = {};
  Map<String, String> attendanceData = {};
  Map<String, String> studentNames = {};
  List<String> sortedKeys = [];
  bool isLoading = true;
  bool hasShownError = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final date = widget.selectedDate ?? DateTime.now();
    final formattedDate = '${date.day}-${date.month}-${date.year}';

    try {
      final classDoc =
          FirebaseFirestore.instance.collection('classes').doc(widget.section);
      final snapshot = await classDoc.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final List<String> keys = [];
          final List<Future<void>> futures = [];

          data.forEach((key, value) {
            if (value is List<dynamic>) {
              String roll = value[0];
              String name = value[1];
              studentNames[roll] = name;
              keys.add(roll);

              futures
                  .add(_fetchStudentAttendance(classDoc, roll, formattedDate));
            }
          });

          await Future.wait(futures);

          keys.sort((a, b) {
            String lastThreeDigitsA = a.padLeft(3, '0').substring(a.length - 3);
            String lastThreeDigitsB = b.padLeft(3, '0').substring(b.length - 3);
            return lastThreeDigitsA.compareTo(lastThreeDigitsB);
          });

          setState(() {
            sortedKeys = keys;
            isLoading = false;
            hasShownError = false; // Reset error flag when data is loaded
          });
        }
      }
    } catch (error) {
      print('Error fetching timetable data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching timetable data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchStudentAttendance(
    DocumentReference classDoc,
    String roll,
    String formattedDate,
  ) async {
    try {
      final studentDoc = classDoc.collection(roll).doc(widget.subject);
      final snapshot = await studentDoc.get();
      var attendance = false;
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          for (var key in data.keys) {
            print(key.split(" -")[0].split(" "));
            if (key.split(' -')[0] ==
                formattedDate + " " + widget.time.split('-')[0].split(' ')[0]) {
              attendanceData[roll] = data[key] == 'p' ? 'p' : 'a';
              buttonStates[roll] = data[key] != 'p';
              attendance = true;
              _showErrorOnce("Attendance already taken");
              return;
            } else if (key.split(" -")[0].split(" ")[0] == formattedDate) {
              attendanceData[roll] = data[key] == 'p' ? 'p' : 'a';
              buttonStates[roll] = data[key] != 'p';
              attendance = true;
              _showErrorOnce("Last class attendance");
              return;
            }
          }
        }
      }

      if (attendance == false) {
        final subdoc = classDoc.collection(roll);
        final qry = await subdoc.get();
        List<String> subjectNames = qry.docs.map((doc) => doc.id).toList();
        for (var i in subjectNames) {
          var attdoc = subdoc.doc(i);
          var attsnap = await attdoc.get();
          if (attsnap.exists) {
            final data = attsnap.data();
            if (data != null) {
              for (var key in data.keys) {
                if (key.split(" -")[0].split(" ")[0] == formattedDate) {
                  attendanceData[roll] = data[key] == 'p' ? 'p' : 'a';
                  buttonStates[roll] = data[key] != 'p';
                  attendance = true;
                  _showErrorOnce("Last Class Attendance");
                  return;
                }
              }
            }
          }
        }
      }

      attendanceData[roll] = 'p'; // Default to 'p' if no data exists
      buttonStates[roll] = false;
    } catch (error) {
      print('Error fetching student attendance: $error');
    }
  }

  int getTotalStudents() {
    return sortedKeys.length;
  }

  int getPresentCount() {
    return attendanceData.values.where((status) => status == 'p').length;
  }

  int getAbsentCount() {
    return attendanceData.values.where((status) => status == 'a').length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "ATTENDANCE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        ),
        backgroundColor: const Color.fromARGB(255, 151, 195, 220),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    int totalStudents = getTotalStudents();
    int presentCount = getPresentCount();
    int absentCount = getAbsentCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ATTENDANCE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Total: $totalStudents',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Present: $presentCount',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Absent: $absentCount',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final roll = sortedKeys[index];

                final isButtonPressed = buttonStates[roll] ?? false;
                final isAbsent = attendanceData[roll] == 'a';
                final studentName = studentNames[roll] ?? 'Unknown';
                print(buttonStates);

                String lastThreeChars =
                    roll.length >= 3 ? roll.substring(roll.length - 3) : roll;

                // Determine button color based on attendance status and source
                Color buttonColor;
                if (isAbsent) {
                  buttonColor = isButtonPressed
                      ? Colors.red
                      : Colors.orange; // Marked absentees vs loaded absentees
                } else {
                  buttonColor = Colors.white; // Present students
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        buttonStates[roll] = !isButtonPressed;
                        attendanceData[roll] = isButtonPressed ? 'p' : 'a';
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(buttonColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 10.0,
                        ),
                        Text(lastThreeChars),
                        const SizedBox(
                          width: 70.0,
                        ),
                        Text(studentName),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                submitAttendance();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const FacultyLog()),
                  (Route<dynamic> route) =>
                      false, // This predicate removes all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  void submitAttendance() async {
    final date = widget.selectedDate ?? DateTime.now();
    final formattedDate = '${date.day}-${date.month}-${date.year}';

    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.section)
        .get();
    final data = snapshot.data();
    if (data != null) {
      for (var key in data.keys) {
        if (data[key] is List<dynamic>) {
          List<dynamic> list = data[key];
          String roll = list[0];
          if (!attendanceData.containsKey(roll)) {
            attendanceData[roll] = 'p';
          }
        }
      }
    }

    for (var roll in attendanceData.keys) {
      bool isPressed = buttonStates[roll] ?? false;
      attendanceData[roll] = isPressed ? 'a' : 'p';
    }

    final times = widget.time.split('-');
    final startTime = times[0];
    final endTime = times[1];

    final startHourMinute = startTime.split(':').map(int.parse).toList();
    final endHourMinute = endTime.split(':').map(int.parse).toList();

    final startMinutes = startHourMinute[0] * 60 + startHourMinute[1];
    final endMinutes = endHourMinute[0] * 60 + endHourMinute[1];

    final timeDifference = endMinutes - startMinutes;
    final numPeriods = (timeDifference / 45).floor();

    if (numPeriods == 1) {
      for (var entry in attendanceData.entries) {
        String studentId = entry.key;
        String status = entry.value;
        String periodTime = '$formattedDate $startTime -${startMinutes + 45}';
        await updateAttendance(studentId, status, periodTime);
      }
    } else {
      for (int period = 0; period < numPeriods; period++) {
        for (var entry in attendanceData.entries) {
          String studentId = entry.key;
          String status = entry.value;
          String periodTime =
              '$formattedDate $startTime-${startMinutes + 45 * (period + 1)}';
          await updateAttendance(studentId, status, periodTime);
        }
      }
    }
  }

  Future<void> updateAttendance(
      String studentId, String status, String formattedDate) async {
    final attendanceRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.section)
        .collection(studentId)
        .doc(widget.subject);

    await attendanceRef.set({
      formattedDate: status,
    }, SetOptions(merge: true));

    final querySnapshot = await attendanceRef.get();
    final attendanceData = querySnapshot.data() as Map<String, dynamic>?;

    if (attendanceData == null || attendanceData.isEmpty) {
      await attendanceRef.set({
        'percentage': status == 'p' ? 100.0 : 0.0,
        'totalClasses': 1,
      }, SetOptions(merge: true));
      return;
    }

    final dataToCount = Map.of(attendanceData);
    dataToCount.remove('percentage');
    dataToCount.remove('totalClasses');

    final totalEntries = dataToCount.length;
    final absentCount =
        dataToCount.values.where((value) => value == 'a').length;
    final presentCount = totalEntries - absentCount;
    final attendancePercentage =
        totalEntries > 0 ? (presentCount / totalEntries) * 100 : 0.0;

    await attendanceRef.set({
      'percentage': attendancePercentage,
      'totalClasses': totalEntries,
    }, SetOptions(merge: true));
  }

  void _showErrorOnce(String message) {
    if (!hasShownError) {
      // Check if the error has already been shown
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      hasShownError = true; // Set the flag to true after showing the error
    }
  }
}
