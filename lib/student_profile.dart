import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile extends StatefulWidget {
  final String userId;

  const StudentProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
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
        title: const Text('Student Profile'),
        backgroundColor: Color.fromARGB(255, 97, 167, 214),
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
          final initials = getInitials(userData['name'] ?? 'N/A');

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
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  userData['name'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25.0),
                const Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  userData['email'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25.0),
                const Text(
                  'Digital ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  userData['digital_id'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 35.0),
                const Text(
                  'Section',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  userData['sec'] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2.0,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
