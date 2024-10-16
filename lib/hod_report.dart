import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HodReport extends StatefulWidget {
  @override
  _HodReportState createState() => _HodReportState();
}

class _HodReportState extends State<HodReport> {
  List<String> years = [];
  String selectedYear = '';
  String selectedSection = 'A';
  String selectedSubject = 'All';
  List<String> subjects = [];
  Map<String, Map<String, dynamic>> attendanceData = {};
  DateFormat format = DateFormat('dd-MM-yyyy');
  bool isLoading = true;
  bool hasData = true; // Track whether there is data to show
  double? thresholdPercentage;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userSnapshot.exists) {
        List<dynamic> yearsList = userSnapshot.get('years');
        setState(() {
          years = yearsList.cast<String>();
          selectedYear = years.isNotEmpty ? years[0] : '';
          _fetchSubjects();
        });
      } else {
        print('User document for $userId does not exist or is not HOD.');
      }
    } catch (error) {
      print('Error fetching years: $error');
    }
  }

  Future<void> _fetchSubjects() async {
    if (selectedYear.isEmpty) return;

    try {
      String combinedId = '$selectedYear$selectedSection';
      DocumentSnapshot<Map<String, dynamic>> classSnapshot =
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(combinedId)
              .get();

      if (classSnapshot.exists) {
        final data = classSnapshot.data();
        if (data != null) {
          Set<String> fetchedSubjects = {};
          await Future.wait(data.keys.map((key) async {
            String regno = data[key][0];
            QuerySnapshot<Map<String, dynamic>> subCollectionSnapshot =
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(combinedId)
                    .collection(regno)
                    .get();
            fetchedSubjects.addAll(subCollectionSnapshot.docs
                .map((doc) => doc.id)
                .where((id) => id != 'info'));
          }));

          setState(() {
            subjects = ['All'] + fetchedSubjects.toList();
            selectedSubject = subjects[0]; // Reset selected subject to 'All'
            _fetchAttendanceData(); // Fetch attendance data for the new section
          });
        }
      } else {
        setState(() {
          attendanceData.clear();
          hasData = false;
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching subjects: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSectionChanged(String? newValue) {
    setState(() {
      selectedSection = newValue!;
      _fetchSubjects(); // Fetch subjects for the new section
    });
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      isLoading = true;
      hasData = true;
    });

    if (selectedYear.isEmpty || selectedSection.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String combinedId = '$selectedYear$selectedSection';
      DocumentSnapshot<Map<String, dynamic>> classSnapshot =
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(combinedId)
              .get();

      if (classSnapshot.exists) {
        final data = classSnapshot.data();
        if (data != null) {
          attendanceData.clear();
          await Future.wait(data.keys.map((key) async {
            String regno = data[key][0];
            String name = data[key][1];
            double overallPercentage = 0.0;

            if (selectedSubject == 'All') {
              double totalPercentage = 0.0;
              int subjectCount = 0;

              await Future.wait(subjects
                  .where((subject) => subject != 'All')
                  .map((subject) async {
                DocumentSnapshot<Map<String, dynamic>> subjectSnapshot =
                    await FirebaseFirestore.instance
                        .collection('classes')
                        .doc(combinedId)
                        .collection(regno)
                        .doc(subject)
                        .get();
                if (subjectSnapshot.exists) {
                  final subjectData = subjectSnapshot.data();
                  if (subjectData != null) {
                    double percentage =
                        (subjectData['percentage'] as num).toDouble();
                    totalPercentage += percentage;
                    subjectCount++;
                  }
                }
              }));

              overallPercentage =
                  subjectCount > 0 ? (totalPercentage / subjectCount) : 0.0;
            } else {
              DocumentSnapshot<Map<String, dynamic>> selectedSubjectSnapshot =
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(combinedId)
                      .collection(regno)
                      .doc(selectedSubject)
                      .get();
              if (selectedSubjectSnapshot.exists) {
                final selectedSubjectData = selectedSubjectSnapshot.data();
                if (selectedSubjectData != null) {
                  overallPercentage =
                      (selectedSubjectData['percentage'] as num).toDouble();
                }
              }
            }

            attendanceData[regno] = {
              'name': name,
              'percentage': overallPercentage,
            };
          }));

          // Sort the data by registration number
          final sortedEntries = attendanceData.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          setState(() {
            attendanceData = Map.fromEntries(sortedEntries);
            isLoading = false;
            hasData = attendanceData.isNotEmpty;
          });
        } else {
          setState(() {
            attendanceData.clear(); // Clear previous data
            hasData = false;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          attendanceData.clear(); // Clear previous data
          hasData = false;
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching attendance data: $error');
      setState(() {
        attendanceData.clear(); // Clear previous data
        isLoading = false;
      });
    }
    print(attendanceData);
  }

  Future<void> _fetchAttendanceDataWithinDateRange() async {
    setState(() {
      isLoading = true;
      hasData = true;
    });

    if (selectedYear.isEmpty ||
        selectedSection.isEmpty ||
        selectedDateRange == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      String combinedId = '$selectedYear$selectedSection';
      DocumentSnapshot<Map<String, dynamic>> classSnapshot =
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(combinedId)
              .get();

      if (classSnapshot.exists) {
        final data = classSnapshot.data();
        if (data != null) {
          attendanceData.clear();
          await Future.wait(data.keys.map((key) async {
            String regno = data[key][0];
            String name = data[key][1];
            double overallPercentage = 0.0;

            if (selectedSubject == 'All') {
              double totalPercentage = 0.0;
              int subjectCount = 0;

              await Future.wait(subjects
                  .where((subject) => subject != 'All')
                  .map((subject) async {
                DocumentSnapshot<Map<String, dynamic>> subjectSnapshot =
                    await FirebaseFirestore.instance
                        .collection('classes')
                        .doc(combinedId)
                        .collection(regno)
                        .doc(subject)
                        .get();
                if (subjectSnapshot.exists) {
                  final subjectData = subjectSnapshot.data();
                  if (subjectData != null) {
                    int totalClasses = 0;
                    int presentCount = 0;

                    subjectData.forEach((key, value) {
                      if (key != 'percentage' && key != 'totalClasses') {
                        DateTime classDate = format.parse(key.split(' ')[0]);
                        if ((classDate.isAfter(selectedDateRange!.start) ||
                                classDate.isAtSameMomentAs(
                                    selectedDateRange!.start)) &&
                            (classDate.isBefore(selectedDateRange!.end) ||
                                classDate.isAtSameMomentAs(
                                    selectedDateRange!.end))) {
                          totalClasses++;
                          if (value == 'p') {
                            presentCount++;
                          }
                        }
                      }
                    });

                    if (totalClasses > 0) {
                      double percentage = (presentCount / totalClasses) * 100;
                      totalPercentage += percentage;
                      subjectCount++;
                    } else {
                      totalPercentage += 0.0;
                    }
                  }
                }
              }));

              overallPercentage =
                  subjectCount > 0 ? (totalPercentage / subjectCount) : 0.0;
            } else {
              DocumentSnapshot<Map<String, dynamic>> selectedSubjectSnapshot =
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(combinedId)
                      .collection(regno)
                      .doc(selectedSubject)
                      .get();
              if (selectedSubjectSnapshot.exists) {
                final selectedSubjectData = selectedSubjectSnapshot.data();
                if (selectedSubjectData != null) {
                  int totalClasses = 0;
                  int presentCount = 0;

                  selectedSubjectData.forEach((key, value) {
                    if (key != 'percentage' && key != 'totalClasses') {
                      DateTime classDate = format.parse(key.split(' ')[0]);
                      if ((classDate.isAfter(selectedDateRange!.start) ||
                              classDate.isAtSameMomentAs(
                                  selectedDateRange!.start)) &&
                          (classDate.isBefore(selectedDateRange!.end) ||
                              classDate
                                  .isAtSameMomentAs(selectedDateRange!.end))) {
                        totalClasses++;
                        if (value == 'p') {
                          presentCount++;
                        }
                      }
                    }
                  });

                  if (totalClasses > 0) {
                    overallPercentage = (presentCount / totalClasses) * 100;
                  } else {
                    overallPercentage = 0.0;
                  }
                }
              }
            }

            attendanceData[regno] = {
              'name': name,
              'percentage': overallPercentage,
            };
          }));

          // Sort the data by registration number
          final sortedEntries = attendanceData.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          setState(() {
            attendanceData = Map.fromEntries(sortedEntries);
            isLoading = false;
            hasData = attendanceData.isNotEmpty;
          });
        } else {
          setState(() {
            attendanceData.clear(); // Clear previous data
            hasData = false;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          attendanceData.clear(); // Clear previous data
          hasData = false;
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching attendance data within date range: $error');
      setState(() {
        attendanceData.clear(); // Clear previous data
        isLoading = false;
      });
    }
  }

  void _showThresholdDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController thresholdController =
            TextEditingController(text: thresholdPercentage?.toString() ?? '');
        return AlertDialog(
          title: Text('Set Threshold Percentage'),
          content: TextField(
            controller: thresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Threshold Percentage'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  thresholdPercentage =
                      double.tryParse(thresholdController.text);
                });
                Navigator.of(context).pop();
                _fetchAttendanceData(); // Fetch data again with new threshold
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        _fetchAttendanceDataWithinDateRange();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedSubject = 'All';
      selectedDateRange = null;
      thresholdPercentage = null;
      _fetchAttendanceData(); // Fetch data again with cleared filters
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter attendance data based on threshold
    List<MapEntry<String, Map<String, dynamic>>> filteredAttendanceData =
        attendanceData.entries.where((entry) {
      double percentage = entry.value['percentage'] ?? 0.0;
      return thresholdPercentage == null ||
          percentage <= (thresholdPercentage ?? 0);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('HOD Report'),
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: _showThresholdDialog,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          items: years.map((String year) {
                            return DropdownMenuItem<String>(
                              value: year,
                              child: Text(year),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedYear = newValue!;
                              _fetchSubjects();
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedSection,
                          items: ['A', 'B', 'C'].map((String section) {
                            return DropdownMenuItem<String>(
                              value: section,
                              child: Text(section),
                            );
                          }).toList(),
                          onChanged: _onSectionChanged,
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          items: subjects.map((String subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSubject = newValue!;
                              _fetchAttendanceData();
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (thresholdPercentage != null)
                    Text(
                        'Threshold Percentage: ${thresholdPercentage!.toStringAsFixed(2)}'),
                  if (selectedDateRange != null)
                    Text(
                        'Date Range: ${format.format(selectedDateRange!.start)} - ${format.format(selectedDateRange!.end)}'),
                  SizedBox(height: 16),
                  if (!hasData)
                    Text('No classes exist for the selected year and section.'),
                  if (hasData)
                    Text('Showing ${filteredAttendanceData.length} students'),
                  Expanded(
                    child: SingleChildScrollView(
                      //scrollDirection: Axis.vertical,

                      //scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Roll')),
                          DataColumn(label: Text('Name')),
                          DataColumn(
                              label: Text('  %'),
                              tooltip: 'Attendance Percentage'),
                        ],
                        rows: filteredAttendanceData.map((entry) {
                          return DataRow(
                            cells: [
                              DataCell(Text(entry.key)),
                              DataCell(Text(entry.value['name'] ?? '')),
                              DataCell(Text((entry.value['percentage'] ?? 0.0)
                                  .toStringAsFixed(1))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }
}
