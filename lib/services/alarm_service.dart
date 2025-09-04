import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';
import 'alarm_storage.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final List<AlarmModel> alarms = [];
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;

  List<String> availableSounds = [
    "assets/sounds/lakolosy_6h00.mp3",
    "assets/sounds/lakolosy_6h45.mp3",
    "assets/sounds/lakolosy_12h.mp3",
    "assets/sounds/lakolosy_anjely_gabriely_Angelus_6h.mp3",
    "assets/sounds/lakolosy_anjely_gabriely_maria.mp3",
    "assets/sounds/lakolosy_Ave_Maria12h.mp3",
    "assets/sounds/lakolosy_jozefa_be_voninahitra_06h30.mp3",
    "assets/sounds/lakolosy_jozefa_mpitaiza_07h.mp3",
  ];

  Future<void> playSound(String path) async {
    await _player.stop();
    await _player.play(AssetSource(path.replaceFirst("assets/", "")));
    // Stop après 1 minute max
    Future.delayed(const Duration(minutes: 1), () {
      stopSound();
    });
  }

  Future<void> stopSound() async {
    await _player.stop();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    alarms.add(alarm);
    await AlarmStorage.saveAlarms(alarms);
    _scheduleCheck();
  }

  Future<void> removeAlarm(String id) async {
    alarms.removeWhere((a) => a.id == id);
    await AlarmStorage.saveAlarms(alarms);
  }

  Future<void> updateAlarm(AlarmModel updated) async {
    final index = alarms.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      alarms[index] = updated;
      await AlarmStorage.saveAlarms(alarms);
    }
  }

  void _scheduleCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    for (var alarm in alarms) {
      if (!alarm.isActive) continue;
      if (alarm.days.contains(_dayName(now.weekday)) &&
          alarm.time.hour == now.hour &&
          alarm.time.minute == now.minute) {
        playSound(alarm.sound);
      }
    }
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1: return "Lundi";
      case 2: return "Mardi";
      case 3: return "Mercredi";
      case 4: return "Jeudi";
      case 5: return "Vendredi";
      case 6: return "Samedi";
      case 7: return "Dimanche";
      default: return "";
    }
  }

  /// Charger les alarmes sauvegardées au démarrage
  Future<void> loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    alarms.clear();
    alarms.addAll(loaded);
    if (alarms.isNotEmpty) {
      _scheduleCheck();
    }
  }
}
