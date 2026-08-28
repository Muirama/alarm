// ignore_for_file: avoid_print

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import '../models/alarm_model.dart';
import 'alarm_storage.dart';
import 'alarm_player.dart';
import 'alarm_scheduler.dart'; // pour nextOccurrence() top-level

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Callback TOP-LEVEL annoté @pragma — requis par AndroidAlarmManager
//    S'exécute dans un isolat Flutter séparé.
//    NE PAS utiliser de singletons qui dépendent de l'état UI ici.
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  // Le callback tourne dans un isolat distinct lorsque l'application est
  // fermée ou l'écran verrouillé. Le binding est requis pour les MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  _log('🔔 Déclenchée — id=$id params=$params');

  final alarmId = params['alarmId'] as String?;
  final sound = params['sound'] as String? ?? 'assets/sounds/angelus_6h.mp3';
  final isOneTime = params['isOneTime'] as bool? ?? false;
  final isRecurring = params['isRecurring'] as bool? ?? false;

  if (alarmId == null) {
    _log('❌ alarmId manquant, abandon');
    return;
  }

  // Charger puis valider l'alarme avant toute lecture. Une alarme peut avoir
  // été supprimée ou désactivée entre le déclenchement Android et ce callback.
  final alarms = await AlarmStorage.loadAlarms();
  final alarm = alarms.where((a) => a.id == alarmId).firstOrNull;

  if (alarm == null) {
    _log('⚠️ Alarme $alarmId introuvable dans le storage');
    return;
  }
  if (!alarm.isActive) {
    _log('ℹ️ Alarme $alarmId désactivée, aucun son joué');
    return;
  }

  // AlarmPlayer est un singleton léger (AudioPlayer), sans dépendance UI.
  await AlarmPlayer().play(sound);

  // ── Post-traitement ─────────────────────────
  if (isOneTime) {
    await _handleOneTime(alarm, alarms);
  } else if (isRecurring && alarm.isActive) {
    await _handleRecurring(alarm, id);
  }
}

/// Désactive l'alarme ponctuelle après déclenchement.
Future<void> _handleOneTime(AlarmModel alarm, List<AlarmModel> alarms) async {
  alarm.isActive = false;
  await AlarmStorage.saveAlarms(alarms);
  _log('📅 Alarme ponctuelle désactivée: ${alarm.id}');
}

/// Reprogramme l'alarme récurrente à sa prochaine occurrence.
Future<void> _handleRecurring(AlarmModel alarm, int androidId) async {
  // Petit délai pour éviter conflit avec l'alarme qui vient de se déclencher
  await Future.delayed(const Duration(seconds: 2));

  final next = nextOccurrence(alarm); // top-level depuis alarm_scheduler.dart

  if (next != null) {
    _log('🔁 Reprogrammation: $next');
    final scheduled = await AndroidAlarmManager.oneShotAt(
      next,
      androidId,
      alarmCallback, // se rappelle lui-même ✅
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'alarmId': alarm.id, 'sound': alarm.sound, 'isRecurring': true},
    );
    if (!scheduled) {
      _log('❌ Échec de reprogrammation: ${alarm.id}');
    }
  } else {
    _log('⚠️ Aucune prochaine occurrence pour: ${alarm.id}');
  }
}

void _log(String msg) => print('[AlarmCallback] $msg');
