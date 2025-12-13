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
      print('[AlarmService] Son terminé naturellement');
    });
  }

  final List<AlarmModel> alarms = [];
  final AudioPlayer _player = AudioPlayer();
  Timer? _playStopTimer;

  bool _isPlaying = false;
  String? _currentAlarmId;

  List<String> availableSounds = [
    "assets/sounds/alahady_06h30_06h45.mp3",
    "assets/sounds/alahady_06h45.mp3",
    "assets/sounds/alahady_07h_09h_jmf.mp3",
    "assets/sounds/alahady_07h_09h_Zozefa_be.mp3",
    "assets/sounds/angelus_6h.mp3",
    "assets/sounds/ave_maria_12h.mp3",
    "assets/sounds/lakolosy_18h.mp3",
    "assets/sounds/mariazy.mp3",
    "assets/sounds/mesia_mpamonjy.mp3"
  ];

  Future<void> playSound(String path, [String? alarmId]) async {
    if (_isPlaying) {
      print('[AlarmService] Son déjà en lecture, ignoré');
      return;
    }

    _isPlaying = true;
    _currentAlarmId = alarmId;
    
    try {
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);

      final assetPath = path.replaceFirst("assets/", "");
      print('[AlarmService] ▶️ Lecture: $assetPath');

      await _player.play(AssetSource(assetPath));

      // ✅ Arrêt automatique après 2 minutes
      _playStopTimer?.cancel();
      _playStopTimer = Timer(const Duration(minutes: 2), () {
        print('[AlarmService] ⏱️ Arrêt automatique après 2 minutes');
        stopSound();
      });
    } catch (e, st) {
      print('[AlarmService] ❌ Erreur lecture: $e\n$st');
      _isPlaying = false;
      _currentAlarmId = null;
    }
  }

  Future<void> stopSound() async {
    try {
      _playStopTimer?.cancel();
      _playStopTimer = null;
      await _player.stop();
      print('[AlarmService] ⏹️ Son arrêté');
    } catch (e) {
      print('[AlarmService] Erreur arrêt: $e');
    } finally {
      _isPlaying = false;
      _currentAlarmId = null;
    }
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    alarms.add(alarm);
    await AlarmStorage.saveAlarms(alarms);
    
    if (alarm.isActive) {
      await _scheduleAndroidAlarm(alarm);
    }
    
    print('[AlarmService] ✅ Alarme ajoutée: ${alarm.id}');
  }

  Future<void> removeAlarm(String id) async {
    final alarmIndex = alarms.indexWhere((a) => a.id == id);
    if (alarmIndex == -1) return;
    
    final alarm = alarms[alarmIndex];
    await _cancelAndroidAlarm(alarm);
    alarms.removeAt(alarmIndex);
    await AlarmStorage.saveAlarms(alarms);
    
    print('[AlarmService] 🗑️ Alarme supprimée: $id');
  }

  Future<void> updateAlarm(AlarmModel updated) async {
    final index = alarms.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    
    final oldAlarm = alarms[index];
    await _cancelAndroidAlarm(oldAlarm);
    
    alarms[index] = updated;
    await AlarmStorage.saveAlarms(alarms);
    
    if (updated.isActive) {
      await _scheduleAndroidAlarm(updated);
    }
    
    print('[AlarmService] 🔄 Alarme mise à jour: ${updated.id}');
  }

  Future<void> _scheduleAndroidAlarm(AlarmModel alarm) async {
    if (!alarm.isActive) return;

    final int alarmId = alarm.id.hashCode;
    final now = DateTime.now();

    // ✅ Alarme ponctuelle (date fixe)
    if (alarm.isOneTime && alarm.date != null) {
      final alarmDateTime = DateTime(
        alarm.date!.year,
        alarm.date!.month,
        alarm.date!.day,
        alarm.time.hour,
        alarm.time.minute,
      );

      if (alarmDateTime.isAfter(now)) {
        print('[AlarmService] 📅 Programmation ponctuelle: $alarmDateTime');
        await AndroidAlarmManager.oneShotAt(
          alarmDateTime,
          alarmId,
          _androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'alarmId': alarm.id,
            'sound': alarm.sound,
            'isOneTime': true,
          },
        );
      }
    } 
    // ✅ Alarme récurrente (jours de la semaine)
    else if (alarm.days != null && alarm.days!.isNotEmpty) {
      final nextOccurrence = _getNextOccurrence(alarm);
      if (nextOccurrence != null) {
        print('[AlarmService] 🔁 Programmation récurrente: $nextOccurrence');
        await AndroidAlarmManager.oneShotAt(
          nextOccurrence,
          alarmId,
          _androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: {
            'alarmId': alarm.id,
            'sound': alarm.sound,
            'isRecurring': true,
          },
        );
      }
    }
  }

  Future<void> _cancelAndroidAlarm(AlarmModel alarm) async {
    final int alarmId = alarm.id.hashCode;
    await AndroidAlarmManager.cancel(alarmId);
    print('[AlarmService] ❌ Alarme système annulée: $alarmId');
  }

  DateTime? _getNextOccurrence(AlarmModel alarm) {
    if (alarm.days == null || alarm.days!.isEmpty) return null;

    final now = DateTime.now();
    
    // ✅ Chercher la prochaine occurrence dans les 7 prochains jours
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final dayName = _dayName(checkDate.weekday);
      
      if (alarm.days!.contains(dayName)) {
        var candidate = DateTime(
          checkDate.year,
          checkDate.month,
          checkDate.day,
          alarm.time.hour,
          alarm.time.minute,
        );
        
        // ✅ Doit être dans le futur
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    return null;
  }

  String _dayName(int weekday) {
    const days = {
      1: "Lundi",
      2: "Mardi",
      3: "Mercredi",
      4: "Jeudi",
      5: "Vendredi",
      6: "Samedi",
      7: "Dimanche",
    };
    return days[weekday] ?? "";
  }

  Future<void> loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    alarms.clear();
    alarms.addAll(loaded);
    
    print('[AlarmService] 📂 ${alarms.length} alarme(s) chargée(s)');
    
    // ✅ Reprogrammer uniquement les alarmes actives
    for (var alarm in alarms) {
      if (alarm.isActive) {
        // ✅ Vérifier si alarme ponctuelle passée
        if (alarm.isOneTime && alarm.date != null) {
          final alarmDateTime = DateTime(
            alarm.date!.year,
            alarm.date!.month,
            alarm.date!.day,
            alarm.time.hour,
            alarm.time.minute,
          );
          
          if (alarmDateTime.isBefore(DateTime.now())) {
            // ✅ Désactiver automatiquement
            alarm.isActive = false;
            print('[AlarmService] ⏭️ Alarme ponctuelle passée, désactivée: ${alarm.id}');
            continue;
          }
        }
        
        await _scheduleAndroidAlarm(alarm);
      }
    }
    
    // ✅ Sauvegarder les changements (alarmes expirées désactivées)
    await AlarmStorage.saveAlarms(alarms);
  }
}

