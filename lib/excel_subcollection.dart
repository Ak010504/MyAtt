import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:attendance/firebase_options.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase app
  await exportData(); // Call exportData function when the app starts
  runApp(const MyApp());
}

Future<void> exportData() async {
  final DocumentReference documentRef =
      FirebaseFirestore.instance.collection("classes").doc("2226BECSEA");

  // Load CSV file from assets
  String csvString = await rootBundle.loadString('assets/2226BECSEA.csv');

  // Parse CSV data
  List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

  // Iterate through the CSV rows, skipping the header row
  for (int i = 1; i < csvTable.length; i++) {
    // Get the values from the 3rd and 4th columns
    String subcollectionNameStr = csvTable[i][2].toString().trim();
    String nameValue = csvTable[i][3].toString().trim();

    // Ensure the subcollection name is not empty
    if (subcollectionNameStr.isNotEmpty) {
      // Create a document named "info" in the subcollection with a field "name"
      await documentRef
          .collection(subcollectionNameStr)
          .doc('info')
          .set({'name': nameValue});
      print(
          "Created subcollection: $subcollectionNameStr with document 'info' having name: $nameValue");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel to Firestore Uploader',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Excel to Firestore Uploader'),
        ),
        body: const Center(
          child: Text('Data Exported to Firestore!'), // Placeholder UI
        ),
      ),
    );
  }
}
