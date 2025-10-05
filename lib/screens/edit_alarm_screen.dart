import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm;
  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  final _service = AlarmService();

  late TimeOfDay _time;
  DateTime? _selectedDate;
  List<String> _selectedDays = [];
  String _selectedSound = "";
  bool _isOneTime = false;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _time = TimeOfDay.fromDateTime(widget.alarm!.time);
      _selectedDate = widget.alarm!.date;
      _selectedDays = widget.alarm!.days ?? [];
      _selectedSound = widget.alarm!.sound;
      _isOneTime = widget.alarm!.isOneTime;
    } else {
      _time = const TimeOfDay(hour: 6, minute: 0);
      _selectedSound = _service.availableSounds.first;
    }
  }

  void _saveAlarm() async {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    final newAlarm = AlarmModel(
      id: widget.alarm?.id ?? const Uuid().v4(),
      days: _isOneTime ? null : _selectedDays,
      time: alarmTime,
      date: _isOneTime ? _selectedDate : null,
      sound: _selectedSound,
      isActive: true,
    );

    if (widget.alarm == null) {
      await _service.addAlarm(newAlarm);
    } else {
      await _service.updateAlarm(newAlarm);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alarm == null ? "Nouvelle alarme" : "Modifier alarme",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text("Alarme ponctuelle (date spécifique)"),
              secondary: const Icon(Icons.event),
              value: _isOneTime,
              onChanged: (val) => setState(() => _isOneTime = val),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Heure"),
              subtitle: Text(
                "${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}",
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
          if (_isOneTime)
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Date"),
                subtitle: Text(
                  _selectedDate != null
                      ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                      : "Choisir une date",
                ),
                onTap: _pickDate,
              ),
            ),
          if (!_isOneTime)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var day in [
                      "Lundi",
                      "Mardi",
                      "Mercredi",
                      "Jeudi",
                      "Vendredi",
                      "Samedi",
                      "Dimanche",
                    ])
                      FilterChip(
                        label: Text(day),
                        selected: _selectedDays.contains(day),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _selectedDays.add(day);
                            } else {
                              _selectedDays.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _selectedSound,
                isExpanded: true,
                items:
                    _service.availableSounds.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.split("/").last,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSound = val);
                },
                decoration: const InputDecoration(
                  labelText: "Sonnerie",
                  icon: Icon(Icons.music_note),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAlarm,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer"),
            ),
          ),
        ],
      ),
    );
  }
}