// ✅ Callback unique pour toutes les alarmes
@pragma('vm:entry-point')
void _androidAlarmCallback(int id, Map<String, dynamic> params) async {
  print('[🔔 ALARME] Déclenchée: id=$id');
  
  final alarmId = params['alarmId'] as String?;
  final sound = params['sound'] as String? ?? 'assets/sounds/angelus_6h.mp3';
  final isOneTime = params['isOneTime'] as bool? ?? false;
  final isRecurring = params['isRecurring'] as bool? ?? false;

  if (alarmId == null) {
    print('[🔔 ALARME] Erreur: alarmId manquant');
    return;
  }

  final service = AlarmService();

  // ✅ 1. Jouer le son (max 2 min)
  await service.playSound(sound, alarmId);

  // ✅ 2. Charger les alarmes pour traitement
  final alarms = await AlarmStorage.loadAlarms();
  final alarm = alarms.where((a) => a.id == alarmId).firstOrNull;

  if (alarm == null) {
    print('[🔔 ALARME] Alarme $alarmId introuvable dans storage');
    return;
  }

  // ✅ 3. Si alarme ponctuelle, la désactiver automatiquement
  if (isOneTime) {
    alarm.isActive = false;
    await AlarmStorage.saveAlarms(alarms);
    print('[🔔 ALARME] Alarme ponctuelle désactivée: $alarmId');
  }
  
  // ✅ 4. Si alarme récurrente, reprogrammer la prochaine occurrence
  else if (isRecurring && alarm.isActive) {
    final nextOccurrence = service._getNextOccurrence(alarm);
    
    if (nextOccurrence != null) {
      print('[🔔 ALARME] Reprogrammation: $nextOccurrence');
      
      await AndroidAlarmManager.oneShotAt(
        nextOccurrence,
        id, // ✅ Même ID pour éviter les doublons
        _androidAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {
          'alarmId': alarm.id,
          'sound': alarm.sound,
          'isRecurring': true,
        },
      );
    } else {
      print('[🔔 ALARME] Aucune prochaine occurrence trouvée');
    }
  }
}
