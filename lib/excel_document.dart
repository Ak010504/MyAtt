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

      // Get the first sheet
      final sheet = excel.tables.keys.first;

      if (sheet != null) {
        final rows = excel.tables[sheet]?.rows;
        if (rows != null) {
          // Iterate through the Excel rows, skipping the header row
          for (int i = 1; i < rows.length; i++) {
            // Get the values from the 3rd and 4th columns
            String? rollNumber = rows[i][2]?.value?.toString().trim();
            String? studentName = rows[i][3]?.value?.toString().trim();

            // Ensure the roll number and student name are not empty or null
            if (rollNumber != null &&
                rollNumber.isNotEmpty &&
                studentName != null &&
                studentName.isNotEmpty) {
              // Check if the document already exists
              final subcollectionDocRef =
                  mainDocRef.collection(rollNumber).doc('info');

              final docSnapshot = await subcollectionDocRef.get();

              if (!docSnapshot.exists) {
                // Create an entry for the student
                studentEntries['$i'] = [rollNumber, studentName];

                // Set the 'info' document in the subcollection
                await subcollectionDocRef.set({
                  'name': studentName,
                });

                print(
                    "Created document for roll number $rollNumber in subcollection 'students'.");
              } else {
                print(
                    "Document for roll number $rollNumber already exists. Skipping.");
              }
            }
          }
          print(studentEntries);

          // Update Firestore document with the student entries array
          await mainDocRef.set(studentEntries, SetOptions(merge: true));
          print("Updated document for file $fileName with student entries.");

          // Navigate to admin_log.dart and show success message
          _showSuccessMessage();
        }
      }
    } catch (e) {
      print('Error in exportData: $e');
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name.split('.').first;
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
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin_log',
      (route) => false,
      arguments: 'Users Successfully Loaded',
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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Excel to Firestore Uploader'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // Navigate back to the previous screen
            },
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 151, 195, 220),
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
