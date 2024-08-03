import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance/faculty_log.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedDay = DateFormat('EEEE').format(DateTime.now());
  String _subject = '';
  String _time = '';
  String _room = '';
  String _section = '';
  bool _isSubstitution = false;
  bool _isEarlyLunch = false;
  List<String> _sections = [];
  List<String> _subjects = [];
  bool _isNewSubject = false;
  String _newSubject = '';
  String _alternateDay = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchSections();
    _fetchSubjects();
  }

  void _fetchSections() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection('classes').get();
      final List<String> sections = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        _sections = sections;
      });
    } catch (error) {
      print('Error fetching sections: $error');
    }
  }

  void _fetchSubjects() async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').doc(userId).get()
              as DocumentSnapshot<Map<String, dynamic>>;
      final Map<String, dynamic> userData = userSnapshot.data() ?? {};
      final List<String> subjects =
          List<String>.from(userData['subjects'] ?? []);

      // Remove the last word from each subject and ensure uniqueness
      final Set<String> processedSubjectsSet = {};
      for (var subject in subjects) {
        final List<String> parts = subject.split(' ');
        if (parts.length > 1) {
          parts.removeLast(); // Remove the last word
        }
        processedSubjectsSet.add(parts.join(' '));
      }

      setState(() {
        _subjects = processedSubjectsSet.toList();
      });
    } catch (error) {
      print('Error fetching subjects: $error');
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ADD CLASSES",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDay,
                onChanged: (String? value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
                items: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ].map((String day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Day *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a day';
                  }
                  return null;
                },
              ),
              if (_selectedDay == 'Saturday')
                DropdownButtonFormField<String>(
                  value: _alternateDay.isEmpty ? null : _alternateDay,
                  onChanged: (String? value) {
                    setState(() {
                      _alternateDay = value!;
                    });
                  },
                  items: [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday'
                  ].map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Choose a new day *',
                  ),
                  validator: (value) {
                    if (_selectedDay == 'Saturday' &&
                        (value == null || value.isEmpty)) {
                      return 'Please choose a new day';
                    }
                    return null;
                  },
                ),
              DropdownButtonFormField<String>(
                value: _isNewSubject
                    ? 'New Subject'
                    : (_subject.isEmpty ? null : _subject),
                onChanged: (String? value) {
                  setState(() {
                    if (value == 'New Subject') {
                      _isNewSubject = true;
                      _subject = ''; // Clear the selected subject
                      // Clear the new subject field
                    } else {
                      _isNewSubject = false;
                      _subject = value!;
                    }
                  });
                },
                items: [
                  ..._subjects.map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  DropdownMenuItem<String>(
                    value: 'New Subject',
                    child: Text('New Subject'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                ),
                validator: (value) {
                  if (_selectedDay != 'Saturday' &&
                      (value == null || value.isEmpty)) {
                    return 'Please select or enter a subject';
                  }
                  return null;
                },
              ),
              if (_isNewSubject)
                TextFormField(
                  decoration: InputDecoration(labelText: 'New Subject Name *'),
                  validator: (value) {
                    if (_selectedDay != 'Saturday' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter a new subject name';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _newSubject = value;
                  },
                ),
              TextFormField(
                controller: _hourController,
                decoration: InputDecoration(
                    labelText: 'Hour numbers (comma-separated) *'),
                validator: (value) {
                  if (_selectedDay != 'Saturday' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter hour numbers';
                  }
                  return null;
                },
                onChanged: (_) {
                  _updateTime();
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time'),
                enabled: false,
                validator: (value) {
                  if (_selectedDay != 'Saturday' &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter a time';
                  }
                  return null;
                },
                onSaved: (value) {
                  _time = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Room (Optional)'),
                validator: (value) {
                  return null;
                },
                onSaved: (value) {
                  _room = value ?? '';
                },
              ),
              DropdownButtonFormField<String>(
                value: _section.isEmpty ? null : _section,
                onChanged: (String? value) {
                  setState(() {
                    _section = value!;
                  });
                },
                items: _sections.map((String section) {
                  return DropdownMenuItem<String>(
                    value: section,
                    child: Text(section),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Section *',
                ),
                validator: (value) {
                  if (_selectedDay != 'Saturday' &&
                      (value == null || value.isEmpty)) {
                    return 'Please select a section';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Is this a substitution period?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _isSubstitution,
                      onChanged: (bool? value) {
                        setState(() {
                          _isSubstitution = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _isSubstitution,
                      onChanged: (bool? value) {
                        setState(() {
                          _isSubstitution = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Early Lunch?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Yes'),
                      value: true,
                      groupValue: _isEarlyLunch,
                      onChanged: (bool? value) {
                        setState(() {
                          _isEarlyLunch = value!;
                          _updateTime(); // Update time when Early Lunch changes
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No'),
                      value: false,
                      groupValue: _isEarlyLunch,
                      onChanged: (bool? value) {
                        setState(() {
                          _isEarlyLunch = value!;
                          _updateTime(); // Update time when Early Lunch changes
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _submitForm();
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }

  void _updateTime() {
    String hourText = _hourController.text;
    List<String> hourList = hourText.split(',').map((e) => e.trim()).toList();
    List<int> hours = hourList.map((e) => int.tryParse(e) ?? 0).toList();

    if (hours.isEmpty || hours.any((hour) => hour < 1 || hour > 8)) {
      _timeController.text = '';
      return;
    }

    if (hours.length == 1) {
      // Single hour number case
      String time = getTimeRange(hours.first);
      if (time == 'Enter a valid hour number') {
        setState(() {
          _timeController.text = 'Invalid hour number';
        });
      } else {
        setState(() {
          _timeController.text = time;
        });
      }
    } else {
      // Multiple hour numbers case
      String startTime = getTimeRange(hours.first);
      String endTime = getTimeRange(hours.last);
      print(hours.first);
      print(hours.last);
      if (startTime == 'Enter a valid hour number' ||
          endTime == 'Enter a valid hour number') {
        setState(() {
          _timeController.text = 'Invalid hour numbers';
        });
      } else {
        startTime = startTime.split('-')[0];
        endTime = endTime.split('-')[1];
        print(startTime);
        print(endTime);
        print('$startTime - $endTime');

        setState(() {
          _timeController.text = '$startTime - $endTime';
        });
      }
    }
  }

  String getTimeRange(int hour) {
    if (_isEarlyLunch) {
      switch (hour) {
        case 1:
          return '08:00-08:45';
        case 2:
          return '08:45-09:30';
        case 3:
          return '09:50-10:35';
        case 4:
          return '10:35-11:20';
        case 5:
          return '12:05-12:55';
        case 6:
          return '12:55-13:50';
        case 7:
          return '14:10-14:55';
        case 8:
          return '14:55-15:40';
        default:
          return 'Enter a valid hour number';
      }
    } else {
      switch (hour) {
        case 1:
          return '08:00-08:45';
        case 2:
          return '08:45-09:30';
        case 3:
          return '09:50-10:35';
        case 4:
          return '10:35-11:20';
        case 5:
          return '11:20-12:05';
        case 6:
          return '13:05-13:50';
        case 7:
          return '14:10-14:55';
        case 8:
          return '14:55-15:40';
        default:
          return 'Enter a valid hour number';
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedDay == 'Saturday' && _alternateDay.isNotEmpty) {
        // Handle copying data from alternate day to Saturday
        try {
          final String userId = FirebaseAuth.instance.currentUser!.uid;
          final CollectionReference usersCollection =
              firestore.collection('users');
          final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
              await usersCollection.doc(userId).get()
                  as DocumentSnapshot<Map<String, dynamic>>;
          final Map<String, dynamic> userData = userSnapshot.data() ?? {};
          final String initials = userData['initials'] ?? '';

          if (initials.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User initials not found.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          final CollectionReference userCollection =
              usersCollection.doc(userId).collection(initials);
          final DocumentReference alternateDayDocument =
              userCollection.doc(_alternateDay.toLowerCase());
          final DocumentSnapshot<Map<String, dynamic>> alternateDaySnapshot =
              await alternateDayDocument.get()
                  as DocumentSnapshot<Map<String, dynamic>>;
          final Map<String, dynamic> alternateDayData =
              alternateDaySnapshot.data() ?? {};

          // Modify data for Saturday to include substitution as 'yes' for all hours
          final Map<String, dynamic> saturdayData = {};
          alternateDayData.forEach((key, value) {
            if (value is List) {
              List<dynamic> modifiedValue = List.from(value);
              modifiedValue[4] = 'yes'; // Set substitution to 'yes'
              saturdayData[key] = modifiedValue;
            }
          });

          final DocumentReference saturdayDocument =
              userCollection.doc('saturday');
          await saturdayDocument.set(saturdayData,
              SetOptions(merge: true)); // Merge to keep existing data

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data for Saturday updated successfully.'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (error) {
          print('Error updating Saturday data: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occurred updating Saturday data'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // Handle adding new data
      try {
        final String userId = FirebaseAuth.instance.currentUser!.uid;
        final CollectionReference usersCollection =
            firestore.collection('users');
        final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await usersCollection.doc(userId).get()
                as DocumentSnapshot<Map<String, dynamic>>;
        final Map<String, dynamic> userData = userSnapshot.data() ?? {};
        final String initials = userData['initials'] ?? '';

        if (initials.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User initials not found'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final CollectionReference userCollection =
            usersCollection.doc(userId).collection(initials);
        final String selectedDay = _selectedDay.toLowerCase();
        final DocumentReference dayDocument = userCollection.doc(selectedDay);

        // Create the new data to add
        final String combinedTime = _timeController.text;
        final List<dynamic> newData = [
          _isNewSubject ? _newSubject : _subject,
          combinedTime.isNotEmpty ? combinedTime : null,
          _room.isNotEmpty ? _room : null,
          _section.isNotEmpty ? _section : null,
          _isSubstitution ? 'yes' : 'no',
          DateTime.now().toString(),
        ];

        final String newKey = _hourController.text;
        if (newKey.isNotEmpty && newData.any((element) => element != null)) {
          final Map<String, dynamic> existingData = (await dayDocument.get()
                      as DocumentSnapshot<Map<String, dynamic>>)
                  .data() ??
              {};
          existingData[newKey] = newData;

          await dayDocument.set(existingData,
              SetOptions(merge: true)); // Merge to keep existing data

          // Update subjects list
          String subjectEntry =
              (_isNewSubject ? _newSubject : _subject) + " " + _section;
          if (!userData.containsKey('subjects') ||
              userData['subjects'] == null) {
            userData['subjects'] = [];
          }

          if (userData['subjects'] is List) {
            List<dynamic> subjects = userData['subjects'];
            if (!subjects.contains(subjectEntry)) {
              subjects.add(subjectEntry);
              userData['subjects'] = subjects;
              await usersCollection.doc(userId).update({
                'subjects': subjects,
              });

              print('$subjectEntry has been added to the subjects list.');
            } else {
              print('$subjectEntry is already present in the subjects list.');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data added successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in all required fields'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Show loading indicator and navigate to FacultyLogPage
        void showLoadingIndicator() {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        }

        showLoadingIndicator();
        await Future.delayed(Duration(seconds: 2));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FacultyLog()),
          (Route<dynamic> route) => false,
        );
      } catch (error) {
        print('Error adding data: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
