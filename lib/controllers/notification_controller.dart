import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';
import 'package:thpt_exam_prep_app/services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();

  bool _isLoading = false;
  String? _userId;
  List<NotificationItem> _notifications = <NotificationItem>[];
  StreamSubscription<List<NotificationItem>>? _streamSubscription;

  bool get isLoading => _isLoading;
  String? get userId => _userId;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> initialize(String userId) async {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    _isLoading = true;
    notifyListeners();

    await _streamSubscription?.cancel();

    _streamSubscription = _repositoryService.notification
        .streamNotificationsByUser(userId)
        .listen(
      (items) {
        if (!_isLoading && _notifications.isNotEmpty) {
          for (final item in items) {
            final wasPresent = _notifications.any((n) => n.id == item.id);
            if (!wasPresent && !item.isRead) {
              NotificationService.instance.showLocalNotification(
                id: item.id.hashCode,
                title: item.title,
                body: item.message,
                payload: item.actionUrl ?? '/student/notifications',
                deduplicationId: item.id,
              );
            }
          }
        }
        _notifications = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Lỗi stream thông báo Firestore: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repositoryService.notification.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Lỗi đánh dấu đã đọc: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    try {
      await _repositoryService.notification.markAllAsRead(_userId!);
    } catch (e) {
      debugPrint('Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }

  Future<void> refresh() async {
    await _reload();
  }

  Future<void> _reload() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _repositoryService.notification
          .getNotificationsByUser(_userId!)
          .timeout(const Duration(seconds: 12));
      _notifications = items.take(20).toList();
    } catch (e) {
      debugPrint('Không tải lại được thông báo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  NotificationType? mostFrequentType() {
    if (_notifications.isEmpty) return null;
    final counts = <NotificationType, int>{};
    for (final item in _notifications) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return entries.first.key;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
