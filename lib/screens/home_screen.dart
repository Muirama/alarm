import 'package:flutter/material.dart';
import '../services/alarm_service.dart';
import '../models/alarm_model.dart';
import '../widgets/alarm_list_tile.dart';
import '../widgets/sound_tester_card.dart';
import 'edit_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AlarmService _service = AlarmService();

  // ─── Navigation ────────────────────────────
  Future<void> _openEditScreen([AlarmModel? alarm]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditAlarmScreen(alarm: alarm)),
    );
    if (mounted) setState(() {});
  }

  // ─── Suppression avec confirmation ─────────
  Future<void> _confirmDelete(AlarmModel alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette alarme ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _service.removeAlarm(alarm.id);
      setState(() {});
    }
  }

  // ─── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réveil Catholique'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SoundTesterCard(),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(child: _buildAlarmList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditScreen(),
        elevation: 6,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlarmList() {
    if (_service.alarms.isEmpty) {
      return const Center(
        child: Text(
          'Aucune alarme.\nAppuyez sur + pour en créer une.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _service.alarms.length,
      itemBuilder: (_, index) {
        final alarm = _service.alarms[index];
        return AlarmListTile(
          alarm: alarm,
          onToggle: (val) async {
            setState(() => alarm.isActive = val);
            await _service.updateAlarm(alarm);
          },
          onEdit: () => _openEditScreen(alarm),
          onDelete: () => _confirmDelete(alarm),
        );
      },
    );
  }
}