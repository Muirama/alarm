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

      _timer?.cancel();
      _timer = Timer(const Duration(minutes: 1), stopSound);
    } catch (e) {
      debugPrint("Erreur lecture: $e");
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
    final dateFormat = DateFormat('dd/MM/yyyy – HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Mes réveils"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown pour le choix du son
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
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => selectedSound = val),
            ),

            const SizedBox(height: 16),

            // Boutons play/stop
            Row(
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: selectedSound == null ? null : playSound,
                    icon: const Icon(Icons.play_arrow),
                    label: const FittedBox(child: Text("Jouer")),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: stopSound,
                    icon: const Icon(Icons.stop),
                    label: const FittedBox(child: Text("Stop")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1),

            // Liste des alarmes améliorée
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<AlarmModel> box, _) {
                  if (box.values.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucune alarme créée",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: box.values.length,
                    itemBuilder: (context, i) {
                      final alarm = box.getAt(i)!;
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              // Icône alarme stylisée
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      alarm.isActive
                                          ? Colors.blueAccent.withValues(alpha : 0.2)
                                          : Colors.grey.withValues(alpha : 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.alarm,
                                  color:
                                      alarm.isActive
                                          ? Colors.blueAccent
                                          : Colors.grey,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Infos alarme
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateFormat.format(alarm.dateTime),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color:
                                            alarm.isActive
                                                ? Colors.black
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "🔔 ${alarm.sound.split('/').last}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Switch + actions
                              Column(
                                children: [
                                  Switch(
                                    value: alarm.isActive,
                                    onChanged: (val) async {
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
                                          color: Colors.blueAccent,
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
                                          color: Colors.redAccent,
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
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add),
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
