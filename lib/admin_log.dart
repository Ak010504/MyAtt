import 'package:attendance/excel_document.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendance/auth/login_screen.dart'; // Import your LoginScreen
import 'package:attendance/upload_users_page.dart'; // Import your UploadUsersPage

class AdminLogPage extends StatelessWidget {
  const AdminLogPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _goToUploadUsersPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UploadUsersPage()),
    );
  }

  void _goToUploadClassesAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassesUpload()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Log Page'),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome Admin!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _goToUploadUsersPage(context),
              child: const Text('Add Users from Excel to Authentication'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _goToUploadClassesAttendance(context),
              child: const Text('Add classes student from Excel'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
