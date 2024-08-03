import 'package:attendance/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:attendance/auth/auth_service.dart';
import 'package:attendance/student_log.dart';
import 'package:attendance/faculty_log.dart';
import 'package:attendance/admin_log.dart'; // Import the new admin page

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      body: FutureBuilder<String?>(
        future: auth.getUserRole(), // Get user role asynchronously
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator if data is still loading
            return Container(
              color: Color.fromARGB(255, 151, 195,
                  220), // Change this to your desired background color
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            // Show error message if there's an error
            return Center(
              child: Text("Error"),
            );
          } else {
            // Check user's role and navigate accordingly
            final role = snapshot.data;
            if (role == 'student') {
              return const StudentLog();
            } else if (role == 'faculty' || role == 'hod') {
              return const FacultyLog();
            } else if (role == 'admin') {
              return const AdminLogPage(); // Redirect to AdminLogPage for admin role
            } else {
              // Handle unknown role
              return const LoginScreen();
            }
          }
        },
      ),
    );
  }
}
