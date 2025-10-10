import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomAlarmService {
  static final CustomAlarmService _instance = CustomAlarmService._internal();
  factory CustomAlarmService() => _instance;
  CustomAlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // 🔧 CORRECTION: Gérer plusieurs alarmes simultanément
  final Map<int, Timer> _alarmTimers = {}; // Timer pour chaque alarme
  final Map<int, Timer> _soundTimers = {}; // Timer d'arrêt pour chaque alarme
  
  bool _isRinging = false;
  int? _currentAlarmId;

  Future<void> init() async {
    // Initialiser les notifications
    await _initNotifications();
    
    // Demander les permissions nécessaires
    await _requestPermissions();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> _requestPermissions() async {
    // Demander les permissions nécessaires
    await Permission.notification.request();
    if (Platform.isAndroid) {
      await Permission.systemAlertWindow.request();
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String soundPath,
    required String title,
    required String body,
  }) async {
    // Annuler toute alarme existante avec cet ID
    await cancelAlarm(id);

    final now = DateTime.now();
    final duration = dateTime.difference(now);

    if (duration.isNegative) {
      print('❌ Impossible de programmer une alarme dans le passé');
      return;
    }

    print('⏰ Alarme $id programmée pour ${dateTime.toString()}');
    print('🔔 Déclenchement dans ${duration.inMinutes} minutes et ${duration.inSeconds % 60} secondes');
    print('📊 Total alarmes programmées: ${_alarmTimers.length + 1}');

    // Programmer l'alarme avec son propre timer
    _alarmTimers[id] = Timer(duration, () async {
      await _triggerAlarm(id, soundPath, title, body);
    });
    
    print('✅ Alarme $id ajoutée. IDs programmés: ${_alarmTimers.keys.toList()}');
  }

  Future<void> _triggerAlarm(int id, String soundPath, String title, String body) async {
    if (_isRinging) {
      print('🚫 Une alarme sonne déjà, annulation de la nouvelle');
      return;
    }

    _isRinging = true;
    _currentAlarmId = id;
    
    print('🔊 ALARME $id SE DÉCLENCHE !');

    // Afficher la notification
    await _showAlarmNotification(id, title, body);

    // Jouer le son en boucle pendant 2 minutes
    await _playSoundLoop(soundPath);

    // Programmer l'arrêt automatique après 2 minutes
    _soundTimers[id] = Timer(const Duration(minutes: 2), () async {
      await stopAlarm(id);
    });
  }

  Future<void> _showAlarmNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarmes',
      channelDescription: 'Notifications pour les alarmes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
    );
  }

  Future<void> _playSoundLoop(String soundPath) async {
    try {
      // Configurer le lecteur audio
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Jouer le son
      await _audioPlayer.play(AssetSource(soundPath.replaceFirst('assets/', '')));
      
      print('🎵 Son joué en boucle: $soundPath');
      
    } catch (e) {
      print('❌ Erreur lecture son: $e');
      // Fallback: vibration seulement
      if (Platform.isAndroid) {
        // Vibration de secours (nécessiterait un plugin de vibration)
        print('📳 Vibration de secours');
      }
    }
  }

  Future<void> stopAlarm(int id) async {
    if (!_isRinging || _currentAlarmId != id) {
      return;
    }

    print('⏹️ Arrêt de l\'alarme $id');

    // Arrêter le son
    await _audioPlayer.stop();
    
    // Annuler le timer d'arrêt automatique pour cette alarme
    _soundTimers[id]?.cancel();
    _soundTimers.remove(id);
    
    // Supprimer la notification
    await _notifications.cancel(id);
    
    // Réinitialiser l'état
    _isRinging = false;
    _currentAlarmId = null;
    
    print('✅ Alarme $id arrêtée avec succès');
  }

  Future<void> cancelAlarm(int id) async {
    // Annuler le timer de programmation pour cette alarme
    _alarmTimers[id]?.cancel();
    _alarmTimers.remove(id);
    
    // Arrêter l'alarme si elle sonne
    await stopAlarm(id);
    print('🗑️ Alarme $id annulée');
  }

  bool get isRinging => _isRinging;
  int? get currentAlarmId => _currentAlarmId;
  
  // 📊 Nouvelle méthode: voir toutes les alarmes programmées
  int get scheduledAlarmsCount => _alarmTimers.length;
  List<int> get scheduledAlarmIds => _alarmTimers.keys.toList();

  Future<void> dispose() async {
    // Annuler tous les timers
    for (var timer in _alarmTimers.values) {
      timer.cancel();
    }
    for (var timer in _soundTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();
    _soundTimers.clear();
    
    await _audioPlayer.dispose();
  }
}