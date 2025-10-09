import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_repository.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm;
  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  final repo = AlarmRepository();

  late TimeOfDay _time;
  DateTime? _date;
  List<String> _days = [];
  String _sound = 'assets/sounds/angelus_6h.mp3';
  bool _isOneTime = false;

  final List<String> availableSounds = [
    'assets/sounds/angelus_6h.mp3',
    'assets/sounds/alahady_06h30_06h45.mp3',
    'assets/sounds/alahady_06h45.mp3',
    'assets/sounds/alahady_07h_09h_jmf.mp3',
    'assets/sounds/alahady_07h_09h_zozefa_be.mp3',
    'assets/sounds/ave_maria_12h.mp3',
    'assets/sounds/lakolosy_18h.mp3',
    'assets/sounds/mariazy.mp3',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      final a = widget.alarm!;
      _time = TimeOfDay(hour: a.time.hour, minute: a.time.minute);
      _date = a.date;
      _days = a.days ?? [];
      _sound = a.soundAsset;
      _isOneTime = a.isOneTime;
    } else {
      final now = DateTime.now();
      _time = TimeOfDay(hour: max(7, now.hour), minute: 0);
      _isOneTime = false;
      _sound = availableSounds.first;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    // validation minimal
    if (_isOneTime && _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez d’abord une date pour une alarme ponctuelle.',
          ),
        ),
      );
      return;
    }
    if (!_isOneTime && _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez au moins un jour pour une alarme récurrente.',
          ),
        ),
      );
      return;
    }

    // compute next DateTime occurrence
    final now = DateTime.now();
    final dt = DateTime(
      (_date ?? now).year,
      (_date ?? now).month,
      (_date ?? now).day,
      _time.hour,
      _time.minute,
    );

    final id = widget.alarm?.id ?? const Uuid().v4().hashCode;

    final model = AlarmModel(
      id: id,
      days: _isOneTime ? null : List.from(_days),
      time: dt,
      date: _isOneTime ? _date : null,
      soundAsset: _sound,
      isActive: true,
    );

    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final days = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alarm == null ? 'Nouvelle alarme' : 'Modifier alarme',
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: SwitchListTile(
              title: const Text('Alarme ponctuelle (date spécifique)'),
              value: _isOneTime,
              onChanged: (v) => setState(() => _isOneTime = v),
              activeColor: theme.colorScheme.primary,
              inactiveThumbColor: Colors.grey.shade700,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure'),
              subtitle: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_isOneTime)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  _date != null
                      ? DateFormat('dd/MM/yyyy').format(_date!)
                      : 'Choisir une date',
                ),
                onTap: _pickDate,
              ),
            ),
          if (!_isOneTime)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      days.map((d) {
                        final selected = _days.contains(d);
                        return FilterChip(
                          label: Text(d),
                          selected: selected,
                          onSelected:
                              (v) => setState(() {
                                if (v) {
                                  _days.add(d);
                                } else {
                                  _days.remove(d);
                                }
                              }),
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.2 * 255).round()),
                          checkmarkColor: theme.colorScheme.primary,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color:
                                selected
                                    ? theme.colorScheme.primary
                                    : Colors.black87,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _sound,
                decoration: const InputDecoration(
                  labelText: 'Sonnerie',
                  border: OutlineInputBorder(),
                ),
                items:
                    availableSounds
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.split('/').last),
                          ),
                        )
                        .toList(),
                onChanged:
                    (v) => setState(() => _sound = v ?? availableSounds.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
