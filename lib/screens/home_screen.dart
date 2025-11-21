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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Réveil Catholique"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Section Son de Test
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tester un son",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          label: const Text("Écouter"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => alarmService.stopSound(),
                          icon: const Icon(Icons.stop),
                          label: const Text("Arrêter"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Liste des alarmes
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(
                        Icons.alarm,
                        color:
                            alarm.isActive
                                ? theme.colorScheme.primary
                                : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              alarm.isActive ? Colors.black : Colors.grey[500],
                        ),
                      ),
                      subtitle: Text(
                        "$desc\n${alarm.sound.split("/").last}",
                        style: TextStyle(
                          color:
                              alarm.isActive
                                  ? Colors.black54
                                  : Colors.grey[400],
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ Switch plus visible quand désactivé
                          Switch(
                            value: alarm.isActive,
                            onChanged: (val) async {
                              setState(() {
                                alarm.isActive = val;
                              });
                              await alarmService.updateAlarm(alarm);
                            },
                            activeColor: theme.colorScheme.primary,
                            inactiveThumbColor: Colors.grey.shade600,
                            inactiveTrackColor: Colors.grey.shade300,
                          ),

                          // 🟧 Bouton édition
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

                          // 🗑️ Bouton suppression manuelle
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text(
                                        "Supprimer cette alarme ?",
                                      ),
                                      content: const Text(
                                        "Cette action est irréversible.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("Annuler"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            "Supprimer",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                setState(() {
                                  alarmService.removeAlarm(alarm.id);
                                });
                              }
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
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }
}
