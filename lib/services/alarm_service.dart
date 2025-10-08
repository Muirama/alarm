import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';
import 'alarm_storage.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentAlarmId = null;
      _playStopTimer?.cancel();
      _playStopTimer = null;
      print('[AlarmService] onPlayerComplete -> stopped');
    });

    _player.onPlayerStateChanged.listen((state) {
      print('[AlarmService] PlayerState: $state');
    });
  }

  final List<AlarmModel> alarms = [];
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  Timer? _playStopTimer;

  bool _isPlaying = false;
  String? _currentAlarmId;
  final Map<String, DateTime> _lastPlayed = {};

  List<String> availableSounds = [
    "assets/sounds/alahady_06h30_06h45.mp3",
    "assets/sounds/alahady_06h45.mp3",
    "assets/sounds/alahady_07h_09h_jmf.mp3",
    "assets/sounds/alahady_07h_09h_zozefa_be.mp3",
    "assets/sounds/angelus_6h.mp3",
    "assets/sounds/ave_maria_12h.mp3",
    "assets/sounds/lakolosy_18h.mp3",
    "assets/sounds/mariazy.mp3",
  ];

  Future<void> playSound(String path, [String? alarmId]) async {
    if (_isPlaying) {
      print('[AlarmService] playSound demandé mais déjà en cours -> skip');
      return;
    }

    _isPlaying = true;
    _currentAlarmId = alarmId;
    try {
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);

      final assetPath = path.replaceFirst("assets/", "");
      print('[AlarmService] play -> $assetPath (alarmId=$alarmId)');

      await _player.play(AssetSource(assetPath));

      _playStopTimer?.cancel();
      _playStopTimer = Timer(const Duration(minutes: 1, seconds: 30), () {
        print('[AlarmService] Arrêt forcé après 1 minute 30');
        stopSound();
      });
    } catch (e, st) {
      print('[AlarmService] Erreur playSound: $e\n$st');
      _isPlaying = false;
      _currentAlarmId = null;
      _playStopTimer?.cancel();
      _playStopTimer = null;
    }
  }

  Future<void> stopSound() async {
    try {
      _playStopTimer?.cancel();
      _playStopTimer = null;
      await _player.stop();
    } catch (e) {
      print('[AlarmService] Erreur stopSound: $e');
    } finally {
      _isPlaying = false;
      _currentAlarmId = null;
      print('[AlarmService] stopSound -> done');
    }
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

      if (alarm.date != null) {
        if (alarm.date!.year == now.year &&
            alarm.date!.month == now.month &&
            alarm.date!.day == now.day &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {
          final last = _lastPlayed[alarm.id];
          if (last == null || now.difference(last).inMinutes >= 1) {
            playSound(alarm.sound, alarm.id);
            _lastPlayed[alarm.id] = now;
            alarm.isActive = false;
            updateAlarm(alarm);
          }
        }
      }
      else if (alarm.days != null &&
          alarm.days!.contains(_dayName(now.weekday)) &&
          alarm.time.hour == now.hour &&
          alarm.time.minute == now.minute) {
        final last = _lastPlayed[alarm.id];
        if (last == null || now.difference(last).inMinutes >= 1) {
          playSound(alarm.sound, alarm.id);
          _lastPlayed[alarm.id] = now;
        }
      }
    }
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Lundi";
      case 2:
        return "Mardi";
      case 3:
        return "Mercredi";
      case 4:
        return "Jeudi";
      case 5:
        return "Vendredi";
      case 6:
        return "Samedi";
      case 7:
        return "Dimanche";
      default:
        return "";
    }
  }

  Future<void> loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    alarms.clear();
    alarms.addAll(loaded);
    if (alarms.isNotEmpty) {
      _scheduleCheck();
    }
  }
}
