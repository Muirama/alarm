class AlarmModel {
  String id;
  List<String>? days;   // lun , mar , mer
  DateTime time;        // heure
  DateTime? date;       // date fixe
  String sound;
  bool isActive;

  AlarmModel({
    required this.id,
    this.days,          // null si alarme ponctuelle
    required this.time,
    this.date,          // null si alarme récurrente
    required this.sound,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "days": days,
      "time": time.toIso8601String(),
      "date": date?.toIso8601String(),
      "sound": sound,
      "isActive": isActive,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json["id"],
      days: json["days"] != null ? List<String>.from(json["days"]) : null,
      time: DateTime.parse(json["time"]),
      date: json["date"] != null ? DateTime.parse(json["date"]) : null,
      sound: json["sound"],
      isActive: json["isActive"],
    );
  }

  bool get isOneTime => date != null;
}
