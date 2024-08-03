import 'package:attendance/admin_log.dart';
import 'package:flutter/material.dart';
import 'package:attendance/auth/auth_service.dart';
import 'package:attendance/reset_password.dart';
import 'package:attendance/faculty_log.dart';
import 'package:attendance/student_log.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8CC0FF), // Top color of the gradient
                  Color(0xFF3A48D5), // Bottom color of the gradient
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 125),
                Image.asset('assets/ssn1.png', width: 200, height: 200),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    SizedBox(width: 60),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                const Row(
                  children: [
                    SizedBox(width: 60),
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _password,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 110),
                  child: FloatingActionButton(
                    onPressed: _login,
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 23),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Forget Password? ",
                      style: TextStyle(fontSize: 18),
                    ),
                    InkWell(
                      onTap: () => goToReset(context),
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void goToReset(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPassword()),
    );
  }

  Future<void> _login() async {
    if (!mounted) return; // Check if the widget is still mounted

    try {
      final user = await _auth.loginUserWithEmailAndPassword(
        _email.text,
        _password.text,
      );

      if (!mounted) return; // Check again after async operation

      if (user != null) {
        final userData = await _auth.getUserData(user.uid);
        if (!mounted) return; // Check again after async operation
        if (userData != null && userData.containsKey('role')) {
          final role = userData['role'] as String;
          if (role.toLowerCase() == 'faculty' || role.toLowerCase() == 'hod') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FacultyLog()),
            );
          } else if (role.toLowerCase() == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentLog()),
            );
          } else if (role.toLowerCase() == 'admin') {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminLogPage()),
              );
            }
          } else {
            _showError('Unknown role');
          }
        } else {
          _showError('User data not found or role not specified');
        }
      } else {
        _showError('Failed to login');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
