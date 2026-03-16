import 'package:flutter/material.dart';
import '../../models/alarm_model.dart';

/// Tuile affichée dans la liste des alarmes.
class AlarmListTile extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmListTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = alarm.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.alarm,
          color: isActive ? theme.colorScheme.primary : Colors.grey,
          size: 32,
        ),
        title: Text(
          alarm.formattedTime,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey[500],
          ),
        ),
        subtitle: Text(
          '${alarm.displayDescription}\n${alarm.soundLabel}',
          style: TextStyle(
            color: isActive ? Colors.black54 : Colors.grey[400],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isActive,
              onChanged: onToggle,
              activeColor: theme.colorScheme.primary,
              inactiveThumbColor: Colors.grey.shade600,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}