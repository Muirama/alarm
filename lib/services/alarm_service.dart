import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
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
    await _scheduleAndroidAlarm(alarm);
    _scheduleCheck();
  }

  Future<void> removeAlarm(String id) async {
    final alarmIndex = alarms.indexWhere((a) => a.id == id);
    if (alarmIndex == -1) {
      print('[AlarmService] Alarme $id déjà supprimée');
      return;
    }
    
    final alarm = alarms[alarmIndex];
    await _cancelAndroidAlarm(alarm);
    alarms.removeAt(alarmIndex);
    await AlarmStorage.saveAlarms(alarms);
    print('[AlarmService] Alarme $id supprimée');
  }

  Future<void> updateAlarm(AlarmModel updated) async {
    final index = alarms.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      // ✅ IMPORTANT: Annuler l'ancienne alarme AVANT de modifier
      final oldAlarm = alarms[index];
      await _cancelAndroidAlarm(oldAlarm);
      print('[AlarmService] Ancienne alarme annulée avant mise à jour');
      
      // ✅ Attendre un peu pour que l'annulation soit effective
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Mettre à jour
      alarms[index] = updated;
      await AlarmStorage.saveAlarms(alarms);
      
      // Reprogrammer si active
      if (updated.isActive) {
        await _scheduleAndroidAlarm(updated);
      }
    }
  }

  Future<void> _scheduleAndroidAlarm(AlarmModel alarm) async {
    if (!alarm.isActive) return;

    final int alarmId = alarm.id.hashCode;
    final now = DateTime.now();

    if (alarm.isOneTime && alarm.date != null) {
      final alarmDateTime = DateTime(
        alarm.date!.year,
        alarm.date!.month,
        alarm.date!.day,
        alarm.time.hour,
        alarm.time.minute,
      );

      if (alarmDateTime.isAfter(now)) {
        print('[AlarmService] Programmation oneShot: $alarmDateTime (id=$alarmId)');
        await AndroidAlarmManager.oneShotAt(
          alarmDateTime,
          alarmId,
          _androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {'alarmId': alarm.id, 'sound': alarm.sound},
        );
      }
    } else if (alarm.days != null && alarm.days!.isNotEmpty) {
      final nextOccurrence = _getNextOccurrence(alarm);
      if (nextOccurrence != null) {
        print('[AlarmService] Programmation récurrente: $nextOccurrence (id=$alarmId)');
        await AndroidAlarmManager.oneShotAt(
          nextOccurrence,
          alarmId,
          _androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {'alarmId': alarm.id, 'sound': alarm.sound, 'recurring': true},
        );
      }
    }
  }

  Future<void> _cancelAndroidAlarm(AlarmModel alarm) async {
    final int alarmId = alarm.id.hashCode;
    await AndroidAlarmManager.cancel(alarmId);
    print('[AlarmService] Alarme système annulée: $alarmId');
  }

  DateTime? _getNextOccurrence(AlarmModel alarm) {
    if (alarm.days == null || alarm.days!.isEmpty) return null;

    final now = DateTime.now();
    final todayWeekday = now.weekday;
    
    for (int i = 0; i < 7; i++) {
      final checkDay = (todayWeekday + i - 1) % 7 + 1;
      final dayName = _dayName(checkDay);
      
      if (alarm.days!.contains(dayName)) {
        var candidate = DateTime(
          now.year,
          now.month,
          now.day + i,
          alarm.time.hour,
          alarm.time.minute,
        );
        
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    return null;
  }

  void _scheduleCheck() {
    _timer?.cancel();
  }

  void _checkAlarms() {
    // Non utilisé - AndroidAlarmManager gère tout
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

  // ✅ Méthode séparée pour charger SANS reprogrammer (utilisée par callback)
  Future<AlarmModel?> getAlarmById(String alarmId) async {
    final loaded = await AlarmStorage.loadAlarms();
    try {
      return loaded.firstWhere((a) => a.id == alarmId);
    } catch (e) {
      print('[AlarmService] Alarme $alarmId non trouvée dans storage');
      return null;
    }
  }

  Future<void> loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    alarms.clear();
    alarms.addAll(loaded);
    
    // ✅ Reprogrammer toutes les alarmes actives au démarrage
    print('[AlarmService] Chargement de ${alarms.length} alarmes');
    for (var alarm in alarms) {
      if (alarm.isActive) {
        await _scheduleAndroidAlarm(alarm);
      }
    }
  }
}

// ✅ Callback optimisé - ne recharge QUE l'alarme concernée
@pragma('vm:entry-point')
void _androidAlarmCallback(int id, Map<String, dynamic> params) async {
  print('[AndroidAlarmCallback] Déclenchée: id=$id, params=$params');
  
  final alarmId = params['alarmId'] as String?;
  final sound = params['sound'] as String? ?? 'assets/sounds/angelus_6h.mp3';
  final isRecurring = params['recurring'] as bool? ?? false;

  // ✅ Jouer le son
  final service = AlarmService();
  await service.playSound(sound, alarmId);

  // ✅ Si récurrente, reprogrammer UNIQUEMENT cette alarme
  if (isRecurring && alarmId != null) {
    try {
      // ✅ Charger SEULEMENT cette alarme depuis le storage
      final alarm = await service.getAlarmById(alarmId);
      
      if (alarm == null) {
        print('[AndroidAlarmCallback] Alarme $alarmId introuvable, annulation');
        return;
      }
      
      // Vérifier qu'elle est toujours active et récurrente
      if (alarm.isActive && alarm.days != null && alarm.days!.isNotEmpty) {
        final nextOccurrence = service._getNextOccurrence(alarm);
        if (nextOccurrence != null) {
          print('[AndroidAlarmCallback] Reprogrammation: $nextOccurrence');
          
          // ✅ Reprogrammer avec le même ID
          await AndroidAlarmManager.oneShotAt(
            nextOccurrence,
            id,
            _androidAlarmCallback,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
            params: {
              'alarmId': alarm.id,
              'sound': alarm.sound,
              'recurring': true,
            },
          );
        } else {
          print('[AndroidAlarmCallback] Pas de prochaine occurrence trouvée');
        }
      } else {
        print('[AndroidAlarmCallback] Alarme désactivée ou non récurrente, pas de reprogrammation');
      }
    } catch (e, st) {
      print('[AndroidAlarmCallback] Erreur reprogrammation: $e\n$st');
    }
  }
}
