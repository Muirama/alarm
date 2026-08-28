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
  late TimeOfDay _time;
  DateTime? _selectedDate;
  List<String> _selectedDays = [];
  late String _selectedSound;
  late bool _isOneTime;

  static const _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    if (alarm != null) {
      _time = TimeOfDay.fromDateTime(alarm.time);
      _selectedDate = alarm.date;
      _selectedDays = List<String>.from(alarm.days ?? []);
      _selectedSound = alarm.sound;
      _isOneTime = alarm.isOneTime;
    } else {
      _time = const TimeOfDay(hour: 6, minute: 0);
      _selectedSound = AlarmService.availableSounds.first;
      _selectedDays = [];
      _isOneTime = false;
    }
  }

  // ─── Validation & sauvegarde ───────────────
  Future<void> _saveAlarm() async {
    final error = _validate();
    if (error != null) {
      _showError(error);
      return;
    }

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
      days: _isOneTime ? null : List<String>.from(_selectedDays),
      time: alarmTime,
      date: _isOneTime ? _selectedDate : null,
      sound: _selectedSound,
      isActive: widget.alarm?.isActive ?? true,
    );

    final service = AlarmService();
    if (widget.alarm == null) {
      await service.addAlarm(newAlarm);
    } else {
      await service.updateAlarm(newAlarm);
    }

    if (mounted) Navigator.pop(context);
  }

  String? _validate() {
    if (_isOneTime && _selectedDate == null) {
      return 'Veuillez choisir une date pour l\'alarme ponctuelle';
    }
    if (!_isOneTime && _selectedDays.isEmpty) {
      return 'Veuillez sélectionner au moins un jour';
    }
    if (_isOneTime && _selectedDate != null) {
      final alarmDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _time.hour,
        _time.minute,
      );
      if (alarmDateTime.isBefore(DateTime.now())) {
        return 'La date et l\'heure doivent être dans le futur';
      }
    }
    return null;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('⚠️ Attention'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
          _buildOneTimeSwitch(theme),
          const SizedBox(height: 12),
          _buildTimePicker(),
          const SizedBox(height: 12),
          if (_isOneTime) _buildDatePicker(),
          if (!_isOneTime) _buildDaySelector(theme),
          const SizedBox(height: 16),
          _buildSoundSelector(),
          const SizedBox(height: 24),
          _buildSaveButton(theme),
        ],
      ),
    );
  }

  // ─── Widgets internes ──────────────────────
  Widget _buildOneTimeSwitch(ThemeData theme) => _card(
    child: SwitchListTile(
      title: const Text(
        'Alarme ponctuelle (date spécifique)',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      secondary: const Icon(Icons.event),
      value: _isOneTime,
      onChanged:
          (val) => setState(() {
            _isOneTime = val;
            if (val) {
              _selectedDays = [];
            } else {
              _selectedDate = null;
            }
          }),
      activeThumbColor: theme.colorScheme.primary,
      inactiveThumbColor: Colors.grey.shade600,
      inactiveTrackColor: Colors.grey.shade300,
    ),
  );

  Widget _buildTimePicker() => _card(
    child: ListTile(
      leading: const Icon(Icons.access_time),
      title: const Text('Heure'),
      subtitle: Text(
        '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _time,
        );
        if (picked != null) setState(() => _time = picked);
      },
    ),
  );

  Widget _buildDatePicker() => _card(
    borderColor: _selectedDate == null ? Colors.red : null,
    child: ListTile(
      leading: Icon(
        Icons.calendar_today,
        color: _selectedDate == null ? Colors.red : null,
      ),
      title: Text(
        'Date${_selectedDate == null ? ' (obligatoire)' : ''}',
        style: TextStyle(color: _selectedDate == null ? Colors.red : null),
      ),
      subtitle: Text(
        _selectedDate != null
            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
            : 'Choisir une date',
        style: TextStyle(color: _selectedDate == null ? Colors.red[300] : null),
      ),
      onTap: _pickDate,
    ),
  );

  Widget _buildDaySelector(ThemeData theme) => _card(
    borderColor: _selectedDays.isEmpty ? Colors.red : null,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jours de répétition'
            '${_selectedDays.isEmpty ? ' (obligatoire)' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _selectedDays.isEmpty ? Colors.red : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _weekdays.map((day) {
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: selected,
                    selectedColor: theme.colorScheme.primary.withAlpha(
                      (0.2 * 255).round(),
                    ),
                    checkmarkColor: theme.colorScheme.primary,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color:
                          selected ? theme.colorScheme.primary : Colors.black87,
                    ),
                    onSelected:
                        (sel) => setState(() {
                          sel
                              ? _selectedDays.add(day)
                              : _selectedDays.remove(day);
                        }),
                  );
                }).toList(),
          ),
        ],
      ),
    ),
  );

  Widget _buildSoundSelector() => _card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSound,
        isExpanded: true,
        items:
            AlarmService.availableSounds.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.split('/').last, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedSound = val);
        },
        decoration: const InputDecoration(
          labelText: 'Sonnerie',
          prefixIcon: Icon(Icons.music_note),
          border: OutlineInputBorder(),
        ),
      ),
    ),
  );

  Widget _buildSaveButton(ThemeData theme) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _saveAlarm,
      icon: const Icon(Icons.save),
      label: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
      ),
    ),
  );

  /// Helper : Card avec bordure optionnelle.
  Widget _card({required Widget child, Color? borderColor}) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side:
          borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : BorderSide.none,
    ),
    elevation: 3,
    child: child,
  );
}
