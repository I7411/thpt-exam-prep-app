import 'dart:convert';

enum ReminderRepeatType {
  once,
  daily,
  selectedWeekdays;

  String toValue() => name;

  static ReminderRepeatType fromValue(String value) {
    return ReminderRepeatType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReminderRepeatType.once,
    );
  }
}

class StudyReminder {
  final int id;
  final String? userId;
  final String title;
  final String? description;
  final int hour;
  final int minute;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday
  final String ringtoneAsset;
  final String? androidSoundResource;
  final bool vibrationEnabled;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyReminder({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.ringtoneAsset,
    this.androidSoundResource,
    required this.vibrationEnabled,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  ReminderRepeatType get repeatType {
    if (weekdays.isEmpty) {
      return ReminderRepeatType.once;
    } else if (weekdays.length == 7) {
      return ReminderRepeatType.daily;
    } else {
      return ReminderRepeatType.selectedWeekdays;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id > 0 ? id : null, // Let SQLite auto-increment handle it if id <= 0
      'user_id': userId,
      'title': title,
      'description': description,
      'hour': hour,
      'minute': minute,
      'weekdays': jsonEncode(weekdays),
      'repeat_type': repeatType.toValue(),
      'ringtone_asset': ringtoneAsset,
      'android_sound_resource': androidSoundResource,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudyReminder.fromMap(Map<String, dynamic> map) {
    List<int> parsedWeekdays = [];
    if (map['weekdays'] != null) {
      try {
        final decoded = jsonDecode(map['weekdays'] as String);
        if (decoded is List) {
          parsedWeekdays = decoded.map((e) => e as int).toList();
        }
      } catch (_) {
        // Fallback
      }
    }
    return StudyReminder(
      id: map['id'] as int? ?? 0,
      userId: map['user_id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      hour: map['hour'] as int? ?? 0,
      minute: map['minute'] as int? ?? 0,
      weekdays: parsedWeekdays,
      ringtoneAsset: map['ringtone_asset'] as String? ?? 'assets/audios/file.mp3',
      androidSoundResource: map['android_sound_resource'] as String?,
      vibrationEnabled: (map['vibration_enabled'] as int? ?? 1) == 1,
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  StudyReminder copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    int? hour,
    int? minute,
    List<int>? weekdays,
    String? ringtoneAsset,
    String? androidSoundResource,
    bool? vibrationEnabled,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      ringtoneAsset: ringtoneAsset ?? this.ringtoneAsset,
      androidSoundResource: androidSoundResource ?? this.androidSoundResource,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
