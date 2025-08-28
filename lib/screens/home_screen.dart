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
      appBar: AppBar(title: const Text("Réveil")),
      body: Column(
        children: [
          DropdownButton<String>(
            hint: const Text("Choisir un son"),
            value: selectedSound,
            items:
                alarmService.availableSounds.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.split("/").last),
                  );
                }).toList(),
            onChanged: (val) => setState(() => selectedSound = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                    selectedSound == null
                        ? null
                        : () => alarmService.playSound(selectedSound!),
                child: const Text("Faire sonner"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => alarmService.stopSound(),
                child: const Text("Arrêter"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: alarmService.alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarmService.alarms[index];
                return ListTile(
                  title: Text(
                    "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')} - ${alarm.days.join(", ")}",
                  ),
                  subtitle: Text(alarm.sound.split("/").last),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alarm.isActive,
                        onChanged: (val) {
                          setState(() {
                            alarm.isActive = val;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
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
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            alarmService.removeAlarm(alarm.id);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
