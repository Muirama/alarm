import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

/// Persistance des alarmes via SharedPreferences.
class AlarmStorage {
  AlarmStorage._(); // non instanciable

  static const String _key = 'alarms';

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    // 🔑 Essentiel : l'isolat d'arrière-plan de android_alarm_manager_plus
    // est réutilisé entre plusieurs déclenchements et garde en mémoire un
    // instantané périmé des préférences. reload() force une relecture
    // depuis le disque pour voir les alarmes créées/modifiées depuis l'UI.
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((entry) {
            try {
              return AlarmModel.fromJson(Map<String, dynamic>.from(entry));
            } on FormatException {
              return null;
            } on TypeError {
              return null;
            }
          })
          .whereType<AlarmModel>()
          .toList();
    } on FormatException {
      return [];
    }
  }
}