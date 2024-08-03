import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      // Check if password meets requirements
      if (!_isPasswordValid(password, email)) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password does not meet requirements',
        );
      }

      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Create a new collection based on user's initials
      String initials = _extractInitials(email);
      await _firestore.collection('users').doc(cred.user!.uid).collection(initials).doc('initial_collection').set({});

      return cred.user;
    } on FirebaseAuthException catch (e) {
      exceptionHandler(e.code);
    } catch (e) {
      print("Something went wrong");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      exceptionHandler(e.code);
    } catch (e) {
      print("Something went wrong");
    }
    return null;
  }

  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data()!.containsKey('role')) {
          return userData.data()!['role'];
        }
      }
    } catch (e) {
      print("Error getting user role: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final userData = await _firestore.collection('users').doc(uid).get();
      if (userData.exists) {
        return userData.data();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Something went wrong while signing out");
    }
  }

  String _extractInitials(String email) {
    List<String> parts = email.split('@');
    String username = parts[0];
    List<String> usernameParts = username.split('.');
    String initials = usernameParts.map((part) => part[0]).join('').toUpperCase();
    return initials;
  }

  // Method to check if password meets requirements
  bool _isPasswordValid(String password, String email) {
    // Implement your password validation logic here
    // For example, check password length, complexity, etc.
    return true;
  }

  // Method to handle exceptions
  void exceptionHandler(String code) {
    switch (code) {
      case "invalid-credentials":
        print("Your Login Credentials Are Invalid");
        break;
      case "weak-password":
        print("Password does not meet requirements");
        break;
      case "email-already-in-use":
        print("User Already Exist");
        break;
      default:
        print("Something Went Wrong");
    }
  }
}
