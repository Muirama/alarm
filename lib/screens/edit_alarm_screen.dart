import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm;
  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  final AlarmService alarmService = AlarmService();
  final List<String> days = [
    "Lundi",
    "Mardi",
    "Mercredi",
    "Jeudi",
    "Vendredi",
    "Samedi",
    "Dimanche",
  ];
  final Set<String> selectedDays = {};
  TimeOfDay? selectedTime;
  String? selectedSound;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      selectedDays.addAll(widget.alarm!.days);
      selectedTime = TimeOfDay.fromDateTime(widget.alarm!.time);
      selectedSound = widget.alarm!.sound;
    }
  }

  void saveAlarm() {
    if (selectedDays.isEmpty || selectedTime == null || selectedSound == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Choisir au moins un jour, une heure et un son"),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final alarm = AlarmModel(
      id: widget.alarm?.id ?? const Uuid().v4(),
      days: selectedDays.toList(),
      time: dateTime,
      sound: selectedSound!,
    );

    if (widget.alarm == null) {
      alarmService.addAlarm(alarm);
    } else {
      alarmService.updateAlarm(alarm);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvel Alarme")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children:
                  days.map((d) {
                    final selected = selectedDays.contains(d);
                    return FilterChip(
                      label: Text(d),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            selectedDays.add(d);
                          } else {
                            selectedDays.remove(d);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                    }
                  },
                  child: const Text("Choisir heure"),
                ),
                const SizedBox(width: 16),
                Text(
                  selectedTime == null
                      ? "Pas d'heure choisie"
                      : DateFormat.Hm().format(
                        DateTime(
                          0,
                          0,
                          0,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Choisir un son"),
              value: selectedSound,
              items:
                  alarmService.availableSounds.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.split("/").last,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedSound = val),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: saveAlarm,
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
