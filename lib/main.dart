import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:attendance/upload_users.dart';
import 'package:attendance/home_screen.dart';
import 'package:attendance/wrapper.dart';
import 'package:attendance/reset_password_success.dart';
import 'package:attendance/faculty_profile.dart';
import 'package:attendance/student_log.dart';
import 'package:attendance/attendance.dart';
import 'package:attendance/admin_log.dart';
import 'package:attendance/excel_document.dart';
import 'package:attendance/splash_screen.dart'; // Import the splash screen
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyCjm98mleux3Is4MapiUlwwNwk60n35IC0",
            authDomain: "attendance-888e2.firebaseapp.com",
            projectId: "attendance-888e2",
            storageBucket: "attendance-888e2.appspot.com",
            messagingSenderId: "940441662966",
            appId: "1:940441662966:web:ce158de69d0311f2a8c3d7",
            measurementId: "G-8TYBHMGVMF"));
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Remove the native splash screen
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Set Wrapper as the home screen
      routes: {
        '/reset_password_success': (context) => ResetPasswordSuccessScreen(),
        '/quotes1': (context) => TeacherProfile(),
        '/quotes2': (context) => const HomeScreen(),
        '/quotes3': (context) => const Attendance(),
        '/quotes4': (context) => const StudentLog(),
        '/admin_log': (context) => const AdminLogPage(),
        '/classes_upload': (context) =>
            const ClassesUpload(), // Add ClassesUpload route
      },
    );
  }
}
