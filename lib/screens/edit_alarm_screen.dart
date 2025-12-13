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
    // ✅ Validation 1: Vérifier le son
    if (_selectedSound.isEmpty) {
      _showError("Veuillez choisir une sonnerie");
      return;
    }

    // ✅ Validation 2: Si alarme ponctuelle, vérifier la date
    if (_isOneTime && _selectedDate == null) {
      _showError("Veuillez choisir une date pour l'alarme ponctuelle");
      return;
    }

    // ✅ Validation 3: Si alarme récurrente, vérifier les jours
    if (!_isOneTime && _selectedDays.isEmpty) {
      _showError("Veuillez sélectionner au moins un jour");
      return;
    }

    // ✅ Validation 4: Si alarme ponctuelle, vérifier que la date/heure est future
    if (_isOneTime && _selectedDate != null) {
      final alarmDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _time.hour,
        _time.minute,
      );
      
      if (alarmDateTime.isBefore(DateTime.now())) {
        _showError("La date et l'heure doivent être dans le futur");
        return;
      }
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

  // ✅ Méthode pour afficher les erreurs
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Attention"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alarm == null ? "Nouvelle alarme" : "Modifier alarme",
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔁 Alarme ponctuelle ou récurrente
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: SwitchListTile(
              title: const Text(
                "Alarme ponctuelle (date spécifique)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              secondary: const Icon(Icons.event),
              value: _isOneTime,
              onChanged: (val) => setState(() {
                _isOneTime = val;
                // ✅ Réinitialiser les sélections lors du changement de mode
                if (val) {
                  _selectedDays = [];
                } else {
                  _selectedDate = null;
                }
              }),
              activeColor: theme.colorScheme.primary,
              inactiveThumbColor: Colors.grey.shade600,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 12),

          // 🕐 Sélecteur d'heure
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
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
          const SizedBox(height: 12),

          // 📅 Sélecteur de date si alarme ponctuelle
          if (_isOneTime)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                // ✅ Bordure rouge si date non choisie
                side: _selectedDate == null 
                    ? const BorderSide(color: Colors.red, width: 1)
                    : BorderSide.none,
              ),
              elevation: 3,
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: _selectedDate == null ? Colors.red : null,
                ),
                title: Text(
                  "Date ${_selectedDate == null ? '(obligatoire)' : ''}",
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.red : null,
                  ),
                ),
                subtitle: Text(
                  _selectedDate != null
                      ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                      : "Choisir une date",
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.red[300] : null,
                  ),
                ),
                onTap: _pickDate,
              ),
            ),

          // 🔁 Sélecteur de jours si récurrente
          if (!_isOneTime)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                // ✅ Bordure rouge si aucun jour choisi
                side: _selectedDays.isEmpty
                    ? const BorderSide(color: Colors.red, width: 1)
                    : BorderSide.none,
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jours de répétition ${_selectedDays.isEmpty ? '(obligatoire)' : ''}",
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
                            selectedColor: theme.colorScheme.primary.withAlpha(
                              (0.2 * 255).round(),
                            ),
                            checkmarkColor: theme.colorScheme.primary,
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color:
                                  _selectedDays.contains(day)
                                      ? theme.colorScheme.primary
                                      : Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 🎵 Sélecteur de son
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButtonFormField<String>(
                value: _selectedSound.isEmpty ? null : _selectedSound,
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
                  labelText: "Sonnerie (obligatoire)",
                  prefixIcon: Icon(Icons.music_note),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 💾 Bouton Enregistrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAlarm,
              icon: const Icon(Icons.save),
              label: const Text("Enregistrer", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: theme.colorScheme.primary,
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
