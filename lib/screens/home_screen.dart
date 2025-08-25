import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';
import 'alarm_edit_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _player = AudioPlayer();
  String? selectedSound;
  Timer? _timer;

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

  Future<void> playSound() async {
    if (selectedSound == null) return;
    try {
      await _player.setAsset(selectedSound!);
      await _player.play();

      // auto-stop après 1 minute max
      _timer?.cancel();
      _timer = Timer(const Duration(minutes: 1), stopSound);
    } catch (e) {
      print("Erreur lecture: $e");
    }
  }

  Future<void> stopSound() async {
    await _player.stop();
    _timer?.cancel();
  }

  @override
  void dispose() {
    _player.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<AlarmModel>('alarms');
    final timeFormat = DateFormat('HH:mm'); // seulement l'heure
    final dateFormat = DateFormat('dd/MM/yyyy'); // seulement la date

    return Scaffold(
      appBar: AppBar(
        title: const Text("⏰ Mes Réveils"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Choix son ===
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Choisir un son 🔔",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              isExpanded: true,
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

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedSound == null ? null : playSound,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Jouer"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: stopSound,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1.2),

            // === Liste des alarmes créées ===
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<AlarmModel> box, _) {
                  if (box.values.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucune alarme créée 😴",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: box.values.length,
                    itemBuilder: (context, i) {
                      final alarm = box.getAt(i)!;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeFormat.format(alarm.dateTime),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(alarm.dateTime),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "Son : ${alarm.sound.split('/').last}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Switch(
                                    value: alarm.isActive,
                                    onChanged: (val) {
                                      setState(() {
                                        alarm.isActive = val;
                                        alarm.save();
                                      });
                                    },
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => AlarmEditScreen(
                                                    initial: alarm,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => box.deleteAt(i),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // === Bouton pour ajouter une alarme ===
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Nouvelle alarme"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
          );
        },
      ),
    );
  }
}
