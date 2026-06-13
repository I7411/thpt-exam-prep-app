import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_student_connection_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/models.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final String? classId;

  const TeacherClassDetailScreen({super.key, this.classId});

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthController>();
    final teacherController = context.read<TeacherController>();
    final classId = widget.classId ?? teacherController.classes.firstOrNull?.id;

    await teacherController.ensureLoaded(authProvider.currentUser, force: true);

    if (classId != null) {
      if (authProvider.currentUser != null) {
        await context.read<TeacherStudentConnectionController>().loadForTeacher(
          authProvider.currentUser!,
          force: true,
        );
      }
      await teacherController.loadClassLeaderboard(classId);
    }
  }

  void _showAddStudentDialog(BuildContext context, TeacherClass teacherClass) {
    final connectionController = context
        .read<TeacherStudentConnectionController>();
    final teacherProvider = context.read<TeacherController>();

    final currentStudentIds = teacherClass.studentIds.toSet();
    final addableStudents = connectionController.myStudents
        .where((req) => !currentStudentIds.contains(req.studentId))
        .toList();

    if (addableStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Thêm học sinh'),
          content: const Text(
            'Không có học sinh nào đã kết nối ngoài các thành viên hiện tại của lớp. Vui lòng gửi lời mời kết nối học sinh mới trước.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      return;
    }

    String? selectedStudentId = addableStudents.first.studentId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm học sinh vào lớp'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: const InputDecoration(
                      labelText: 'Học sinh kết nối',
                    ),
                    items: addableStudents.map((req) {
                      return DropdownMenuItem<String>(
                        value: req.studentId,
                        child: Text('${req.studentName} (${req.studentEmail})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedStudentId = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (selectedStudentId == null) return;
                    Navigator.pop(dialogContext);

                    final success = await teacherProvider.addStudentToClass(
                      classId: teacherClass.id,
                      studentId: selectedStudentId!,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Đã thêm học sinh vào lớp.'
                                : 'Lỗi khi thêm học sinh.',
                          ),
                        ),
                      );
                      _loadData();
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditClassNameDialog(
    BuildContext context,
    TeacherClass teacherClass,
  ) {
    final controller = TextEditingController(text: teacherClass.className);
    final teacherProvider = context.read<TeacherController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sửa tên lớp'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tên lớp mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(dialogContext);

              final success = await teacherProvider.editClassName(
                classId: teacherClass.id,
                newClassName: newName,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã đổi tên lớp thành $newName.'
                          : 'Lỗi khi sửa tên lớp.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, TeacherClass teacherClass) {
    final teacherProvider = context.read<TeacherController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lớp học'),
        content: Text(
          'Bạn có chắc chắn muốn xóa lớp ${teacherClass.className} không? Học sinh sẽ không thể thấy lớp này nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await teacherProvider.deleteClass(
                teacherClass.id,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã xóa lớp học thành công.'
                          : 'Lỗi khi xóa lớp học.',
                    ),
                  ),
                );
                if (success) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeStudent(
    BuildContext context,
    String classId,
    String studentId,
    String studentName,
  ) async {
    final teacherProvider = context.read<TeacherController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa học sinh khỏi lớp'),
        content: Text(
          'Bạn có chắc chắn muốn xóa học sinh $studentName khỏi lớp học này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await teacherProvider.removeStudentFromClass(
      classId: classId,
      studentId: studentId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Đã xóa học sinh khỏi lớp.' : 'Lỗi khi xóa học sinh.',
          ),
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherController>();
    final teacherClass = widget.classId == null
        ? teacherProvider.classes.firstOrNull
        : teacherProvider.classById(widget.classId!);

    if (teacherClass == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết lớp')),
        body: const Center(child: Text('Không tìm thấy lớp học.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lớp ${teacherClass.className}'),
          actions: [
            IconButton(
              onPressed: () => _showEditClassNameDialog(context, teacherClass),
              icon: const Icon(Icons.edit),
              tooltip: 'Sửa tên lớp',
            ),
            IconButton(
              onPressed: () => _confirmDeleteClass(context, teacherClass),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa lớp',
            ),
            IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chi tiết & Học sinh'),
              Tab(text: 'Bảng xếp hạng'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(context, teacherProvider, teacherClass),
                  const SizedBox(height: 16),
                  _buildStats(teacherProvider, teacherClass),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách học sinh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddStudentDialog(context, teacherClass),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm học sinh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStudents(context, teacherProvider, teacherClass),
                  const SizedBox(height: 24),
                  _buildRelatedExams(teacherProvider, teacherClass),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadData,
              child: _buildLeaderboardTab(teacherProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TeacherController teacherProvider,
    TeacherClass teacherClass,
  ) {
    final subjectName = teacherProvider.getSubjectName(teacherClass.subjectId);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teacherClass.className,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subjectName,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            teacherClass.description,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    TeacherController teacherProvider,
    TeacherClass teacherClass,
  ) {
    final students = teacherProvider.studentsForClass(teacherClass.id);
    final averageScore = students.isEmpty
        ? 0.0
        : students
                  .map((student) => student.averageScore)
                  .reduce((left, right) => left + right) /
              students.length;
    final averageProgress = students.isEmpty
        ? 0.0
        : students
                  .map((student) => student.completionPercentage)
                  .reduce((left, right) => left + right) /
              students.length;
    final passed = students.fold<int>(
      0,
      (sum, student) => sum + student.examsPassed,
    );

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      children: [
        _DetailStatCard(
          label: 'Học sinh',
          value: teacherClass.studentCount.toString(),
          icon: Icons.groups,
          color: Colors.blue,
        ),
        _DetailStatCard(
          label: 'Tiến độ TB',
          value: '${averageProgress.toStringAsFixed(0)}%',
          icon: Icons.insights,
          color: Colors.green,
        ),
        _DetailStatCard(
          label: 'Điểm TB',
          value: averageScore.toStringAsFixed(1),
          icon: Icons.grade,
          color: Colors.orange,
        ),
        _DetailStatCard(
          label: 'Đạt bài',
          value: passed.toString(),
          icon: Icons.verified,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStudents(
    BuildContext context,
    TeacherController teacherProvider,
    TeacherClass teacherClass,
  ) {
    final students = teacherProvider.studentsForClass(teacherClass.id);
    if (students.isEmpty) {
      return const _EmptyState(
        message: 'Lớp học chưa có học sinh nào. Bấm "Thêm học sinh" để thêm.',
      );
    }

    return Column(
      children: students
          .map(
            (student) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(student.name[0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.email,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${student.averageScore.toStringAsFixed(1)} đ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeStudent(
                            context,
                            teacherClass.id,
                            student.id,
                            student.name,
                          ),
                          tooltip: 'Xóa khỏi lớp',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: student.completionPercentage / 100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${student.completionPercentage.toStringAsFixed(0)}% hoàn thành • ${student.totalExamsTaken} bài • ${student.streakDays} ngày liên tiếp',
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRelatedExams(
    TeacherController teacherProvider,
    TeacherClass teacherClass,
  ) {
    final exams = teacherProvider.assignedExams
        .where((exam) => exam.subjectId == teacherClass.subjectId)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đề liên quan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (exams.isEmpty)
          const _EmptyState(message: 'Chưa có đề thi nào cho môn này')
        else
          ...exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.teacherQuestions),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exam.questionCount} câu • ${exam.durationMinutes} phút',
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.teacherQuestions),
          icon: const Icon(Icons.quiz),
          label: const Text('Mở ngân hàng câu hỏi'),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab(TeacherController teacherProvider) {
    if (teacherProvider.isLeaderboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final leaderboard = teacherProvider.classLeaderboard;
    if (leaderboard.isEmpty) {
      return const _EmptyState(
        message: 'Chưa có bảng xếp hạng cho lớp học này.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final item = leaderboard[index];
        final isTop3 = item.rank <= 3;
        final rankColor = item.rank == 1
            ? Colors.amber
            : item.rank == 2
            ? Colors.grey.shade400
            : item.rank == 3
            ? Colors.brown.shade300
            : Colors.grey.shade200;

        return Card(
          elevation: isTop3 ? 2 : 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rankColor,
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  color: isTop3 ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Đề đã làm: ${item.totalExamsCompleted} | Tài liệu: ${item.documentsRead}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.averageScore.toStringAsFixed(1)} đ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isTop3 ? Colors.deepOrange : Colors.black87,
                  ),
                ),
                Text(
                  '${item.overallProgressPercentage.toStringAsFixed(0)}% HT',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
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

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
