import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/services/notification_service.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/notification_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _initialized = false;
  String? _fcmToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final authProvider = context.read<AuthController>();
    final userId = authProvider.currentUser?.id ?? 'student_001';
    context.read<NotificationController>().initialize(userId);

    _fetchFcmToken();
    _initialized = true;
  }

  Future<void> _fetchFcmToken() async {
    // Poll a few times with delay to wait for FCM Token to register on startup
    for (int i = 0; i < 6; i++) {
      final token = NotificationService.instance.fcmToken;
      if (token != null) {
        if (mounted) {
          setState(() {
            _fcmToken = token;
          });
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
      builder: (context, provider, _) {
        final authProvider = context.read<AuthController>();
        final showFcmToken = kDebugMode && authProvider.currentUser?.role == UserRole.admin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông báo'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: provider.unreadCount == 0 ? null : provider.markAllAsRead,
                child: const Text('Đánh dấu tất cả đã đọc'),
              ),
            ],
          ),
          body: provider.isLoading && provider.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: provider.notifications.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _StudyReminderPanel(
                              fcmToken: _fcmToken,
                              showFcmToken: showFcmToken,
                              onDemoReminder: () => _createReminder(context, payload: AppRoutes.studentNotifications),
                              onDailyReminder: () => _createDailyReminder(context),
                              onCancelAll: () => _cancelAll(context),
                            ),
                            const SizedBox(height: 32),
                            const _EmptyNotificationState(),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.notifications.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _StudyReminderPanel(
                                fcmToken: _fcmToken,
                                showFcmToken: showFcmToken,
                                onDemoReminder: () => _createReminder(context, payload: AppRoutes.studentNotifications),
                                onDailyReminder: () => _createDailyReminder(context),
                                onCancelAll: () => _cancelAll(context),
                              );
                            }

                            final notification = provider.notifications[index - 1];
                            return _NotificationTile(
                              notification: notification,
                              onTap: () {
                                if (!notification.isRead) {
                                  provider.markAsRead(notification.id);
                                }
                              },
                            );
                          },
                        ),
                ),
        );
      },
    );
  }

  Future<void> _createReminder(BuildContext context, {required String payload}) async {
    await NotificationService.instance.showStudyReminderDemo(payload: payload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo nhắc học demo sau 10 giây')),
    );
  }

  Future<void> _createDailyReminder(BuildContext context) async {
    await NotificationService.instance.scheduleDailyStudyReminder(payload: AppRoutes.studentProgress);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lập lịch nhắc học mỗi ngày lúc 19:00')),
    );
  }

  Future<void> _cancelAll(BuildContext context) async {
    await NotificationService.instance.cancelAllNotifications();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy tất cả thông báo')),
    );
  }
}

class _StudyReminderPanel extends StatelessWidget {
  final String? fcmToken;
  final bool showFcmToken;
  final VoidCallback onDemoReminder;
  final VoidCallback onDailyReminder;
  final VoidCallback onCancelAll;

  const _StudyReminderPanel({
    required this.fcmToken,
    required this.showFcmToken,
    required this.onDemoReminder,
    required this.onDailyReminder,
    required this.onCancelAll,
  });

  @override
  Widget build(BuildContext context) {
    final token = fcmToken;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigo.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt thông báo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Cấu hình nhắc học định kỳ và nhận tin nhắn ôn tập từ hệ thống.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onDemoReminder,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Tạo nhắc học demo'),
              ),
              OutlinedButton.icon(
                onPressed: onDailyReminder,
                icon: const Icon(Icons.schedule_outlined),
                label: const Text('Nhắc mỗi ngày 19:00'),
              ),
              TextButton.icon(
                onPressed: onCancelAll,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hủy tất cả thông báo'),
              ),
            ],
          ),
          if (showFcmToken && token != null && token.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Thiết bị kiểm thử (FCM Token):',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      token,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép FCM Token vào bộ nhớ tạm'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _notificationConfig(notification.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: notification.isRead ? Colors.white : config.color.withOpacity(0.08),
          border: Border.all(
            color: notification.isRead ? Colors.grey.shade200 : config.color.withOpacity(0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                  ),
                  if (notification.senderRole != null || notification.senderId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Người gửi: ${notification.senderRole == 'admin' ? 'Quản trị viên' : (notification.senderRole == 'teacher' ? 'Giáo viên' : 'Hệ thống')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ChipLabel(label: config.label, color: config.color),
                      _ChipLabel(
                        label: notification.isRead ? 'Đã đọc' : 'Chưa đọc',
                        color: notification.isRead ? Colors.green : Colors.orange,
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          foregroundColor: Colors.indigo,
                        ),
                        onPressed: onTap,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Đánh dấu đã đọc', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotificationConfig _notificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return const _NotificationConfig(
          label: 'Nhắc học',
          icon: Icons.notifications_active_outlined,
          color: Colors.blue,
        );
      case NotificationType.warning:
        return const _NotificationConfig(
          label: 'Nhắc học',
          icon: Icons.schedule_outlined,
          color: Colors.orange,
        );
      case NotificationType.examReminder:
        return const _NotificationConfig(
          label: 'Đề thi mới',
          icon: Icons.quiz_outlined,
          color: Colors.indigo,
        );
      case NotificationType.success:
        return const _NotificationConfig(
          label: 'Kết quả học tập',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );
      case NotificationType.announcement:
        return const _NotificationConfig(
          label: 'Tài liệu mới',
          icon: Icons.description_outlined,
          color: Colors.purple,
        );
      case NotificationType.error:
        return const _NotificationConfig(
          label: 'Cảnh báo',
          icon: Icons.warning_amber_outlined,
          color: Colors.red,
        );
      case NotificationType.assignmentDue:
        return const _NotificationConfig(
          label: 'Nhắc học',
          icon: Icons.assignment_outlined,
          color: Colors.teal,
        );
    }
  }

  String _formatTime(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _NotificationConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _NotificationConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipLabel({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Không có thông báo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Các thông báo mới sẽ xuất hiện ở đây.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
