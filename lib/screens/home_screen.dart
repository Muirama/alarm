import 'package:flutter/material.dart';
import '../services/alarm_service.dart';
import '../services/exact_alarm_permission.dart';
import '../models/alarm_model.dart';
import '../widgets/alarm_list_tile.dart';
import '../widgets/sound_tester_card.dart';
import 'edit_alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AlarmService _service = AlarmService();
  bool _canScheduleExactAlarms = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshExactAlarmPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshExactAlarmPermission();
  }

  Future<void> _refreshExactAlarmPermission() async {
    try {
      final allowed = await ExactAlarmPermission.canSchedule();
      if (!mounted) return;

      final wasDenied = !_canScheduleExactAlarms;
      setState(() => _canScheduleExactAlarms = allowed);
      if (allowed && wasDenied) await _service.rescheduleActiveAlarms();
    } catch (_) {
      // L'interface reste utilisable ; le scheduler signalera toute erreur.
    }
  }

  Future<void> _requestExactAlarmPermission() =>
      ExactAlarmPermission.openSettings();

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
      builder:
          (ctx) => AlertDialog(
            title: const Text('Supprimer cette alarme ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (!_canScheduleExactAlarms) ...[
              _buildExactAlarmWarning(),
              const SizedBox(height: 12),
            ],
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

  Widget _buildExactAlarmWarning() => Card(
    color: Colors.amber.shade50,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Autorisation requise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Autorisez les alarmes et rappels pour que les réveils sonnent '
            'à l\'heure, même lorsque l\'écran est verrouillé.',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _requestExactAlarmPermission,
              child: const Text('Ouvrir les paramètres'),
            ),
          ),
        ],
      ),
    ),
  );

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
