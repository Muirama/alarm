import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_repository.dart';
import 'edit_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = AlarmRepository();

  @override
  void initState() {
    super.initState();
    // already initialized in main; just refresh UI
    setState(() {});
  }

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alarms = repo.alarms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réveil Catholique'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // header card: gestion rapide du son (optionnel)
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Sons disponibles'),
                subtitle: Text('Choisir son dans l’écran d’édition'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: alarms.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune alarme. Appuie sur + pour en ajouter.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: alarms.length,
                      itemBuilder: (context, i) {
                        final a = alarms[i];
                        final desc = a.isOneTime
                            ? '📅 ${a.date!.day}/${a.date!.month}/${a.date!.year}'
                            : '🔁 ${(a.days ?? []).join(", ")}';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            leading: Icon(
                              Icons.alarm,
                              color: a.isActive
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                              size: 36,
                            ),
                            title: Text(
                              _formatTime(a.time),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: a.isActive ? Colors.black : Colors.grey[500],
                              ),
                            ),
                            subtitle: Text(
                              '$desc\n${a.soundAsset.split("/").last}',
                              style: TextStyle(
                                  color: a.isActive ? Colors.black54 : Colors.grey[400]),
                              maxLines: 2,
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Switch visible when inactive (contrasted colors)
                                Switch(
                                  value: a.isActive,
                                  onChanged: (val) async {
                                    await repo.toggleActive(a.id, val);
                                    setState(() {});
                                  },
                                  activeColor: theme.colorScheme.primary,
                                  inactiveThumbColor: Colors.grey.shade700,
                                  inactiveTrackColor: Colors.grey.shade300,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () async {
                                    final res = await Navigator.push<AlarmModel?>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditAlarmScreen(alarm: a),
                                      ),
                                    );
                                    if (res != null) {
                                      // update returned model
                                      await repo.updateAlarm(res);
                                      setState(() {});
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Supprimer cette alarme ?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(c, false),
                                              child: const Text('Annuler')),
                                          TextButton(
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text(
                                                'Supprimer',
                                                style: TextStyle(color: Colors.red),
                                              )),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await repo.deleteAlarm(a.id);
                                      setState(() {});
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newAlarm = await Navigator.push<AlarmModel?>(
            context,
            MaterialPageRoute(builder: (_) => const EditAlarmScreen()),
          );
          if (newAlarm != null) {
            await repo.createAlarm(newAlarm);
            setState(() {});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle alarme'),
      ),
    );
  }
}
