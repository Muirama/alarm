/// Représente une alarme (ponctuelle ou récurrente).
class AlarmModel {
  final String id; // UUID string
  final List<String>? days; // ["Lundi", "Mardi", ...] — null si ponctuelle
  final DateTime time; // heure de l'alarme
  final DateTime? date; // date fixe — null si récurrente
  final String sound; // chemin asset
  bool isActive;

  AlarmModel({
    required this.id,
    this.days,
    required this.time,
    this.date,
    required this.sound,
    this.isActive = true,
  });

  // ─────────────────────────────────────────────
  // 🔑 ID entier STABLE pour AndroidAlarmManager
  // On utilise les 9 premiers chiffres du hashCode absolu.
  // Stable dans le même process ; suffisant pour Android alarm IDs.
  // ─────────────────────────────────────────────
  int get androidAlarmId {
    // Fold chaque code-unit pour réduire les collisions
    int hash = 0;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF; // rester positif 31-bit
    }
    return hash;
  }

  // ─── Helpers ───────────────────────────────
  bool get isOneTime => date != null;
  bool get isRecurring => days != null && days!.isNotEmpty;

  String get formattedTime =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String get formattedDate => date != null
      ? '${date!.day.toString().padLeft(2, '0')}/'
        '${date!.month.toString().padLeft(2, '0')}/'
        '${date!.year}'
      : '';

  String get soundLabel => sound.split('/').last;

  /// Retourne la description courte affichée dans la liste.
  String get displayDescription {
    if (isOneTime) return '📅 $formattedDate';
    return '🔁 ${(days ?? []).join(", ")}';
  }

  // ─── Sérialisation ─────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'days': days,
        'time': time.toIso8601String(),
        'date': date?.toIso8601String(),
        'sound': sound,
        'isActive': isActive,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'] as String,
        days: json['days'] != null
            ? List<String>.from(json['days'] as List)
            : null,
        time: DateTime.parse(json['time'] as String),
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : null,
        sound: json['sound'] as String,
        isActive: json['isActive'] as bool,
      );

  AlarmModel copyWith({
    String? id,
    List<String>? days,
    DateTime? time,
    DateTime? date,
    String? sound,
    bool? isActive,
    bool clearDate = false,
    bool clearDays = false,
  }) =>
      AlarmModel(
        id: id ?? this.id,
        days: clearDays ? null : (days ?? this.days),
        time: time ?? this.time,
        date: clearDate ? null : (date ?? this.date),
        sound: sound ?? this.sound,
        isActive: isActive ?? this.isActive,
      );
}