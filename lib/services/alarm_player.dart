// ignore_for_file: avoid_print

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Gère la lecture audio des sonneries d'alarme.
/// Indépendant du scheduler — peut être utilisé depuis n'importe quel isolat.
class AlarmPlayer {
  static final AlarmPlayer _instance = AlarmPlayer._internal();
  factory AlarmPlayer() => _instance;

  AlarmPlayer._internal() {
    _player.onPlayerComplete.listen((_) {
      _stopCleanup();
      _log('Son terminé naturellement');
    });
  }

  final AudioPlayer _player = AudioPlayer();
  Timer? _autoStopTimer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  static const Duration autoStopDuration = Duration(minutes: 2);

  // ─── Lecture ───────────────────────────────
  Future<void> play(String assetPath) async {
    if (_isPlaying) {
      _log('Déjà en lecture, ignoré');
      return;
    }

    _isPlaying = true;

    try {
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);

      // audioplayers attend le chemin sans le préfixe "assets/"
      final cleaned = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;

      _log('▶️ Lecture: $cleaned');
      await _player.play(AssetSource(cleaned));

      // Arrêt automatique
      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(autoStopDuration, () {
        _log('⏱️ Arrêt automatique (${autoStopDuration.inMinutes} min)');
        stop();
      });
    } catch (e, st) {
      _log('❌ Erreur lecture: $e\n$st');
      _stopCleanup();
    }
  }

  // ─── Arrêt ─────────────────────────────────
  Future<void> stop() async {
    try {
      await _player.stop();
      _log('⏹️ Son arrêté');
    } catch (e) {
      _log('Erreur arrêt: $e');
    } finally {
      _stopCleanup();
    }
  }

  void _stopCleanup() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isPlaying = false;
  }

  void _log(String msg) => print('[AlarmPlayer] $msg');
}