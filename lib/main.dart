import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final alarmService = AlarmService();
  await alarmService.loadAlarms();

  runApp(const AlarmApp());
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Alarm App",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
