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
}
