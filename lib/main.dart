import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/alarm_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmRepository().init();
  runApp(const AlarmApp());
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.blue.shade700;
    return MaterialApp(
      title: 'Réveil Catholique',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
