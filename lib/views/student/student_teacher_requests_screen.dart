import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_student_connection_controller.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class StudentTeacherRequestsScreen extends StatefulWidget {
  const StudentTeacherRequestsScreen({super.key});

  @override
  State<StudentTeacherRequestsScreen> createState() =>
      _StudentTeacherRequestsScreenState();
}

class _StudentTeacherRequestsScreenState
    extends State<StudentTeacherRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  AppUser? get _student {
    final user = context.read<AuthController>().currentUser;
    if (user?.role == UserRole.student) {
      return user;
    }
    return null;
  }

  Future<void> _loadData({bool force = false}) async {
    final student = _student;
    if (student == null) return;
    await context.read<TeacherStudentConnectionController>().loadForStudent(
      student,
      force: force,
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    final success = await context
        .read<TeacherStudentConnectionController>()
        .acceptRequest(requestId);

    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chấp nhận lời mời giáo viên.')),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    final success = await context
        .read<TeacherStudentConnectionController>()
        .rejectRequest(requestId);

    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối lời mời giáo viên.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthController>().currentUser;

    if (student?.role != UserRole.student) {
      return const Scaffold(
        body: Center(child: Text('Chỉ học sinh mới có thể xem lời mời.')),
      );
    }

    return Consumer<TeacherStudentConnectionController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Lời mời giáo viên'),
            actions: [
              IconButton(
                onPressed: controller.isLoading
                    ? null
                    : () => _loadData(force: true),
                icon: const Icon(Icons.refresh),
                tooltip: 'Tải lại',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _loadData(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _MessageBanner(
                  message: controller.errorMessage,
                  color: AppColors.error,
                  icon: Icons.error_outline,
                  onClose: controller.clearMessages,
                ),
                _MessageBanner(
                  message: controller.successMessage,
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                  onClose: controller.clearMessages,
                ),
                if (controller.isLoading &&
                    controller.studentPendingRequests.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (controller.studentPendingRequests.isEmpty)
                  const _EmptyState()
                else
                  ...controller.studentPendingRequests.map(
                    (request) => _TeacherRequestCard(
                      request: request,
                      isBusy: controller.isLoading,
                      onAccept: () => _acceptRequest(request.id),
                      onReject: () => _rejectRequest(request.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeacherRequestCard extends StatelessWidget {
  final TeacherStudentRequest request;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TeacherRequestCard({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.cyanSoft,
                child: Icon(Icons.assignment_ind, color: AppColors.secondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.teacherName.isEmpty
                          ? 'Giáo viên'
                          : request.teacherName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      request.teacherEmail,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gửi ngày ${_formatDate(request.createdAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onAccept,
                icon: const Icon(Icons.check),
                label: const Text('Chấp nhận'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onReject,
                icon: const Icon(Icons.close),
                label: const Text('Từ chối'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onClose;

  const _MessageBanner({
    required this.message,
    required this.color,
    required this.icon,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            color: AppColors.muted.withOpacity(0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa có lời mời nào',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lời mời kết nối từ giáo viên sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
