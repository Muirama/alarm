// ignore_for_file: avoid_print

import '../models/alarm_model.dart';
import 'alarm_storage.dart';
import 'alarm_scheduler.dart';
import 'alarm_player.dart';

/// Façade principale — orchestre storage, scheduler et player.
/// C'est l'unique point d'entrée pour l'UI.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  // ─── État ──────────────────────────────────
  final List<AlarmModel> alarms = [];

  // ─── Sons disponibles ──────────────────────
  static const List<String> availableSounds = [
    'assets/sounds/angelus_6h.mp3',
    'assets/sounds/alahady_06h30_06h45.mp3',
    'assets/sounds/alahady_07h_09h_jmf.mp3',
    'assets/sounds/alahady_07h_09h_Zozefa_be.mp3',
    'assets/sounds/ave_maria_12h.mp3',
    'assets/sounds/lalan_ny_Hazo_Zoma_17h.mp3',
    'assets/sounds/mariazy.mp3',
    'assets/sounds/mesia_mpamonjy.mp3',
    'assets/sounds/mitsangana_7h_9h.mp3',
  ];

  static const String fallbackSound = 'assets/sounds/angelus_6h.mp3';

  static const Map<String, String> _legacySoundPaths = {
    'assets/sounds/Alahady_07h_09h_Zozefa_be.mp3':
        'assets/sounds/alahady_07h_09h_Zozefa_be.mp3',
    'assets/sounds/Mariazy.mp3': 'assets/sounds/mariazy.mp3',
  };

  /// Garantit qu'une alarme utilise toujours un asset présent dans l'application.
  /// Les alarmes créées avant la suppression d'un son basculent sur Angelus.
  static String normalizeSoundPath(String sound) {
    final normalized = _legacySoundPaths[sound] ?? sound;
    return availableSounds.contains(normalized) ? normalized : fallbackSound;
  }

  // ─── Audio ─────────────────────────────────
  Future<void> playSound(String path) => AlarmPlayer().play(path);
  Future<void> stopSound() => AlarmPlayer().stop();

  // ─── Chargement initial ────────────────────
  Future<void> loadAlarms() async {
    final loaded = await AlarmStorage.loadAlarms();
    alarms.clear();

    final now = DateTime.now();
    bool needsSave = false;

    for (var alarm in loaded) {
      final correctedPath = normalizeSoundPath(alarm.sound);
      if (correctedPath != alarm.sound) {
        alarm = alarm.copyWith(sound: correctedPath);
        needsSave = true;
      }
      // Désactiver automatiquement les alarmes ponctuelles expirées
      if (alarm.isOneTime && alarm.date != null) {
        final alarmDateTime = DateTime(
          alarm.date!.year,
          alarm.date!.month,
          alarm.date!.day,
          alarm.time.hour,
          alarm.time.minute,
        );

        if (alarmDateTime.isBefore(now)) {
          alarm.isActive = false;
          needsSave = true;
          _log('⏭️ Ponctuelle expirée, désactivée: ${alarm.id}');
          alarms.add(alarm);
          continue;
        }
      }

      alarms.add(alarm);

      if (alarm.isActive) await _scheduleSafely(alarm);
    }

    if (needsSave) await AlarmStorage.saveAlarms(alarms);
    _log('📂 ${alarms.length} alarme(s) chargée(s)');
  }

  // ─── CRUD ──────────────────────────────────
  Future<bool> addAlarm(AlarmModel alarm) async {
    alarms.add(alarm);
    await AlarmStorage.saveAlarms(alarms);
    final scheduled = !alarm.isActive || await _scheduleSafely(alarm);
    _log('✅ Alarme ajoutée: ${alarm.id}');
    return scheduled;
  }

  /// Reprogramme les alarmes enregistrées, notamment après le retour depuis
  /// les paramètres d'autorisation Android.
  Future<void> rescheduleActiveAlarms() async {
    for (final alarm in alarms.where((alarm) => alarm.isActive)) {
      await _scheduleSafely(alarm);
    }
  }

  Future<bool> updateAlarm(AlarmModel updated) async {
    final index = alarms.indexWhere((a) => a.id == updated.id);
    if (index == -1) return false;

    // Annuler l'ancienne planification
    await AlarmScheduler.cancel(alarms[index]);

    alarms[index] = updated;
    await AlarmStorage.saveAlarms(alarms);

    final scheduled = !updated.isActive || await _scheduleSafely(updated);
    _log('🔄 Alarme mise à jour: ${updated.id}');
    return scheduled;
  }

  Future<void> removeAlarm(String id) async {
    final index = alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;

    await AlarmScheduler.cancel(alarms[index]);
    alarms.removeAt(index);
    await AlarmStorage.saveAlarms(alarms);
    _log('🗑️ Alarme supprimée: $id');
  }

  void _log(String msg) => print('[AlarmService] $msg');

  Future<bool> _scheduleSafely(AlarmModel alarm) async {
    try {
      await AlarmScheduler.schedule(alarm);
      return true;
    } catch (error) {
      // Les alarmes restent enregistrées : elles seront reprogrammées lorsque
      // l'utilisateur accordera l'autorisation puis reviendra dans l'app.
      _log('⚠️ Planification impossible pour ${alarm.id}: $error');
      return false;
    }
  }
}
