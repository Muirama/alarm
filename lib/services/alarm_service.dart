import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';
import 'alarm_storage.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    // Écoute des événements du player pour maintenir l'état propre
    _player.onPlayerComplete.listen((_) {
      // lecture terminée naturellement
      _isPlaying = false;
      _currentAlarmId = null;
      _playStopTimer?.cancel();
      _playStopTimer = null;
      print('[AlarmService] onPlayerComplete -> stopped');
    });

    _player.onPlayerStateChanged.listen((state) {
      // utile pour debug si besoin
      print('[AlarmService] PlayerState: $state');
    });
  }

  final List<AlarmModel> alarms = [];
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;

  // Timer pour forcer l'arrêt après 1 minute
  Timer? _playStopTimer;

  // état et id de la lecture courante
  bool _isPlaying = false;
  String? _currentAlarmId;

  // pour éviter de relancer la même alarme plusieurs fois dans la même minute
  final Map<String, DateTime> _lastPlayed = {};

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

  /// Joue un son. [alarmId] est optionnel mais recommandé pour éviter
  /// de relancer plusieurs fois la même alarme.
  Future<void> playSound(String path, [String? alarmId]) async {
    if (_isPlaying) {
      print('[AlarmService] playSound demandé mais déjà en cours -> skip');
      return;
    }

    _isPlaying = true;
    _currentAlarmId = alarmId;
    try {
      // Assure un mode adapté sur Android, et ne pas libérer la ressource automatiquement
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);

      final assetPath = path.replaceFirst("assets/", "");
      print('[AlarmService] play -> $assetPath (alarmId=$alarmId)');

      // Joue la source (AssetSource attend le chemin relatif aux assets déclarés)
      await _player.play(AssetSource(assetPath));

      // Planifie un arrêt forcé après 1 minute si nécessaire
      _playStopTimer?.cancel();
      _playStopTimer = Timer(const Duration(minutes: 1), () {
        print('[AlarmService] Arrêt forcé après 1 minute');
        stopSound();
      });
    } catch (e, st) {
      print('[AlarmService] Erreur playSound: $e\n$st');
      // remets l'état à false en cas d'erreur
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
    // 30s est correct mais si tu veux réduire les risques de jank, tu peux monter à 60s
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
        final last = _lastPlayed[alarm.id];
        if (last == null || now.difference(last).inMinutes >= 1) {
          // Passe l'id pour qu'on sache quelle alarme a déclenché
          playSound(alarm.sound, alarm.id);
          _lastPlayed[alarm.id] = now;
        } else {
          print(
            '[AlarmService] Alarme ${alarm.id} déjà jouée il y a ${now.difference(last).inSeconds}s -> skip',
          );
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
