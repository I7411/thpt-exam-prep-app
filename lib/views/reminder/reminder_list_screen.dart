import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/study_reminder_controller.dart';
import 'package:thpt_exam_prep_app/services/ringtone_catalog_service.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReminders();
    });
  }

  void _loadReminders() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Provider.of<StudyReminderController>(context, listen: false).loadReminders(uid);
  }

  Future<void> _deleteReminder(StudyReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lời nhắc học'),
        content: const Text('Bạn có chắc muốn xóa lời nhắc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await Provider.of<StudyReminderController>(context, listen: false)
          .deleteReminder(reminder.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lời nhắc thành công!')),
        );
      }
    }
  }

  Future<void> _deleteAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả lời nhắc'),
        content: const Text(
          'Bạn có chắc muốn xóa tất cả lời nhắc học không?\nHành động này không thể hoàn tác.',
        ),
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
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final success = await Provider.of<StudyReminderController>(context, listen: false)
          .deleteAllReminders(uid);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa toàn bộ lời nhắc.')),
        );
      }
    }
  }

  String _formatRepeatInfo(StudyReminder reminder) {
    if (reminder.weekdays.isEmpty) {
      return 'Một lần';
    } else if (reminder.weekdays.length == 7) {
      return 'Hằng ngày';
    } else {
      final List<String> weekdaysLabels = [];
      final Map<int, String> labels = {
        1: 'Thứ 2',
        2: 'Thứ 3',
        3: 'Thứ 4',
        4: 'Thứ 5',
        5: 'Thứ 6',
        6: 'Thứ 7',
        7: 'Chủ nhật',
      };
      for (final w in reminder.weekdays) {
        if (labels.containsKey(w)) {
          weekdaysLabels.add(labels[w]!);
        }
      }
      return weekdaysLabels.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc nhở học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa tất cả',
            onPressed: _deleteAllReminders,
          ),
        ],
      ),
      body: Consumer<StudyReminderController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReminders,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.reminders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadReminders(),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Chưa có lời nhắc học tập. Hãy tạo lời nhắc đầu tiên để xây dựng thói quen học tập.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadReminders(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: controller.reminders.length,
              itemBuilder: (context, index) {
                final reminder = controller.reminders[index];
                final hourStr = reminder.hour.toString().padLeft(2, '0');
                final minuteStr = reminder.minute.toString().padLeft(2, '0');
                final timeStr = '$hourStr:$minuteStr';
                final repeatStr = _formatRepeatInfo(reminder);
                final ringtone = RingtoneCatalogService.getByAssetPath(reminder.ringtoneAsset);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: reminder.isEnabled
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            Switch(
                              value: reminder.isEnabled,
                              onChanged: (val) {
                                controller.toggleReminder(reminder, val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: reminder.isEnabled ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.description!,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.repeat, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                repeatStr,
                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.music_note, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              ringtone.name,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Sửa'),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/reminder/form',
                                  arguments: reminder,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              onPressed: () => _deleteReminder(reminder),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_alarm),
        label: const Text('Tạo lời nhắc'),
        onPressed: () {
          Navigator.of(context).pushNamed('/reminder/form');
        },
      ),
    );
  }
}
