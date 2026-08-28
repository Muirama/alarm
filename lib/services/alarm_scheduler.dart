// ignore_for_file: avoid_print

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/alarm_model.dart';
import 'alarm_callback.dart'; // callback top-level

/// Planifie et annule les alarmes système Android.
class AlarmScheduler {
  AlarmScheduler._(); // non instanciable

  // ─── Planification ─────────────────────────
  static Future<void> schedule(AlarmModel alarm) async {
    if (!alarm.isActive) return;

    final now = DateTime.now();

    if (alarm.isOneTime && alarm.date != null) {
      await _scheduleOneShot(alarm, now);
    } else if (alarm.isRecurring) {
      await _scheduleRecurring(alarm, now);
    }
  }

  static Future<void> _scheduleOneShot(AlarmModel alarm, DateTime now) async {
    final alarmDateTime = DateTime(
      alarm.date!.year,
      alarm.date!.month,
      alarm.date!.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (alarmDateTime.isAfter(now)) {
      _log('📅 Ponctuelle: $alarmDateTime');
      final scheduled = await AndroidAlarmManager.oneShotAt(
        alarmDateTime,
        alarm.androidAlarmId,
        alarmCallback, // top-level — isolat safe ✅
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: _buildParams(alarm, isOneTime: true),
      );
      if (!scheduled) {
        throw AlarmScheduleException('La planification de l\'alarme a échoué.');
      }
    } else {
      _log('⚠️ Date passée, alarme non planifiée: ${alarm.id}');
    }
  }

  static Future<void> _scheduleRecurring(AlarmModel alarm, DateTime now) async {
    final next = nextOccurrence(alarm, now); // top-level ✅
    if (next != null) {
      _log('🔁 Récurrente: $next');
      final scheduled = await AndroidAlarmManager.oneShotAt(
        next,
        alarm.androidAlarmId,
        alarmCallback,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: _buildParams(alarm, isRecurring: true),
      );
      if (!scheduled) {
        throw AlarmScheduleException('La planification de l\'alarme a échoué.');
      }
    } else {
      _log('⚠️ Aucune occurrence trouvée: ${alarm.id}');
    }
  }

  // ─── Annulation ────────────────────────────
  static Future<void> cancel(AlarmModel alarm) async {
    await AndroidAlarmManager.cancel(alarm.androidAlarmId);
    _log('❌ Annulée: ${alarm.androidAlarmId}');
  }

  // ─── Params ────────────────────────────────
  static Map<String, dynamic> _buildParams(
    AlarmModel alarm, {
    bool isOneTime = false,
    bool isRecurring = false,
  }) => {
    'alarmId': alarm.id,
    'sound': alarm.sound,
    'isOneTime': isOneTime,
    'isRecurring': isRecurring,
  };

  static void _log(String msg) => print('[AlarmScheduler] $msg');
}

class AlarmScheduleException implements Exception {
  const AlarmScheduleException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔑 Fonction TOP-LEVEL : accessible depuis n'importe quel isolat
// ─────────────────────────────────────────────────────────────────────────────

/// Calcule la prochaine occurrence d'une alarme récurrente.
/// Top-level pour être utilisable dans l'isolat du callback Android.
DateTime? nextOccurrence(AlarmModel alarm, [DateTime? from]) {
  if (alarm.days == null || alarm.days!.isEmpty) return null;

  final now = from ?? DateTime.now();

  for (int i = 0; i <= 8; i++) {
    final checkDate = now.add(Duration(days: i));
    final dayName = _weekdayName(checkDate.weekday);

    if (alarm.days!.contains(dayName)) {
      final candidate = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
        alarm.time.hour,
        alarm.time.minute,
      );

      if (i == 0) {
        // Aujourd'hui : doit être au moins 30 secondes dans le futur
        if (candidate.isAfter(now.add(const Duration(seconds: 30)))) {
          return candidate;
        }
      } else {
        return candidate;
      }
    }
  }
  return null;
}

String _weekdayName(int weekday) {
  const days = {
    1: 'Lundi',
    2: 'Mardi',
    3: 'Mercredi',
    4: 'Jeudi',
    5: 'Vendredi',
    6: 'Samedi',
    7: 'Dimanche',
  };
  return days[weekday] ?? '';
}
