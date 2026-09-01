import 'package:flutter/services.dart';

/// Accès aux réglages d'optimisation de batterie Android.
///
/// Même si l'alarme est planifiée avec `alarmClock: true` (exempté de Doze
/// en théorie), de nombreux constructeurs (Xiaomi, Oppo, Vivo, Tecno,
/// Infinix, Itel...) tuent le processus en arrière-plan avant que le son
/// ne puisse jouer, sauf si l'app est explicitement exclue de l'optimisation
/// de batterie et autorisée à démarrer automatiquement.
class BatteryOptimization {
  BatteryOptimization._();

  // Même canal que ExactAlarmPermission : géré par le même MainActivity.
  static const _channel = MethodChannel('alarm_fiangonana/exact_alarm');

  static Future<bool> isIgnoringBatteryOptimizations() async =>
      await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
      false;

  static Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');

  /// Best-effort : ouvre l'écran "Démarrage automatique" du constructeur
  /// si un écran connu existe, sinon la page de détails de l'app.
  static Future<void> openAutostartSettings() =>
      _channel.invokeMethod<void>('openAutostartSettings');
}