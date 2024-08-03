import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart';
import 'package:attendance/firebase_options.dart';
import 'package:attendance/admin_log.dart'; // Import your AdminLogPage

class ClassesUpload extends StatefulWidget {
  const ClassesUpload({Key? key}) : super(key: key);

  @override
  _ClassesUploadState createState() => _ClassesUploadState();
}

class _ClassesUploadState extends State<ClassesUpload> {
  String? _filePath;
  String? _fileName;

  Future<void> exportData(String filePath, String fileName) async {
    try {
      final DocumentReference mainDocRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(
              fileName); // Document in 'classes' collection named after the file

      // Load Excel file from the path
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // List to hold the student entries
      Map<String, dynamic> studentEntries = {};

      // Iterate through each sheet
      for (var sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];

        if (sheet != null) {
          final rows = sheet.rows;
          if (rows != null) {
            // Determine the role and sec from the first two rows
            String role =
                rows[0][0]?.value?.toString().trim().toLowerCase() == 'student'
                    ? 'student'
                    : 'unknown';
            String sec = rows[1][0]?.value?.toString().trim() ?? '';

            // Iterate through the Excel rows, skipping the first two rows
            for (int i = 2; i < rows.length; i++) {
              String digitalId = rows[i][1]?.value?.toString().trim() ?? '';
              String regNo = rows[i][2]?.value?.toString().trim() ?? '';
              String studentName = rows[i][3]?.value?.toString().trim() ?? '';
              String email = rows[i][4]?.value?.toString().trim() ?? '';

              // Ensure the digitalId, regNo, and student name are not empty
              if (digitalId.isNotEmpty &&
                  regNo.isNotEmpty &&
                  studentName.isNotEmpty &&
                  email.isNotEmpty) {
                // Create an entry for the student
                studentEntries['$sheetName-$i'] = [
                  digitalId,
                  regNo,
                  studentName,
                  email,
                  role,
                  sec
                ];

                // Create a reference to the subcollection document based on the digitalId
                final subcollectionDocRef =
                    mainDocRef.collection(digitalId).doc('info');

                // Set the 'info' document in the subcollection
                await subcollectionDocRef.set({
                  'digital_id': digitalId,
                  'name': studentName,
                  'regno': regNo,
                  'email': email,
                  'role': role,
                  'sec': sec,
                });

                print(
                    "Created document for digital_id $digitalId in subcollection 'students'.");
              }
            }
          }
        }
      }
      print(studentEntries);

      // Update Firestore document with the student entries array
      await mainDocRef.set(studentEntries);
      print("Updated document for file $fileName with student entries.");

      // Navigate to admin_log.dart and show success message
      _showSuccessMessage();
    } catch (e) {
      print('Error in exportData: $e');
    }
  }

  Future<void> pickFile() async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      print('Storage permission is not granted');
      return;
    }

    // Pick an Excel file
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name
            .split('.')
            .first; // Extract file name without extension
      });
      print('File selected: $_fileName');
    } else {
      print('File picking canceled');
    }
  }

  Future<void> uploadFile() async {
    if (_filePath != null && _fileName != null) {
      await exportData(_filePath!, _fileName!);
    } else {
      print('No file selected');
    }
  }

  void _showSuccessMessage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AdminLogPage(),
      ),
      (Route<dynamic> route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User Successfully Loaded'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel to Firestore Uploader',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Excel to Firestore Uploader'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pickFile,
                child: const Text('Choose File'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadFile,
                child: const Text('Add'),
              ),
              const SizedBox(height: 20),
              if (_fileName != null) Text('Selected file: $_fileName'),
            ],
          ),
        ),
      ),
    );
  }
}
