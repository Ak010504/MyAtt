import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:attendance/auth/login_screen.dart';
import 'package:attendance/home_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text("Error"),
            );
          } else {
            if (snapshot.data == null) {
              return LoginScreen(); // Show the login screen if user is not authenticated
            } else {
              return HomeScreen(); // Show the home screen if user is authenticated
            }
          }
        },
      ),
    );
  }
}
