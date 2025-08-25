import 'package:hive_ce/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime dateTime;

  @HiveField(2)
  String sound;

  @HiveField(3)
  bool isActive;

  AlarmModel({
    required this.id,
    required this.dateTime,
    required this.sound,
    this.isActive = true,
  });
}
