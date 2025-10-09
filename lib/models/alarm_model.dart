import 'dart:convert';

class AlarmModel {
  final int id;
  final List<String>? days; // ["Lundi","Mardi",...] null => one-time
  final DateTime time; // date-time for the next scheduled occurrence
  final DateTime? date; // if one-time: the exact date; if recurring: null
  final String soundAsset; // path to asset e.g. assets/sounds/alarm_default.mp3
  bool isActive;

  AlarmModel({
    required this.id,
    this.days,
    required this.time,
    this.date,
    required this.soundAsset,
    this.isActive = true,
  });

  bool get isOneTime => date != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'days': days,
    'time': time.toIso8601String(),
    'date': date?.toIso8601String(),
    'soundAsset': soundAsset,
    'isActive': isActive,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      days: json['days'] != null ? List<String>.from(json['days']) : null,
      time: DateTime.parse(json['time']),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      soundAsset: json['soundAsset'],
      isActive: json['isActive'] ?? true,
    );
  }

  static List<AlarmModel> listFromJson(String jsonString) {
    final decoded = json.decode(jsonString) as List<dynamic>;
    return decoded.map((e) => AlarmModel.fromJson(e)).toList();
  }

  static String listToJson(List<AlarmModel> list) =>
      json.encode(list.map((e) => e.toJson()).toList());
}
