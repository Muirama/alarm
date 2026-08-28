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
    'assets/sounds/alahady_06h30_06h45.mp3',
    'assets/sounds/alahady_07h_09h_jmf.mp3',
    'assets/sounds/alahady_07h_09h_Zozefa_be.mp3',
    'assets/sounds/angelus_6h.mp3',
    'assets/sounds/ave_maria_12h.mp3',
    'assets/sounds/lakolosy_18h.mp3',
    'assets/sounds/lalan_ny_Hazo_Zoma_17h.mp3',
    'assets/sounds/mariazy.mp3',
    'assets/sounds/mesia_mpamonjy.mp3',
    'assets/sounds/mitsangana_7h_9h.mp3',
    'assets/sounds/lakolosy_cathedral_bell_dry_Angelus.mp3',
  ];

  static const Map<String, String> _legacySoundPaths = {
    'assets/sounds/Alahady_07h_09h_Zozefa_be.mp3':
        'assets/sounds/alahady_07h_09h_Zozefa_be.mp3',
    'assets/sounds/Mariazy.mp3': 'assets/sounds/mariazy.mp3',
  };

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
      final correctedPath = _legacySoundPaths[alarm.sound];
      if (correctedPath != null) {
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
  Future<void> addAlarm(AlarmModel alarm) async {
    alarms.add(alarm);
    await AlarmStorage.saveAlarms(alarms);
    if (alarm.isActive) await AlarmScheduler.schedule(alarm);
    _log('✅ Alarme ajoutée: ${alarm.id}');
  }

  /// Reprogramme les alarmes enregistrées, notamment après le retour depuis
  /// les paramètres d'autorisation Android.
  Future<void> rescheduleActiveAlarms() async {
    for (final alarm in alarms.where((alarm) => alarm.isActive)) {
      await _scheduleSafely(alarm);
    }
  }

  Future<void> updateAlarm(AlarmModel updated) async {
    final index = alarms.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;

    // Annuler l'ancienne planification
    await AlarmScheduler.cancel(alarms[index]);

    alarms[index] = updated;
    await AlarmStorage.saveAlarms(alarms);

    if (updated.isActive) await AlarmScheduler.schedule(updated);
    _log('🔄 Alarme mise à jour: ${updated.id}');
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

  Future<void> _scheduleSafely(AlarmModel alarm) async {
    try {
      await AlarmScheduler.schedule(alarm);
    } catch (error) {
      // Les alarmes restent enregistrées : elles seront reprogrammées lorsque
      // l'utilisateur accordera l'autorisation puis reviendra dans l'app.
      _log('⚠️ Planification impossible pour ${alarm.id}: $error');
    }
  }
}
