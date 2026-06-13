import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/notification_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/controllers/study_reminder_controller.dart';
import 'package:thpt_exam_prep_app/views/reminder/reminder_list_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild AppBar actions when tab index changes
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final authProvider = context.read<AuthController>();
    final userId = authProvider.currentUser?.id ?? '';
    if (userId.isNotEmpty) {
      context.read<NotificationController>().initialize(userId);
      context.read<StudyReminderController>().loadReminders(userId);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteAllNotifications(NotificationController provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo hệ thống không?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('XÓA TẤT CẢ'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.deleteAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ thông báo hệ thống.')),
        );
      }
    }
  }

  Future<void> _deleteSingleNotification(NotificationController provider, String id) async {
    await provider.deleteNotification(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa thông báo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm thông báo'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Thông báo'),
                  if (notificationProvider.unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text(notificationProvider.unreadCount.toString()),
                      backgroundColor: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Text('Lời nhắc học'),
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 0) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'markRead') {
                  notificationProvider.markAllAsRead();
                } else if (value == 'deleteAll') {
                  _confirmDeleteAllNotifications(notificationProvider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'markRead',
                  enabled: notificationProvider.unreadCount > 0,
                  child: const Text('Đánh dấu đã đọc tất cả'),
                ),
                const PopupMenuItem(
                  value: 'deleteAll',
                  child: Text('Xóa tất cả thông báo'),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.add_alarm),
              tooltip: 'Tạo lời nhắc',
              onPressed: () {
                Navigator.of(context).pushNamed('/reminder/form');
              },
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: REMOTE NOTIFICATIONS
          notificationProvider.isLoading && notificationProvider.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: notificationProvider.refresh,
                  child: notificationProvider.notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            const Center(child: _EmptyNotificationState()),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: notificationProvider.notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = notificationProvider.notifications[index];
                            return _NotificationTile(
                              notification: notification,
                              onMarkRead: () {
                                if (!notification.isRead) {
                                  notificationProvider.markAsRead(notification.id);
                                }
                              },
                              onDelete: () => _deleteSingleNotification(notificationProvider, notification.id),
                            );
                          },
                        ),
                ),

          // TAB 2: LOCAL STUDY REMINDERS LIST
          const ReminderListScreen(),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final config = _notificationConfig(notification.type);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.grey.shade200 : config.color.withOpacity(0.2),
        ),
      ),
      color: notification.isRead ? Colors.white : config.color.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                                fontWeight: FontWeight.bold,
                                color: notification.isRead ? Colors.black87 : Colors.indigo[900],
                              ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
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
                  if (notification.senderRole != null) ...[
                    const SizedBox(height: 6),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!notification.isRead) ...[
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: onMarkRead,
                          icon: const Icon(Icons.done, size: 16),
                          label: const Text('Đọc', style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: Colors.red,
                        ),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
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
          label: 'Hệ thống',
          icon: Icons.info_outline,
          color: Colors.blue,
        );
      case NotificationType.warning:
        return const _NotificationConfig(
          label: 'Cảnh báo',
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
        );
      case NotificationType.examReminder:
        return const _NotificationConfig(
          label: 'Nhắc thi',
          icon: Icons.quiz_outlined,
          color: Colors.indigo,
        );
      case NotificationType.success:
        return const _NotificationConfig(
          label: 'Thành công',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        );
      case NotificationType.announcement:
        return const _NotificationConfig(
          label: 'Thông báo',
          icon: Icons.campaign_outlined,
          color: Colors.purple,
        );
      case NotificationType.error:
        return const _NotificationConfig(
          label: 'Lỗi',
          icon: Icons.error_outline,
          color: Colors.red,
        );
      case NotificationType.assignmentDue:
        return const _NotificationConfig(
          label: 'Bài tập',
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

  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo hệ thống',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới từ giáo viên hoặc hệ thống sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
