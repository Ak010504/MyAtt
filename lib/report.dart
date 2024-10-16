import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FacultyReport extends StatefulWidget {
  @override
  _FacultyReportState createState() => _FacultyReportState();
}

class _FacultyReportState extends State<FacultyReport> {
  List<String> classedSubjects = [];
  Map<String, Map<String, dynamic>> attendanceData = {};
  bool isLoading = false;

  String selectedClassedSubject = '';
  String selectedSetting = 'None'; // Default to 'None'
  double percentageThreshold = 0.0;
  DateTimeRange? selectedDateRange;
  DateFormat format = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _fetchFacultyDetails();
  }

  Future<void> _fetchFacultyDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> facultySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (facultySnapshot.exists) {
        List<dynamic> classedSubjectsList = facultySnapshot.get('subjects');

        if (mounted) {
          setState(() {
            classedSubjects = classedSubjectsList.cast<String>();
            selectedClassedSubject =
                classedSubjects.isNotEmpty ? classedSubjects[0] : '';
          });

          await _fetchAttendanceData();
        }
      } else {
        print('Faculty document for $userId does not exist.');
      }
    } catch (error) {
      print('Error fetching faculty details: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (selectedClassedSubject.isNotEmpty) {
        List<String> parts = selectedClassedSubject.split(' ');
        String section = parts.removeLast();
        String selectedsubject = parts.join(' ');

        DocumentSnapshot<Map<String, dynamic>> classSnapshot =
            await FirebaseFirestore.instance
                .collection('classes')
                .doc(section)
                .get();

        if (classSnapshot.exists) {
          var sortedEntries = classSnapshot.data()!.entries.toList()
            ..sort((a, b) {
              String regNoA = a.value[0];
              String regNoB = b.value[0];
              return _compareLastThreeDigits(regNoA, regNoB);
            });

          List<Future<void>> futures = [];
          for (var studentEntry in sortedEntries) {
            String regNo = studentEntry.value[0];
            String name = studentEntry.value[1];
            futures.add(_processStudentAttendance(
                section, regNo, name, selectedsubject));
          }

          await Future.wait(futures);
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      print('Error fetching attendance data: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _processStudentAttendance(
      String section, String regNo, String name, String selectedsubject) async {
    attendanceData.putIfAbsent(regNo, () => {'name': name});

    QuerySnapshot<Map<String, dynamic>> studentSubcollectionSnapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(section)
            .collection(regNo)
            .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> subjectSnapshot
        in studentSubcollectionSnapshot.docs) {
      String subject = subjectSnapshot.id;
      Map<String, dynamic> subjectData = subjectSnapshot.data();

      if (subjectData.containsKey('percentage') && subject == selectedsubject) {
        double percentage = subjectData['percentage'];
        attendanceData[regNo]![subject] = percentage;
      }
    }
  }

  Future<void> _fetchAttendanceDataWithinDateRange() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (selectedClassedSubject.isNotEmpty && selectedDateRange != null) {
        List<String> parts = selectedClassedSubject.split(' ');
        String section = parts.removeLast();
        String selectedsubject = parts.join(' ');

        DocumentSnapshot<Map<String, dynamic>> classSnapshot =
            await FirebaseFirestore.instance
                .collection('classes')
                .doc(section)
                .get();

        if (classSnapshot.exists) {
          var sortedEntries = classSnapshot.data()!.entries.toList()
            ..sort((a, b) {
              String regNoA = a.value[0];
              String regNoB = b.value[0];
              return _compareLastThreeDigits(regNoA, regNoB);
            });

          List<Future<void>> futures = [];
          for (var studentEntry in sortedEntries) {
            String regNo = studentEntry.value[0];
            String name = studentEntry.value[1];
            futures.add(_processStudentAttendanceWithinDateRange(
                section, regNo, name, selectedsubject));
          }

          await Future.wait(futures);
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      print('Error fetching attendance data within date range: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _processStudentAttendanceWithinDateRange(
      String section, String regNo, String name, String selectedsubject) async {
    attendanceData.putIfAbsent(regNo, () => {'name': name});

    QuerySnapshot<Map<String, dynamic>> studentSubcollectionSnapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(section)
            .collection(regNo)
            .get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> subjectSnapshot
        in studentSubcollectionSnapshot.docs) {
      String subject = subjectSnapshot.id;
      Map<String, dynamic> subjectData = subjectSnapshot.data();

      if (subject == selectedsubject) {
        int totalClasses = 0;
        int presentCount = 0;

        subjectData.forEach((key, value) {
          if (key != 'percentage' && key != 'totalClasses') {
            DateTime classDate = format.parse(key.split(' ')[0]);
            if ((classDate.isAfter(selectedDateRange!.start) ||
                    classDate.isAtSameMomentAs(selectedDateRange!.start)) &&
                (classDate.isBefore(selectedDateRange!.end) ||
                    classDate.isAtSameMomentAs(selectedDateRange!.end))) {
              totalClasses++;
              if (value == 'p') {
                presentCount++;
              }
            }
          }
        });

        if (totalClasses > 0) {
          double percentage = (presentCount / totalClasses) * 100;
          attendanceData[regNo]![subject] = percentage;
        } else {
          attendanceData[regNo]![subject] = 0.0;
        }
      }
    }
  }

  int _compareLastThreeDigits(String a, String b) {
    String lastThreeDigitsA = a.padLeft(3, '0').substring(a.length - 3);
    String lastThreeDigitsB = b.padLeft(3, '0').substring(b.length - 3);
    return lastThreeDigitsA.compareTo(lastThreeDigitsB);
  }

  void _filterByPercentage(double threshold) {
    setState(() {
      percentageThreshold = threshold;
      selectedSetting = 'Percentage'; // Update selectedSetting
    });
    _fetchAttendanceDataWithinDateRange();
  }

  void _filterByDates(DateTimeRange dateRange) {
    setState(() {
      selectedDateRange = dateRange;
      selectedSetting = 'Dates'; // Update selectedSetting
    });
    _fetchAttendanceDataWithinDateRange();
  }

  void _clearFilters() {
    setState(() {
      percentageThreshold = 0.0;
      selectedDateRange = null;
      selectedSetting = 'None'; // Reset selectedSetting
    });
    _fetchAttendanceData();
  }

  List<MapEntry<String, Map<String, dynamic>>> _filteredEntries() {
    if (selectedSetting == 'Percentage' && percentageThreshold > 0) {
      return attendanceData.entries.where((entry) {
        bool hasSubject = entry.value.keys.any((key) => key != 'name');
        if (!hasSubject) return false;
        String subject = entry.value.keys
            .firstWhere((key) => key != 'name', orElse: () => '');
        double percentage = entry.value[subject] ?? 0.0;
        return percentage <= percentageThreshold;
      }).toList();
    } else if (selectedSetting == 'Dates' && selectedDateRange != null) {
      return attendanceData.entries.toList();
    } else if (selectedSetting == 'None') {
      return attendanceData.entries.toList();
    } else {
      return attendanceData.entries.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, Map<String, dynamic>>> filteredAttendanceData =
        _filteredEntries();

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Report'),
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showPercentageDialog,
          ),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _showDateRangeDialog,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearFilters,
          )
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating report...'),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: selectedClassedSubject,
                    onChanged: (value) {
                      setState(() {
                        selectedClassedSubject = value!;
                        attendanceData.clear();
                        _fetchAttendanceData();
                      });
                    },
                    items: classedSubjects
                        .map<DropdownMenuItem<String>>((String classedSubject) {
                      return DropdownMenuItem<String>(
                        value: classedSubject,
                        child: Text(classedSubject),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedSetting == 'Percentage' &&
                    percentageThreshold > 0 &&
                    selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        'Less than $percentageThreshold percent\nAs on ${format.format(selectedDateRange!.start)} to ${format.format(selectedDateRange!.end)}'),
                  ),
                if (selectedSetting == 'Percentage' &&
                    percentageThreshold > 0 &&
                    selectedDateRange == null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Less than $percentageThreshold percent'),
                  ),
                if (selectedSetting == 'Dates' && selectedDateRange != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        'As on ${format.format(selectedDateRange!.start)} to ${format.format(selectedDateRange!.end)}'),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Number of students: ${filteredAttendanceData.length}'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Roll')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Percentage')),
                      ],
                      rows: filteredAttendanceData.map((entry) {
                        String regNo = entry.key;
                        Map<String, dynamic> data = entry.value;
                        String name = data['name'];
                        String lastThreeDigits =
                            regNo.padLeft(3, '0').substring(regNo.length - 3);
                        String subject = data.keys.firstWhere(
                            (key) => key != 'name',
                            orElse: () => '');
                        double percentage = data[subject] ?? 0.0;

                        return DataRow(cells: [
                          DataCell(Text(lastThreeDigits)),
                          DataCell(Text(name)),
                          DataCell(Text(percentage.toStringAsFixed(1))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }

  Future<void> _showPercentageDialog() async {
    double? result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        double tempThreshold = percentageThreshold;

        return AlertDialog(
          title: Text('Filter by Percentage'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              tempThreshold = double.tryParse(value) ?? 0.0;
            },
            decoration: InputDecoration(hintText: "Enter percentage threshold"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Apply'),
              onPressed: () {
                Navigator.of(context).pop(tempThreshold);
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      _filterByPercentage(result);
    }
  }

  Future<void> _showDateRangeDialog() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );

    if (picked != null && picked != selectedDateRange) {
      _filterByDates(picked);
    }
  }
}
