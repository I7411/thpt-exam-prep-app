import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_student_connection_controller.dart';
import 'package:thpt_exam_prep_app/providers/teacher_provider.dart';
import 'package:thpt_exam_prep_app/models.dart';

import 'package:thpt_exam_prep_app/providers_auth.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final _emailController = TextEditingController();
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  AppUser? get _teacher {
    final user = context.read<AuthController>().currentUser;
    if (user?.role == UserRole.teacher) {
      return user;
    }
    return null;
  }

  Future<void> _loadData({bool force = false}) async {
    final teacher = _teacher;
    if (teacher == null) return;
    await context.read<TeacherStudentConnectionController>().loadForTeacher(
      teacher,
      force: force,
    );
  }

  Future<void> _searchStudent() async {
    await context
        .read<TeacherStudentConnectionController>()
        .searchStudentByEmail(_emailController.text);
  }

  Future<void> _sendRequest() async {
    final teacher = _teacher;
    if (teacher == null) return;

    final success = await context
        .read<TeacherStudentConnectionController>()
        .sendConnectionRequest(_emailController.text, teacher: teacher, classId: _selectedClassId);

    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi lời mời kết nối học sinh.')),
    );
  }

  Future<void> _removeConnection(TeacherStudentRequest request) async {
    final success = await context
        .read<TeacherStudentConnectionController>()
        .removeStudentConnection(request.teacherId, request.studentId);

    if (!mounted || !success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa kết nối học sinh.')));
  }

  @override
  Widget build(BuildContext context) {
    final teacher = context.watch<AuthController>().currentUser;

    if (teacher?.role != UserRole.teacher) {
      return const Scaffold(
        body: Center(child: Text('Chỉ giáo viên mới có thể quản lý học sinh.')),
      );
    }

    return Consumer<TeacherStudentConnectionController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý học sinh'),
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
                _SearchPanel(
                  emailController: _emailController,
                  isBusy:
                      controller.isSearching ||
                      controller.isSending ||
                      controller.isLoading,
                  searchedStudent: controller.searchedStudent,
                  selectedClassId: _selectedClassId,
                  onClassChanged: (val) {
                    setState(() {
                      _selectedClassId = val;
                    });
                  },
                  onSearch: _searchStudent,
                  onSend: _sendRequest,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Lời mời đang chờ',
                  count: controller.teacherPendingRequests.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.isLoading &&
                    controller.teacherPendingRequests.isEmpty &&
                    controller.myStudents.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (controller.teacherPendingRequests.isEmpty)
                  const _EmptyPanel(message: 'Chưa có lời mời nào đang chờ.')
                else
                  ...controller.teacherPendingRequests.map(
                    (request) => _RequestTile(request: request),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Học sinh của tôi',
                  count: controller.myStudents.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (controller.myStudents.isEmpty)
                  const _EmptyPanel(
                    message: 'Chưa có học sinh nào chấp nhận kết nối.',
                  )
                else
                  ...controller.myStudents.map(
                    (request) => _ConnectedStudentTile(
                      request: request,
                      progress: controller.progressForStudent(
                        request.studentId,
                      ),
                      onRemove: () => _removeConnection(request),
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

class _SearchPanel extends StatelessWidget {
  final TextEditingController emailController;
  final bool isBusy;
  final AppUser? searchedStudent;
  final VoidCallback onSearch;
  final VoidCallback onSend;
  final String? selectedClassId;
  final ValueChanged<String?> onClassChanged;

  const _SearchPanel({
    required this.emailController,
    required this.isBusy,
    required this.searchedStudent,
    required this.onSearch,
    required this.onSend,
    required this.selectedClassId,
    required this.onClassChanged,
  });

  @override
  Widget build(BuildContext context) {
    final student = searchedStudent;
    final classes = context.watch<TeacherController>().classes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tìm học sinh bằng email',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: emailController,
            enabled: !isBusy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'student@example.com',
              labelText: 'Email học sinh',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (classes.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Gán vào lớp (không bắt buộc)',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Không chọn lớp (Gán sau)'),
                ),
                ...classes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.className),
                  );
                }),
              ],
              onChanged: onClassChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: isBusy ? null : onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Tìm'),
              ),
              FilledButton.icon(
                onPressed: isBusy ? null : onSend,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Gửi lời mời'),
              ),
            ],
          ),
          if (student != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SmallUserRow(
              name: student.fullName,
              email: student.email,
              icon: Icons.school_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedStudentTile extends StatelessWidget {
  final TeacherStudentRequest request;
  final StudentProgressPreview? progress;
  final VoidCallback onRemove;

  const _ConnectedStudentTile({
    required this.request,
    required this.progress,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currentProgress = progress;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SmallUserRow(
                  name: request.studentName,
                  email: request.studentEmail,
                  icon: Icons.person_outline,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.link_off),
                tooltip: 'Xóa kết nối',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (currentProgress == null)
            Text(
              'Chưa có dữ liệu tiến độ học tập.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MetricChip(
                  label:
                      '${currentProgress.averageScore.toStringAsFixed(1)} điểm TB',
                  color: AppColors.primary,
                ),
                _MetricChip(
                  label:
                      '${currentProgress.completionPercentage.toStringAsFixed(0)}% hoàn thành',
                  color: AppColors.success,
                ),
                _MetricChip(
                  label: '${currentProgress.totalExamsTaken} bài thi',
                  color: AppColors.accent,
                ),
                _MetricChip(
                  label: '${currentProgress.streakDays} ngày liên tiếp',
                  color: AppColors.secondary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final TeacherStudentRequest request;

  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SmallUserRow(
              name: request.studentName,
              email: request.studentEmail,
              icon: Icons.hourglass_top,
            ),
          ),
          const _MetricChip(label: 'Đang chờ', color: AppColors.accent),
        ],
      ),
    );
  }
}

class _SmallUserRow extends StatelessWidget {
  final String name;
  final String email;
  final IconData icon;

  const _SmallUserRow({
    required this.name,
    required this.email,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Học sinh' : name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                email,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        _MetricChip(label: count.toString(), color: AppColors.primary),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetricChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
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

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
    );
  }
}
