import 'package:flutter/material.dart';
import 'package:attendance/widgets/button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _emailTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color.fromARGB(255, 151, 195, 220)),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(
                height: 70,
              ),
              Row(
                children: [
                  SizedBox(width: 75),
                  Image.asset('assets/lock2.jpg', width: 200, height: 200),
                ],
              ),
              SizedBox(
                height: 90,
              ),
              const Text(
                "Reset your password?",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              const Text(
                "No Problem, enter your mail id to reset it!",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
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
                  controller: _emailTextController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                label: "Reset Password",
                onPressed: _resetPassword,
              ),
              const SizedBox(height: 20), // Add some space at the bottom
            ],
          ),
        ),
      ),
    );
  }

  void _resetPassword() {
    FirebaseAuth.instance
        .sendPasswordResetEmail(email: _emailTextController.text)
        .then((value) {
      // Navigate to ResetPasswordSuccessScreen after sending the email
      Navigator.pushReplacementNamed(context, '/reset_password_success');
    }).catchError((error) {
      // Handle errors here, if any
      print("Error sending password reset email: $error");
    });
  }
}
