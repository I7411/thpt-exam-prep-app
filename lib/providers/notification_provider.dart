import 'package:flutter/foundation.dart';

import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class NotificationProvider extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();

  bool _isLoading = false;
  String? _userId;
  List<NotificationItem> _notifications = <NotificationItem>[];

  bool get isLoading => _isLoading;
  String? get userId => _userId;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  Future<void> initialize(String userId) async {
    if (_userId == userId && _notifications.isNotEmpty) {
      return;
    }

    _userId = userId;
    _isLoading = true;
    notifyListeners();

    _notifications = await _repositoryService.notification.getNotificationsByUser(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _repositoryService.notification.markAsRead(notificationId);
    await _reload();
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    await _repositoryService.notification.markAllAsRead(_userId!);
    await _reload();
  }

  Future<void> refresh() async {
    await _reload();
  }

  Future<void> _reload() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();
    _notifications = await _repositoryService.notification.getNotificationsByUser(_userId!);
    _isLoading = false;
    notifyListeners();
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
}