import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectTablePage extends StatelessWidget {
  final String section;

  const SubjectTablePage({required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "SUBJECTS TABLE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return Center(child: Text('No data available'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final subjects = userData['subjects'] as List<dynamic>;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').doc(section).snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!classSnapshot.hasData || classSnapshot.data == null || !classSnapshot.data!.exists) {
                return Center(child: Text('No data available'));
              }

              final classData = classSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Reg No')),
                    DataColumn(label: Text('Name')),
                    ...subjects.map((subject) => DataColumn(label: Text(subject.toString()))),
                  ],
                  rows: classData.entries
                      .map<DataRow>((entry) {
                        final studentData = entry.value as Map<String, dynamic>;
                        final regNo = entry.key;
                        final name = studentData['name'] as String;
                        final attendanceData = studentData['subjects'] as Map<String, dynamic>;

                        return DataRow(
                          cells: [
                            DataCell(Text(regNo)),
                            DataCell(Text(name)),
                            ...subjects.map<DataCell>((subject) {
                              final subjectAttendance = attendanceData[subject];
                              final percentage = (subjectAttendance != null && subjectAttendance['total_classes'] != 0)
                                  ? (subjectAttendance['percentage'] as double).toStringAsFixed(2)
                                  : 'N/A';
                              return DataCell(Text(percentage + '%'));
                            }),
                          ],
                        );
                      })
                      .toList(),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }
}
