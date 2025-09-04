class AlarmModel {
  String id;
  List<String> days; // ["Lundi", "Mardi", ...]
  DateTime time;
  String sound;
  bool isActive;

  AlarmModel({
    required this.id,
    required this.days,
    required this.time,
    required this.sound,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "days": days,
      "time": time.toIso8601String(),
      "sound": sound,
      "isActive": isActive,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json["id"],
      days: List<String>.from(json["days"]),
      time: DateTime.parse(json["time"]),
      sound: json["sound"],
      isActive: json["isActive"],
    );
  }
}
