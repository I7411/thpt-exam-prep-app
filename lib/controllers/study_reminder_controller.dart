import 'package:flutter/foundation.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/data/local/app_database.dart';
import 'package:thpt_exam_prep_app/services/notification_service.dart';

class StudyReminderController extends ChangeNotifier {
  final AppLocalRepository _localRepo = AppLocalRepository.instance;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<StudyReminder> _reminders = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<StudyReminder> get reminders => List.unmodifiable(_reminders);

  Future<void> loadReminders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await _localRepo.getRemindersByUser(userId);
      _reminders.sort((a, b) {
        final cmpHour = a.hour.compareTo(b.hour);
        if (cmpHour != 0) return cmpHour;
        return a.minute.compareTo(b.minute);
      });
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách lời nhắc: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReminder(StudyReminder reminder) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _localRepo.createReminder(reminder);
      if (created.isEnabled) {
        await NotificationService.instance.scheduleReminder(created);
      }
      _reminders.add(created);
      _reminders.sort((a, b) {
        final cmpHour = a.hour.compareTo(b.hour);
        if (cmpHour != 0) return cmpHour;
        return a.minute.compareTo(b.minute);
      });
      return true;
    } catch (e) {
      _errorMessage = 'Không thể tạo lời nhắc: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateReminder(StudyReminder reminder) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await NotificationService.instance.cancelReminder(reminder.id);
      await _localRepo.updateReminder(reminder);
      if (reminder.isEnabled) {
        await NotificationService.instance.scheduleReminder(reminder);
      }
      final idx = _reminders.indexWhere((r) => r.id == reminder.id);
      if (idx >= 0) {
        _reminders[idx] = reminder;
      }
      _reminders.sort((a, b) {
        final cmpHour = a.hour.compareTo(b.hour);
        if (cmpHour != 0) return cmpHour;
        return a.minute.compareTo(b.minute);
      });
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật lời nhắc: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> toggleReminder(StudyReminder reminder, bool isEnabled) async {
    final updated = reminder.copyWith(isEnabled: isEnabled, updatedAt: DateTime.now());
    return updateReminder(updated);
  }

  Future<bool> deleteReminder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await NotificationService.instance.cancelReminder(id);
      await _localRepo.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa lời nhắc: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAllReminders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userReminders = await _localRepo.getRemindersByUser(userId);
      for (final r in userReminders) {
        await NotificationService.instance.cancelReminder(r.id);
      }
      await _localRepo.deleteAllRemindersForUser(userId);
      _reminders.clear();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa tất cả lời nhắc: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMemory() {
    _reminders.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
