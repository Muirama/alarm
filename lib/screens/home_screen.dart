import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/alarm_model.dart';
import 'alarm_edit_screen.dart';
import 'dart:async';

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

  List<AlarmModel> alarms = []; // liste des alarmes créées

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
    return Scaffold(
      appBar: AppBar(title: const Text("Mes réveils")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Choix son + test ===
            SizedBox(
              width: double.infinity, // prend toute la largeur disponible
              child: DropdownButton<String>(
                isExpanded: true, // très important !
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
            ),

            const SizedBox(height: 20),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: selectedSound == null ? null : playSound,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Jouer"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: stopSound,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),

            const Divider(height: 40),

            // === Liste des alarmes créées ===
            Expanded(
              child:
                  alarms.isEmpty
                      ? const Center(child: Text("Aucune alarme créée"))
                      : ListView.builder(
                        itemCount: alarms.length,
                        itemBuilder: (context, i) {
                          final alarm = alarms[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.alarm),
                              title: Text(
                                "⏰ ${alarm.dateTime.hour.toString().padLeft(2, '0')}:${alarm.dateTime.minute.toString().padLeft(2, '0')} "
                                "- ${alarm.dateTime.day}/${alarm.dateTime.month}",
                              ),
                              subtitle: Text(
                                "Son: ${alarm.sound.split('/').last}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // bouton modifier
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      final updatedAlarm = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AlarmEditScreen(
                                                initial: alarm,
                                              ),
                                        ),
                                      );

                                      if (updatedAlarm != null &&
                                          updatedAlarm is AlarmModel) {
                                        setState(() {
                                          alarms[i] = updatedAlarm;
                                        });
                                      }
                                    },
                                  ),
                                  // bouton supprimer
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        alarms.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),

      // === Bouton pour ajouter une alarme ===
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newAlarm = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
          );

          if (newAlarm != null && newAlarm is AlarmModel) {
            setState(() {
              alarms.add(newAlarm);
            });
          }
        },
      ),
    );
  }
}
