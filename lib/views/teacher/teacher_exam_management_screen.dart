import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/models/exam_model.dart';

class TeacherExamManagementScreen extends StatefulWidget {
  const TeacherExamManagementScreen({super.key});

  @override
  State<TeacherExamManagementScreen> createState() =>
      _TeacherExamManagementScreenState();
}

class _TeacherExamManagementScreenState
    extends State<TeacherExamManagementScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExams();
    });
  }

  Future<void> _loadExams() async {
    setState(() => _isRefreshing = true);
    try {
      final authProvider = context.read<AuthController>();
      final teacherProvider = context.read<TeacherController>();
      if (authProvider.currentUser != null) {
        await teacherProvider.ensureLoaded(authProvider.currentUser!);
      }
      await teacherProvider.refreshCreatedExams();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showErrorSnackBar(String errorMsg) {
    String message = 'Không thể thực hiện thao tác. Vui lòng thử lại.';
    if (errorMsg.contains('permission-denied') ||
        errorMsg.contains('không có quyền')) {
      message = 'Bạn không có quyền thực hiện thao tác này.';
    } else if (errorMsg.contains('network-request-failed') ||
        errorMsg.contains('kết nối mạng')) {
      message = 'Không có kết nối mạng. Vui lòng thử lại.';
    } else {
      message = errorMsg.replaceAll('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _togglePublishStatus(
    TeacherController provider,
    Exam exam,
  ) async {
    try {
      if (exam.isPublished) {
        await provider.unpublishExam(exam.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chuyển đề thi về bản nháp.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (exam.questionCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể phát hành đề thi chưa có câu hỏi nào.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        await provider.publishExam(exam.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đề thi đã được phát hành thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _deleteExam(TeacherController provider, Exam exam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa đề thi "${exam.title}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteTeacherExam(exam.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa đề thi thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đề thi'),
        actions: [
          IconButton(onPressed: _loadExams, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.teacherExamCreate);
          _loadExams();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo đề kiểm tra'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExams,
          child: _isRefreshing && teacherProvider.createdExams.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : teacherProvider.createdExams.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: teacherProvider.createdExams.length,
                  itemBuilder: (context, index) {
                    final exam = teacherProvider.createdExams[index];
                    return _buildExamCard(teacherProvider, exam);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có đề kiểm tra',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy tạo đề kiểm tra đầu tiên của bạn.',
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.teacherExamCreate,
                    );
                    _loadExams();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo đề kiểm tra ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(TeacherController provider, Exam exam) {
    final createdDateStr = DateFormat('dd/MM/yyyy').format(exam.createdAt);
    final isDraft = exam.status == 'draft';
    final subjectName = provider.getSubjectName(exam.subjectId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subjectName,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Colors.grey.shade100
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDraft ? 'Bản nháp' : 'Đã phát hành',
                        style: TextStyle(
                          color: isDraft
                              ? Colors.grey.shade700
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                if (exam.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    exam.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                // Meta info
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.durationMinutes} phút',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.quiz_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${exam.questionCount} câu hỏi',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      createdDateStr,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.teacherQuestionCreate,
                      arguments: {'examId': exam.id, 'examTitle': exam.title},
                    );
                    _loadExams();
                  },
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Thêm câu hỏi'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _togglePublishStatus(provider, exam),
                  icon: Icon(
                    isDraft
                        ? Icons.publish_outlined
                        : Icons.unpublished_outlined,
                    size: 18,
                  ),
                  label: Text(isDraft ? 'Phát hành' : 'Hủy phát hành'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDraft
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteExam(provider, exam),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
