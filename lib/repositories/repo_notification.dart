import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_progress.dart';

abstract class NotificationRepository {
  Stream<List<NotificationItem>> streamNotificationsByUser(String userId);
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
  Stream<List<NotificationItem>> streamNotificationsByUser(String userId) {
    return Stream.value(
      _notifications
          .where((n) => n.userId == userId)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<List<NotificationItem>> getNotificationsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications
        .where((n) => n.userId == userId)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<NotificationItem>> getUnreadNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications
        .where((n) => n.userId == userId && !n.isRead)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 300));
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
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications.add(notification);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications.removeWhere((n) => n.id == notificationId);
  }
}

/// Real Firestore Notification Repository
class FirestoreNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<NotificationItem>> streamNotificationsByUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          userId: data['receiverId'] ?? '',
          title: data['title'] ?? '',
          message: data['body'] ?? '',
          type: NotificationType.fromValue(data['type'] ?? 'info'),
          actionUrl: data['actionUrl'] ?? (data['relatedId'] != null ? '/student/exam-detail/${data['relatedId']}' : null),
          isRead: data['isRead'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
          senderId: data['senderId'] as String?,
          senderRole: data['senderRole'] as String?,
        );
      }).toList();
    });
  }

  @override
  Future<List<NotificationItem>> getNotificationsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NotificationItem(
        id: doc.id,
        userId: data['receiverId'] ?? '',
        title: data['title'] ?? '',
        message: data['body'] ?? '',
        type: NotificationType.fromValue(data['type'] ?? 'info'),
        actionUrl: data['actionUrl'] ?? (data['relatedId'] != null ? '/student/exam-detail/${data['relatedId']}' : null),
        isRead: data['isRead'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
        senderId: data['senderId'] as String?,
        senderRole: data['senderRole'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<NotificationItem>> getUnreadNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NotificationItem(
        id: doc.id,
        userId: data['receiverId'] ?? '',
        title: data['title'] ?? '',
        message: data['body'] ?? '',
        type: NotificationType.fromValue(data['type'] ?? 'info'),
        actionUrl: data['actionUrl'] ?? (data['relatedId'] != null ? '/student/exam-detail/${data['relatedId']}' : null),
        isRead: data['isRead'] ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        readAt: null,
        senderId: data['senderId'] as String?,
        senderRole: data['senderRole'] as String?,
      );
    }).toList();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    return snapshot.size;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> createNotification(NotificationItem notification) async {
    await _firestore.collection('notifications').add({
      'title': notification.title,
      'body': notification.message,
      'type': notification.type.toValue(),
      'senderId': notification.senderId ?? 'system',
      'senderRole': notification.senderRole ?? 'admin',
      'receiverId': notification.userId,
      'receiverRole': 'student',
      'targetRole': 'student',
      'relatedId': notification.actionUrl,
      'isRead': notification.isRead,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> createBroadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
    required String senderId,
    required String senderRole,
    required String targetRole,
    String? relatedId,
  }) async {
    // 1. Query users matching the target role, or all users if targetRole is 'all'
    Query query = _firestore.collection('users');
    if (targetRole != 'all') {
      query = query.where('role', isEqualTo: targetRole);
    }
    final usersSnapshot = await query.get();

    final batch = _firestore.batch();
    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final receiverRole = userData['role'] as String? ?? 'student';
      final docRef = _firestore.collection('notifications').doc();
      batch.set(docRef, {
        'title': title,
        'body': body,
        'type': type.toValue(),
        'senderId': senderId,
        'senderRole': senderRole,
        'receiverId': userDoc.id,
        'receiverRole': receiverRole,
        'targetRole': targetRole,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
