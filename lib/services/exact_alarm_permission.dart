import 'package:flutter/services.dart';

/// Accès à l'autorisation spéciale requise pour les alarmes exactes Android.
///
/// Android 12+ laisse l'utilisateur désactiver cet accès dans les paramètres
/// système. Cette classe ne demande jamais une permission classique : elle
/// ouvre l'écran système dédié.
class ExactAlarmPermission {
  ExactAlarmPermission._();

  static const _channel = MethodChannel('alarm_fiangonana/exact_alarm');

  static Future<bool> canSchedule() async =>
      await _channel.invokeMethod<bool>('canSchedule') ?? false;

  static Future<void> openSettings() =>
      _channel.invokeMethod<void>('openSettings');
}
