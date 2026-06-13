/// Notification type enumeration
enum NotificationType {
  info,
  warning,
  success,
  error,
  announcement,
  examReminder,
  assignmentDue;

  String toValue() => name;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.info,
    );
  }
}

/// Notification item model (ThÃ´ng bÃ¡o)
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? senderId;
  final String? senderRole;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.senderId,
    this.senderRole,
  });

  /// Create NotificationItem from JSON
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromValue(json['type'] as String? ?? 'info'),
      actionUrl: json['actionUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      senderId: json['senderId'] as String?,
      senderRole: json['senderRole'] as String?,
    );
  }

  /// Convert NotificationItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toValue(),
      'actionUrl': actionUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'senderId': senderId,
      'senderRole': senderRole,
    };
  }

  /// Create a copy with modified fields
  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? senderId,
    String? senderRole,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  @override
  String toString() => 'NotificationItem(id: $id, title: $title)';
}
