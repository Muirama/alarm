import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class AlarmStorage {
  static const String key = "alarms";

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((a) => a.toJson()).toList();
    await prefs.setString(key, jsonEncode(alarmsJson));
  }

  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((data) => AlarmModel.fromJson(data)).toList();
  }
}
