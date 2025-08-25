import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm_model.dart';
import '../main.dart';

Future<void> alarmCallback(int alarmId) async {
  // Initialisation Hive dans l'isolate
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  final box = await Hive.openBox<AlarmModel>('alarms');

  final alarmList = box.values.where((a) => a.id == alarmId);
  if (alarmList.isEmpty) return;
  final alarm = alarmList.first;

  if (!alarm.isActive) return;

  // Notification avec son natif
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarmes',
    channelDescription: 'Notifications pour les alarmes',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
      'alarm',
    ), // mettre alarm.mp3 dans res/raw
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    alarm.id,
    'Réveil',
    '⏰ Votre alarme sonne !',
    notificationDetails,
  );

  // Auto-extinction optionnelle (ex: 1 min)
  // Timer(const Duration(minutes: 1), () async {
    // Ici, le son natif s'arrêtera automatiquement avec la notification
  // });
}
