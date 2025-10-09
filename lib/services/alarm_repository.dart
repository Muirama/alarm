import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class AlarmRepository {
  static const _storageKey = 'stored_alarms_v1';
  final List<AlarmModel> alarms = [];
  StreamSubscription? _ringingSub;
  
  AlarmRepository._internal();
  static final AlarmRepository _instance = AlarmRepository._internal();
  factory AlarmRepository() => _instance;

  Future<void> init() async {
    await Alarm.init();
    await _loadFromStorage();
    _listenRinging();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final list = AlarmModel.listFromJson(raw);
    alarms.clear();
    alarms.addAll(list);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, AlarmModel.listToJson(alarms));
  }

  /// compute next DateTime for a given weekday list (["Lundi","Mardi"...])
  DateTime _nextDateForWeekdays(List<String> days, TimeOfDayLikeTod time) {
    final mapping = {
      "Lundi": DateTime.monday,
      "Mardi": DateTime.tuesday,
      "Mercredi": DateTime.wednesday,
      "Jeudi": DateTime.thursday,
      "Vendredi": DateTime.friday,
      "Samedi": DateTime.saturday,
      "Dimanche": DateTime.sunday,
    };

    final now = DateTime.now();
    final targetWeekdays =
        days.map((d) => mapping[d]!).toList()..sort(); // ints

    // start from today at target time
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    for (int add = 0; add < 14; add++) {
      final d = candidate.add(Duration(days: add));
      if (targetWeekdays.contains(d.weekday)) {
        // if it's today but time already passé, skip it
        if (add == 0 && d.isBefore(DateTime.now())) {
          continue;
        }
        return DateTime(d.year, d.month, d.day, time.hour, time.minute);
      }
    }

    // fallback: same day next week
    return candidate.add(const Duration(days: 7));
  }

  /// Create and schedule an alarm (if recurring -> schedule next occurrence)
  Future<void> createAlarm(AlarmModel model) async {
    // schedule native alarm (await is important)
    await _scheduleNative(model);

    alarms.add(model);
    await _saveToStorage();
  }

  /// Update an existing alarm: cancel previous native scheduled alarm (if any) then schedule new
  Future<void> updateAlarm(AlarmModel model) async {
    await Alarm.stop(model.id); // stop previous (await)
    if (model.isActive) {
      await _scheduleNative(model);
    }
    final idx = alarms.indexWhere((a) => a.id == model.id);
    if (idx >= 0) alarms[idx] = model;
    await _saveToStorage();
  }

  /// Remove alarm (both local and native)
  Future<void> deleteAlarm(int id) async {
    await Alarm.stop(id);
    alarms.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  Future<void> toggleActive(int id, bool active) async {
    final idx = alarms.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    final a = alarms[idx];
    a.isActive = active;
    if (!active) {
      await Alarm.stop(id);
    } else {
      await _scheduleNative(a);
    }
    await _saveToStorage();
  }

  Future<void> _scheduleNative(AlarmModel model) async {
    final dateTime = model.time;

    final settings = AlarmSettings(
      id: model.id,
      dateTime: dateTime,
      assetAudioPath: model.soundAsset,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: Platform.isIOS,
      notificationSettings: NotificationSettings(
        title: 'Réveil',
        body: 'Il est temps de prier',
        stopButton: 'Arrêter',
        icon: 'notification_icon',
      ),
      // utilise un constructeur valide : fixed (pas de fade par défaut)
      volumeSettings: VolumeSettings.fixed(volume: null, volumeEnforced: false),
    );

    await Alarm.set(alarmSettings: settings);
  }

  void _listenRinging() {
    // annule ancienne subscription si existante
    _ringingSub?.cancel();

    // NOTE: on garde la signature simple pour éviter des erreurs de typage
    _ringingSub = Alarm.ringing.listen((alarmSet) async {
      try {
        // alarmSet.alarms contient des AlarmSettings natifs du plugin
        final nativeAlarms = alarmSet.alarms;
        for (final nativeAlarm in nativeAlarms) {
          final id = nativeAlarm.id;
          final idx = alarms.indexWhere((a) => a.id == id);
          if (idx == -1) continue; // pas dans notre liste -> ignore

          final stored = alarms[idx];

          // if recurring -> reschedule next occurrence (weekly logic)
          if (stored.days != null && stored.days!.isNotEmpty) {
            final tod = TimeOfDayLikeTod.fromDateTime(stored.time);
            final next = _nextDateForWeekdays(stored.days!, tod);

            // create a replacement AlarmModel (on ne modifie pas un champ final)
            final replacement = AlarmModel(
              id: stored.id,
              days: stored.days,
              time: next,
              date: null,
              soundAsset: stored.soundAsset,
              isActive: stored.isActive,
            );

            alarms[idx] = replacement;
            await _saveToStorage();

            // schedule the next native occurrence
            await _scheduleNative(replacement);
          } else {
            // one-time alarm -> disable after ringing
            final updated = AlarmModel(
              id: stored.id,
              days: null,
              time: stored.time,
              date: stored.date,
              soundAsset: stored.soundAsset,
              isActive: false,
            );
            alarms[idx] = updated;
            await _saveToStorage();
          }
        }
      } catch (e, st) {
        // log silently - évite crash si l'event arrive et qu'il y a un souci
        // print('Error handling ringing event: $e\n$st');
      }
    });
  }

  Future<void> dispose() async {
    await _ringingSub?.cancel();
  }
}

/// Helper léger pour manipuler hour/minute facilement
class TimeOfDayLikeTod {
  final int hour;
  final int minute;
  TimeOfDayLikeTod(this.hour, this.minute);
  factory TimeOfDayLikeTod.fromDateTime(DateTime dt) =>
      TimeOfDayLikeTod(dt.hour, dt.minute);
}
