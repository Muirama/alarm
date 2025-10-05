import 'package:flutter/material.dart';
import '../services/alarm_service.dart';
import '../models/alarm_model.dart';
import 'edit_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService alarmService = AlarmService();
  String? selectedSound;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" ")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      hint: const Text("Choisir un son"),
                      value: selectedSound,
                      items:
                          alarmService.availableSounds.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.split("/").last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (val) => setState(() => selectedSound = val),
                      decoration: const InputDecoration(
                        labelText: "Sonnerie de test",
                        icon: Icon(Icons.music_note),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              selectedSound == null
                                  ? null
                                  : () =>
                                      alarmService.playSound(selectedSound!),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Faire sonner"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => alarmService.stopSound(),
                          icon: const Icon(Icons.stop),
                          label: const Text("Arrêter"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: alarmService.alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarmService.alarms[index];
                  final timeText =
                      "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";
                  final desc =
                      alarm.isOneTime
                          ? "📅 ${alarm.date!.day}/${alarm.date!.month}/${alarm.date!.year}"
                          : "🔁 ${(alarm.days ?? []).join(", ")}";

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.alarm,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      title: Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("$desc\n${alarm.sound.split("/").last}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: alarm.isActive,
                            onChanged: (val) {
                              setState(() {
                                alarm.isActive = val;
                                alarmService.updateAlarm(alarm);
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditAlarmScreen(alarm: alarm),
                                ),
                              ).then((_) => setState(() {}));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                alarmService.removeAlarm(alarm.id);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditAlarmScreen()),
          ).then((_) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
