import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyAlarmApp());
}

class MyAlarmApp extends StatelessWidget {
  const MyAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Réveil',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
