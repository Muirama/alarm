import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';

class AlarmEditScreen extends StatefulWidget {
  final AlarmModel? initial;

  const AlarmEditScreen({super.key, this.initial});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  DateTime? selectedDateTime;
  String? selectedSound;

  final List<String> sounds = [
    "assets/sounds/lakolosy_6h00.mp3",
    "assets/sounds/lakolosy_6h45.mp3",
    "assets/sounds/lakolosy_12h.mp3",
    "assets/sounds/lakolosy_anjely_gabriely_Angelus_6h.mp3",
    "assets/sounds/lakolosy_anjely_gabriely_maria.mp3",
    "assets/sounds/lakolosy_Ave_Maria12h.mp3",
    "assets/sounds/lakolosy_jozefa_be_voninahitra_06h30.mp3",
    "assets/sounds/lakolosy_jozefa_mpitaiza_07h.mp3",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      selectedDateTime = widget.initial!.dateTime;
      selectedSound = widget.initial!.sound;
    }
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          selectedDateTime != null
              ? TimeOfDay.fromDateTime(selectedDateTime!)
              : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void saveAlarm() {
    if (selectedDateTime == null || selectedSound == null) return;

    final alarm = AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch,
      dateTime: selectedDateTime!,
      sound: selectedSound!,
    );

    Navigator.pop(context, alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? "Nouvelle alarme" : "Modifier alarme",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date & heure
            ElevatedButton.icon(
              onPressed: pickDateTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedDateTime == null
                    ? "Choisir date & heure"
                    : DateFormat("dd/MM/yyyy HH:mm").format(selectedDateTime!),
              ),
            ),
            const SizedBox(height: 20),

            // Choix du son
            DropdownButton<String>(
              hint: const Text("Choisir un son 🔔"),
              value: selectedSound,
              items:
                  sounds.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.split("/").last),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedSound = val),
            ),
            const Spacer(),

            // Bouton enregistrer
            ElevatedButton.icon(
              onPressed:
                  (selectedDateTime != null && selectedSound != null)
                      ? saveAlarm
                      : null,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
