import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'admin_log.dart'; // Import the AdminLogPage

Future<void> uploadUsersFromExcel(BuildContext context, Uint8List bytes) async {
  try {
    final List<List<dynamic>> excelData = await _readExcelFile(bytes);

    for (final sheetData in excelData) {
      String userType = sheetData[0][0]?.toString().trim().toLowerCase() ?? '';

      if (userType == 'student') {
        String role =
            sheetData[0][0]?.toString().trim().toLowerCase() == 'student'
                ? 'student'
                : 'unknown';
        String sec = sheetData[1][0]?.toString().trim() ?? '';

        for (int i = 3; i < sheetData.length; i++) {
          final List<dynamic> row = sheetData[i];
          if (row.length < 5) {
            print('Invalid row data: $row');
            continue;
          }

          final String email = row[4]?.toString() ?? '';
          final String name = row[3]?.toString() ?? '';
          final String digitalId = row[1]?.toString() ?? '';
          final String regNo =
              row[2]?.toString().replaceAll(' ', '').replaceAll('.0', '') ??
                  ''; // Clean regNo

          if (email.isEmpty ||
              name.isEmpty ||
              digitalId.isEmpty ||
              regNo.isEmpty) {
            print('Skipping row due to missing data: $row');
            continue;
          }

          final QuerySnapshot result = await FirebaseFirestore.instance
              .collection('users')
              .where('digital_id', isEqualTo: digitalId)
              .get();
          final List<DocumentSnapshot> documents = result.docs;

          if (documents.isEmpty) {
            try {
              final UserCredential userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: '1234567',
              );
              final User? user = userCredential.user;

              if (user != null) {
                final Map<String, dynamic> userData = {
                  'digital_id': digitalId,
                  'email': email,
                  'name': name,
                  'regno': regNo,
                  'role': role,
                  'sec': sec,
                };
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set(userData);
              }
            } catch (e) {
              print('Error creating student user for $email: $e');
            }
          } else {
            print('Student with digital_id $digitalId already exists.');
          }
        }
      } else if (userType == 'faculty') {
        for (int i = 1; i < sheetData.length; i++) {
          final List<dynamic> row = sheetData[i];
          if (row.length < 4) {
            print('Invalid row data: $row');
            continue;
          }

          final String email = row[3]?.toString() ?? '';
          final String name = row[1]?.toString() ?? '';
          final String designation = row[2]?.toString() ?? '';

          if (email.isEmpty || name.isEmpty || designation.isEmpty) {
            print('Skipping row due to missing data: $row');
            continue;
          }

          final String initials = name.split(' ').map((e) => e[0]).join();
          final String userName = name;
          String role = 'faculty';
          if (designation.toLowerCase() == 'professor & head') {
            role = 'hod';
          } else if (designation.toLowerCase() == 'associate professor' ||
              designation.toLowerCase() == 'professor') {
            role = 'faculty';
          }

          final QuerySnapshot result = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();
          final List<DocumentSnapshot> documents = result.docs;

          if (documents.isEmpty) {
            try {
              final UserCredential userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: '1234567',
              );
              final User? user = userCredential.user;

              if (user != null) {
                final Map<String, dynamic> userData = {
                  'email': email,
                  'initials': initials,
                  'name': userName,
                  'role': role,
                  'designation': designation,
                };
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set(userData);
              }
            } catch (e) {
              print('Error creating faculty user for $email: $e');
            }
          } else {
            print('Faculty with email $email already exists.');
          }
        }
      } else {
        print('Unknown user type: $userType');
      }
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminLogPage()),
      (Route<dynamic> route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Users created from Excel file')),
    );
  } catch (e) {
    print('Error reading Excel file: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to read Excel file')),
    );
  }
}

Future<List<List<List<dynamic>>>> _readExcelFile(Uint8List bytes) async {
  final excel = Excel.decodeBytes(bytes);
  final List<List<List<dynamic>>> allSheetsData = [];

  for (final sheet in excel.tables.keys) {
    final table = excel.tables[sheet];
    if (table != null) {
      final List<List<dynamic>> rows = [];
      for (final row in table.rows) {
        List<dynamic> rowData = [];
        for (final cell in row) {
          if (cell != null && cell.value != null) {
            if (cell.value.runtimeType == TextCellValue) {
              rowData.add(
                  cell.value.toString()); // Convert TextCellValue to String
            } else {
              rowData
                  .add(cell.value); // Use cell value directly for other types
            }
          } else {
            rowData.add(''); // Handle null case or set a default value
          }
        }
        rows.add(rowData);
      }
      allSheetsData.add(rows);
    }
  }

  return allSheetsData;
}
