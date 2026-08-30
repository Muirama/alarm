import 'package:alarm_fiangonana/models/alarm_model.dart';
import 'package:alarm_fiangonana/services/alarm_scheduler.dart';
import 'package:alarm_fiangonana/services/alarm_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AlarmModel recurringAlarm(List<String> days, DateTime time) => AlarmModel(
    id: 'alarm-id',
    days: days,
    time: time,
    sound: 'assets/sounds/angelus_6h.mp3',
  );

  test('nextOccurrence returns the selected day later in the week', () {
    final from = DateTime(2026, 8, 31, 9); // lundi
    final alarm = recurringAlarm(['Mercredi'], DateTime(2026, 1, 1, 7, 30));

    expect(nextOccurrence(alarm, from), DateTime(2026, 9, 2, 7, 30));
  });

  test('nextOccurrence skips an occurrence already passed today', () {
    final from = DateTime(2026, 8, 31, 8); // lundi
    final alarm = recurringAlarm(['Lundi'], DateTime(2026, 1, 1, 7, 30));

    expect(nextOccurrence(alarm, from), DateTime(2026, 9, 7, 7, 30));
  });

  test('Android alarm id is deterministic and positive', () {
    final alarm = recurringAlarm(['Lundi'], DateTime(2026, 1, 1, 7));

    expect(alarm.androidAlarmId, greaterThanOrEqualTo(0));
    expect(alarm.androidAlarmId, alarm.androidAlarmId);
  });

  test('a removed or legacy sound falls back to an available asset', () {
    expect(
      AlarmService.normalizeSoundPath('assets/sounds/lakolosy_18h.mp3'),
      AlarmService.fallbackSound,
    );
    expect(
      AlarmService.normalizeSoundPath(
        'assets/sounds/Alahady_07h_09h_Zozefa_be.mp3',
      ),
      'assets/sounds/alahady_07h_09h_Zozefa_be.mp3',
    );
  });
}
