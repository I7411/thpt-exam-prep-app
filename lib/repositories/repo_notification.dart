/// Notification repository for managing notifications
library;
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> getNotificationsByUser(String userId);
  Future<List<NotificationItem>> getUnreadNotifications(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> createNotification(NotificationItem notification);
  Future<void> deleteNotification(String notificationId);
}

/// Mock implementation
class MockNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _notifications = List.from(MockNotificationsData.notifications);

  @override
  Future<List<NotificationItem>> getNotificationsByUser(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _notifications
        .where((n) => n.userId == userId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<NotificationItem>> getUnreadNotifications(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _notifications
        .where((n) => n.userId == userId && !n.isRead)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(Duration(milliseconds: 200));
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> createNotification(NotificationItem notification) async {
    await Future.delayed(Duration(milliseconds: 300));
    _notifications.add(notification);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(Duration(milliseconds: 300));
    _notifications.removeWhere((n) => n.id == notificationId);
  }
}

