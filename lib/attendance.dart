import 'package:flutter/material.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "ATTENDANCE LIST",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 97, 167, 214),
        actions: <Widget>[
          PopupMenuButton<String>(
            offset: const Offset(0, 70),
            onSelected: (String result) {
              // Handle your action
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Profile',
                height: 50,
                child: Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/quotes1');
                },
              ),
              const PopupMenuItem<String>(
                value: 'TimeTable',
                height: 50,
                child: Text('TimeTable'),
              ),
              const PopupMenuItem<String>(
                value: 'Report',
                height: 50,
                child: Text('Report'),
              ),
              PopupMenuItem<String>(
                value: 'Logout',
                height: 50,
                child: Text('Logout'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/quotes2');
                },
              ),
            ],
            icon: const Icon(
              Icons.account_circle,
              size: 40.0,
            ),
          ),
        ],
      ),
      body: const Column(
        children: [
          SizedBox(
            height: 70.0,
          ),
          Row(
            children: [
              SizedBox(
                width: 40.0,
              ),
              Text(
                "Roll No",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
              ),
              SizedBox(width: 150),
              Text(
                "Name",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
              )
            ],
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 151, 195, 220),
    );
  }
}
