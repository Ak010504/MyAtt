import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimetableDisplay extends StatefulWidget {
  @override
  _TimetableDisplayState createState() => _TimetableDisplayState();
}

class _TimetableDisplayState extends State<TimetableDisplay> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday'
  ];
  final Map<String, Map<String, dynamic>> timetableData = {};

  @override
  void initState() {
    super.initState();
    _fetchTimetableData();
  }

  Future<void> _fetchTimetableData() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').doc(userId).get();
      final Map<String, dynamic> userData = userSnapshot.data() ?? {};
      final String initials = userData['initials'] ?? '';

      if (initials.isEmpty) {
        throw Exception('User initials not found.');
      }

      final CollectionReference<Map<String, dynamic>> userCollection =
          firestore.collection('users').doc(userId).collection(initials);

      for (String day in days) {
        final DocumentSnapshot<Map<String, dynamic>> daySnapshot =
            await userCollection.doc(day).get();
        final Map<String, dynamic> dayData = daySnapshot.data() ?? {};

        setState(() {
          timetableData[day] = dayData;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
      ),
      body: timetableData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: days.map((day) {
                final dayData = timetableData[day] ?? {};
                return ExpansionTile(
                  title: Text(day[0].toUpperCase() + day.substring(1)),
                  children: dayData.entries.map((entry) {
                    final hour = entry.key;
                    final details = entry.value;
                    if (details is List &&
                        details.length > 4 &&
                        details[4] == 'yes') {
                      return SizedBox.shrink(); // Skip displaying this field
                    }
                    String displayDetails = '';
                    if (details is List && details[4] != "yes") {
                      final subjectName = details.isNotEmpty ? details[0] : '';
                      final subjectTime = details.length > 1 ? details[1] : '';
                      final subjectclass = details[3];
                      displayDetails =
                          '$subjectName at $subjectTime\n $subjectclass';
                    } else {
                      displayDetails = details.toString();
                    }

                    return ListTile(
                      title: Text('Hour: $hour'),
                      subtitle: Text(displayDetails),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }
}
