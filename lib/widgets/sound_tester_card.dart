import 'package:flutter/material.dart';
import '../../services/alarm_service.dart';

/// Widget de test de son — affiché en haut du HomeScreen.
class SoundTesterCard extends StatefulWidget {
  const SoundTesterCard({super.key});

  @override
  State<SoundTesterCard> createState() => _SoundTesterCardState();
}

class _SoundTesterCardState extends State<SoundTesterCard> {
  final _service = AlarmService();
  String? _selectedSound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tester un son',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              hint: const Text('Choisir un son'),
              initialValue: _selectedSound,
              items:
                  AlarmService.availableSounds.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (val) => setState(() => _selectedSound = val),
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
                      _selectedSound == null
                          ? null
                          : () => _service.playSound(_selectedSound!),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Écouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _service.stopSound(),
                  icon: const Icon(Icons.stop),
                  label: const Text('Arrêter'),
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
    );
  }
}
