import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_ce/hive.dart';
import 'package:just_audio/just_audio.dart';
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
  bool _isActive = true;
  final AudioPlayer _player = AudioPlayer();

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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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

  Future<void> playSound() async {
    if (selectedSound == null) return;
    try {
      await _player.setAsset(selectedSound!);
      await _player.play();
    } catch (e) {
      print("Erreur lecture: $e");
    }
  }

  Future<void> stopSound() async {
    await _player.stop();
  }

  void saveAlarm() {
    if (selectedDateTime == null || selectedSound == null) return;

    if (selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La date doit être dans le futur ⏳")),
      );
      return;
    }

    final box = Hive.box<AlarmModel>('alarms');

    if (widget.initial == null) {
      final alarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch,
        dateTime: selectedDateTime!,
        sound: selectedSound!,
        isActive: _isActive,
      );
      box.add(alarm);
    } else {
      widget.initial!.dateTime = selectedDateTime!;
      widget.initial!.sound = selectedSound!;
      widget.initial!.isActive = _isActive;
      widget.initial!.save();
    }

    Navigator.pop(context);
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
            // Carte date & heure
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: Text(
                  selectedDateTime == null
                      ? "Choisir date & heure"
                      : DateFormat(
                        "dd/MM/yyyy HH:mm",
                      ).format(selectedDateTime!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                  onPressed: pickDateTime,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Carte choix du son + pré-écoute
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choisir un son 🔔",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
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
                    if (selectedSound != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.green,
                            ),
                            onPressed: playSound,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.red),
                            onPressed: stopSound,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Switch activer / désactiver
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: SwitchListTile(
                title: const Text("Activer l'alarme"),
                secondary: const Icon(Icons.alarm, color: Colors.green),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
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
                minimumSize: const Size(double.infinity, 55),
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
