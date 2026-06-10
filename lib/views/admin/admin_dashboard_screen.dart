import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/admin_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<AdminController>().loadData();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản Admin không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthController>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminController>();
    final report = provider.report;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleLogout();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị hệ thống'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleLogout,
          ),
          actions: [
            IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeroCard(report: report),
                    const SizedBox(height: 16),
                    _StatsGrid(report: report),
                    const SizedBox(height: 16),
                    _QuickActionsCard(),
                    const SizedBox(height: 16),
                    _SubjectOverview(provider: provider),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AdminReportStat? report;

  const _HeroCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.admin,
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan hệ thống', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Quản lý người dùng, tài liệu, đề thi và báo cáo trong một màn hình.',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniBadge(label: 'Lượt làm bài: ${report?.totalExamAttempts ?? 0}'),
              _MiniBadge(label: 'Cập nhật: ${report?.generatedAt.toLocal().toString().split('.').first ?? '-'}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AdminReportStat? report;

  const _StatsGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatItem('Tổng user', report?.totalUsers.toString() ?? '0', Icons.people, AppColors.primary),
      _StatItem('Tổng học sinh', report?.totalStudents.toString() ?? '0', Icons.school, AppColors.success),
      _StatItem('Tổng giáo viên', report?.totalTeachers.toString() ?? '0', Icons.person_pin, AppColors.accent),
      _StatItem('Tổng tài liệu', report?.totalDocuments.toString() ?? '0', Icons.description, Color(0xFF8B5CF6)),
      _StatItem('Tổng đề thi', report?.totalExams.toString() ?? '0', Icons.assignment, AppColors.error),
      _StatItem('Số lượt làm bài', report?.totalExamAttempts.toString() ?? '0', Icons.bar_chart, AppColors.secondary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) => _StatCard(item: cards[index]),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  void _showSendNotificationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String body = '';
    String targetRole = 'all';
    NotificationType type = NotificationType.announcement;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool localLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Gửi thông báo hệ thống'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề thông báo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tiêu đề không được để trống';
                          }
                          return null;
                        },
                        onChanged: (val) => title = val,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nội dung thông báo',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nội dung không được để trống';
                          }
                          return null;
                        },
                        onChanged: (val) => body = val,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: targetRole,
                        decoration: const InputDecoration(
                          labelText: 'Đối tượng nhận',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'student', child: Text('Học sinh')),
                          DropdownMenuItem(value: 'teacher', child: Text('Giáo viên')),
                          DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              targetRole = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<NotificationType>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Loại thông báo',
                          border: OutlineInputBorder(),
                        ),
                        items: NotificationType.values.map((t) {
                          String label = t.name;
                          if (t == NotificationType.announcement) {
                            label = 'Thông báo';
                          } else if (t == NotificationType.examReminder) {
                            label = 'Nhắc thi/Đề mới';
                          } else if (t == NotificationType.assignmentDue) {
                            label = 'Hạn nộp bài';
                          } else if (t == NotificationType.warning) {
                            label = 'Cảnh báo';
                          } else if (t == NotificationType.info) {
                            label = 'Tin tức/Hướng dẫn';
                          } else if (t == NotificationType.success) {
                            label = 'Thành công';
                          } else if (t == NotificationType.error) {
                            label = 'Lỗi hệ thống';
                          }
                          return DropdownMenuItem(value: t, child: Text(label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              type = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: localLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: localLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              localLoading = true;
                            });
                            try {
                              final authProvider = context.read<AuthController>();
                              final senderId = authProvider.currentUser?.id ?? 'admin_uid';
                              final senderRole = authProvider.currentUser?.role.toValue() ?? 'admin';

                              await context.read<AdminController>().sendSystemNotification(
                                    title: title,
                                    body: body,
                                    targetRole: targetRole,
                                    type: type,
                                    senderId: senderId,
                                    senderRole: senderRole,
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã gửi thông báo hệ thống thành công!')),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                localLoading = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gửi thông báo thất bại: $e')),
                                );
                              }
                            }
                          }
                        },
                  child: localLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem('Người dùng', Icons.people, AppRoutes.adminUsers, AppColors.primary),
      _ActionItem('Tài liệu', Icons.description, AppRoutes.adminDocuments, Color(0xFF8B5CF6)),
      _ActionItem('Đề & câu hỏi', Icons.quiz, AppRoutes.adminExams, AppColors.accent),
      _ActionItem('Báo cáo', Icons.assessment, AppRoutes.adminReports, AppColors.success),
      _ActionItem('Notification', Icons.campaign, 'dialog_send_notification', Colors.orange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thao tác nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) {
            final item = actions[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (item.route == 'dialog_send_notification') {
                  _showSendNotificationDialog(context);
                } else {
                  Navigator.pushNamed(context, item.route);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.color.withOpacity(0.16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SubjectOverview extends StatelessWidget {
  final AdminController provider;

  const _SubjectOverview({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thống kê theo môn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (provider.subjectReports.isEmpty)
          const _EmptyState(message: 'Chưa có dữ liệu môn học')
        else
          ...provider.subjectReports.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.12),
                          child: Text(item.subject.name[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${item.documentCount} tài liệu • ${item.examCount} đề • ${item.questionCount} câu'),
                            ],
                          ),
                        ),
                        Text(item.averageScore.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item.label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _ActionItem(this.title, this.icon, this.route, this.color);
}

class _MiniBadge extends StatelessWidget {
  final String label;

  const _MiniBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}
