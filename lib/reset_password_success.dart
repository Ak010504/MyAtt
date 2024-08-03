import 'package:flutter/material.dart';
import 'package:attendance/auth/login_screen.dart';
import 'package:attendance/widgets/button.dart';

class ResetPasswordSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Reset Password Link Has Been Sent To Your Mail",
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: "Done",
              onPressed: () => goToLogin(context), // Wrap the goToLogin function call in a function
            ),
          ],
        ),
      ),
    );
  }
}

void goToLogin(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}
