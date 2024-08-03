import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherProfile extends StatefulWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  // Helper function to get initials from the name
  String getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
      appBar: AppBar(
        title: const Text('Faculty Profile'),
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: const Text('No data available'));
            }
            final userData = snapshot.data!.data()!;
            final initials = getInitials(userData['name'] ?? 'NA');

            return Padding(
              padding: const EdgeInsets.fromLTRB(30.0, 50.0, 30.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 50.0,
                    color: Colors.black,
                  ),
                  const Text(
                    'Name',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        letterSpacing: 2.0),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Text(
                    userData['name'] ?? 'N/A',
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2.0,
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 25.0,
                  ),
                  const Text(
                    'Designation',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        letterSpacing: 2.0),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Text(
                    userData['designation'] ?? 'NA',
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2.0,
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 35.0),
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 10.0,
                      ),
                      Text(
                        userData['email'] ?? 'NA',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30.0),
                ],
              ),
            );
          }),
    );
  }
}
