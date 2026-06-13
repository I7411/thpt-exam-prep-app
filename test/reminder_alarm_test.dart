import 'package:flutter_test/flutter_test.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/services/ringtone_catalog_service.dart';

void main() {
  group('StudyReminder Model Tests', () {
    test('1. Serialization and Deserialization (toMap & fromMap)', () {
      final now = DateTime.now();
      final reminder = StudyReminder(
        id: 1,
        userId: 'test-user-123',
        title: 'Ôn tập Tiếng Anh',
        description: 'Làm đề thi thử số 5',
        hour: 20,
        minute: 30,
        weekdays: [1, 3, 5],
        ringtoneAsset: 'assets/audios/file.mp3',
        androidSoundResource: 'file',
        vibrationEnabled: true,
        isEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = reminder.toMap();
      expect(map['title'], 'Ôn tập Tiếng Anh');
      expect(map['hour'], 20);
      expect(map['minute'], 30);
      expect(map['repeat_type'], 'selectedWeekdays');
      expect(map['vibration_enabled'], 1);
      expect(map['is_enabled'], 1);

      final deserialized = StudyReminder.fromMap(map);
      expect(deserialized.id, 1);
      expect(deserialized.userId, 'test-user-123');
      expect(deserialized.title, 'Ôn tập Tiếng Anh');
      expect(deserialized.description, 'Làm đề thi thử số 5');
      expect(deserialized.hour, 20);
      expect(deserialized.minute, 30);
      expect(deserialized.weekdays, [1, 3, 5]);
      expect(deserialized.ringtoneAsset, 'assets/audios/file.mp3');
      expect(deserialized.androidSoundResource, 'file');
      expect(deserialized.vibrationEnabled, true);
      expect(deserialized.isEnabled, true);
    });

    test('2. copyWith verification', () {
      final reminder = StudyReminder(
        id: 1,
        title: 'Học Toán',
        hour: 18,
        minute: 0,
        weekdays: const [],
        ringtoneAsset: 'assets/audios/file.mp3',
        vibrationEnabled: true,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = reminder.copyWith(
        title: 'Học Lý',
        isEnabled: false,
      );

      expect(updated.id, 1);
      expect(updated.title, 'Học Lý');
      expect(updated.isEnabled, false);
      expect(updated.hour, 18);
    });

    test('3. Repeat type deduction based on weekdays', () {
      final onceReminder = StudyReminder(
        id: 1,
        title: 'Một lần',
        hour: 8,
        minute: 0,
        weekdays: const [],
        ringtoneAsset: 'assets/audios/file.mp3',
        vibrationEnabled: true,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(onceReminder.repeatType, ReminderRepeatType.once);

      final dailyReminder = StudyReminder(
        id: 2,
        title: 'Hằng ngày',
        hour: 8,
        minute: 0,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        ringtoneAsset: 'assets/audios/file.mp3',
        vibrationEnabled: true,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(dailyReminder.repeatType, ReminderRepeatType.daily);

      final weeklyReminder = StudyReminder(
        id: 3,
        title: 'Một số ngày',
        hour: 8,
        minute: 0,
        weekdays: const [1, 3, 5],
        ringtoneAsset: 'assets/audios/file.mp3',
        vibrationEnabled: true,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(weeklyReminder.repeatType, ReminderRepeatType.selectedWeekdays);
    });
  });

  group('Ringtone Catalog Tests', () {
    test('4. Ringtone asset-to-Android-resource mapping', () {
      final ringtone1 = RingtoneCatalogService.getByAssetPath('assets/audios/file.mp3');
      expect(ringtone1.name, contains('Mạnh mẽ'));
      expect(ringtone1.androidRawName, 'file');

      final ringtone2 = RingtoneCatalogService.getByAssetPath('assets/audios/alarm_gentle.wav');
      expect(ringtone2.name, contains('Nhẹ nhàng'));
      expect(ringtone2.androidRawName, 'alarm_gentle');

      // Fallback fallback test
      final fallback = RingtoneCatalogService.getByAssetPath('assets/audios/invalid.mp3');
      expect(fallback.assetPath, 'assets/audios/file.mp3');
      expect(fallback.androidRawName, 'file');
    });
  });

  group('Next Trigger Time Logic Tests (Pure Math/Simulation)', () {
    test('5. Calculating the next daily reminder time (rolls to next day if past)', () {
      // Simulate scheduling math:
      // If now is 15:30 and scheduled is 16:00 -> scheduled today
      // If now is 16:30 and scheduled is 16:00 -> scheduled tomorrow
      final now = DateTime(2026, 6, 13, 16, 30);
      
      // Target time: 16:00
      var target = DateTime(now.year, now.month, now.day, 16, 0);
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      
      expect(target.year, 2026);
      expect(target.month, 6);
      expect(target.day, 14); // Rolls to tomorrow (14th)
      expect(target.hour, 16);
      expect(target.minute, 0);

      // Target time: 17:00
      var target2 = DateTime(now.year, now.month, now.day, 17, 0);
      if (target2.isBefore(now)) {
        target2 = target2.add(const Duration(days: 1));
      }

      expect(target2.day, 13); // Today (13th)
      expect(target2.hour, 17);
      expect(target2.minute, 0);
    });

    test('6. Calculating next selected weekday reminder time', () {
      // Say now is Saturday, 2026-06-13 (Saturday's ISO weekday is 6 in Dart)
      // If we schedule for Sunday (7) -> should schedule for tomorrow (7)
      // If we schedule for Monday (1) -> should schedule for Monday (15th)
      final now = DateTime(2026, 6, 13, 12, 0); // Saturday
      expect(now.weekday, DateTime.saturday);

      // Schedule Monday (1)
      var targetMonday = DateTime(now.year, now.month, now.day, 8, 0);
      while (targetMonday.weekday != DateTime.monday) {
        targetMonday = targetMonday.add(const Duration(days: 1));
      }
      expect(targetMonday.day, 15);
      expect(targetMonday.weekday, DateTime.monday);

      // Schedule Sunday (7)
      var targetSunday = DateTime(now.year, now.month, now.day, 8, 0);
      while (targetSunday.weekday != DateTime.sunday) {
        targetSunday = targetSunday.add(const Duration(days: 1));
      }
      expect(targetSunday.day, 14);
      expect(targetSunday.weekday, DateTime.sunday);
    });
  });
}
