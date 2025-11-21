import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String isolateName = 'alarm_isolate_port';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AndroidAlarmManager.initialize();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final alarmService = AlarmService();
  await alarmService.loadAlarms();

  runApp(const AlarmApp());
}

@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  print('[AlarmCallback] id=$id, params=$params');
  
  final sound = params['sound'] as String? ?? 'assets/sounds/angelus_6h.mp3';
  final soundBase = sound.split('/').last.split('.').first;

  // ✅ Notification
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(const InitializationSettings(android: initSettings));

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarm Notifications',
    channelDescription: 'Notifications pour les alarmes catholiques',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(soundBase),
    fullScreenIntent: true,
    visibility: NotificationVisibility.public,
    enableVibration: true,
    ongoing: true, // ✅ Notification persistante
  );

  await notifications.show(
    id,
    '⏰ Réveil Catholique',
    'Il est temps de prier 🙏',
    NotificationDetails(android: androidDetails),
  );

  // ✅ Jouer le son via AudioPlayer pour 1min30 max
  final service = AlarmService();
  await service.playSound(sound);
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Réveil Catholique',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFFFFD54F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
