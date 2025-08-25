import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_ce/hive.dart';
import '../models/alarm_model.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../services/alarm_service.dart';
import 'home_screen.dart';

class AlarmEditScreen extends StatefulWidget {
  final AlarmModel? initial;

  const AlarmEditScreen({super.key, this.initial});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  DateTime? selectedDateTime;
  String? selectedSound;
  bool _isActive = true;

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
      _isActive = widget.initial!.isActive;
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

  Future<void> saveAlarm() async {
    if (selectedDateTime == null || selectedSound == null) return;

    if (selectedDateTime!.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La date doit être dans le futur ⏳")),
      );
      return;
    }

    final box = Hive.box<AlarmModel>('alarms');

    AlarmModel alarm;
    if (widget.initial == null) {
      alarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch,
        dateTime: selectedDateTime!,
        sound: selectedSound!,
        isActive: _isActive,
      );
      await box.add(alarm);
    } else {
      alarm = widget.initial!;
      alarm.dateTime = selectedDateTime!;
      alarm.sound = selectedSound!;
      alarm.isActive = _isActive;
      await alarm.save();
    }

    // Afficher SnackBar immédiatement selon le statut
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isActive
              ? "Alarme activée et sauvegardée 🎉"
              : "Alarme sauvegardée mais désactivée ⚠️",
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Planifier l’alarme en arrière-plan sans bloquer l’UI
    if (_isActive) {
      final now = DateTime.now();
      final alarmTime = selectedDateTime!;
      final duration = alarmTime.difference(now);
      if (!duration.isNegative) {
        // Ne pas await ici pour ne pas bloquer l'affichage du SnackBar
        AndroidAlarmManager.oneShot(
          duration,
          alarm.id,
          alarmCallback,
          exact: true,
          wakeup: true,
        );
      }
    }

    // Attendre la durée du SnackBar avant navigation
    await Future.delayed(const Duration(seconds: 2));

    // Retour à HomeScreen
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? "Nouvelle alarme" : "Modifier alarme",
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickDateTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedDateTime == null
                    ? "Choisir date & heure"
                    : DateFormat("dd/MM/yyyy HH:mm").format(selectedDateTime!),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedSound,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Choisir un son 🔔",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items:
                  sounds.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.split("/").last,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedSound = val),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Activer l'alarme"),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed:
                  (selectedDateTime != null && selectedSound != null)
                      ? saveAlarm
                      : null,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
