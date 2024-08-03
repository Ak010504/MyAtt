import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'upload_users.dart';
import 'admin_log.dart';

class UploadUsersPage extends StatefulWidget {
  const UploadUsersPage({Key? key}) : super(key: key);

  @override
  _UploadUsersPageState createState() => _UploadUsersPageState();
}

class _UploadUsersPageState extends State<UploadUsersPage> {
  String? _filePath;
  String? _errorMessage;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _filePath = null;
        _errorMessage = 'No file selected';
      });
    }
  }

  Future<void> _uploadUsers() async {
    if (_filePath == null) {
      setState(() {
        _errorMessage = 'Please choose a file';
      });
      return;
    }

    try {
      final bytes = await File(_filePath!).readAsBytes();
      await uploadUsersFromExcel(context, bytes);
      setState(() {
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Users successfully added from Excel')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminLogPage()),
        (Route<dynamic> route) => false,
      ); // Go back to the previous screen
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload users: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Users from Excel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _filePath != null
                  ? 'File selected: ${_filePath!.split('/').last}'
                  : 'No file selected',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Choose File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadUsers,
              child: const Text('Add'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
