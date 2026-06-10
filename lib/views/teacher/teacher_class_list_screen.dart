import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/controllers/teacher_controller.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class TeacherClassListScreen extends StatefulWidget {
  const TeacherClassListScreen({super.key});

  @override
  State<TeacherClassListScreen> createState() => _TeacherClassListScreenState();
}

class _TeacherClassListScreenState extends State<TeacherClassListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthController>();
    await context.read<TeacherController>().ensureLoaded(authProvider.currentUser, force: true);
  }

  void _showCreateClassDialog(BuildContext context) {
    final classNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final teacherProvider = context.read<TeacherController>();
    String? selectedSubjectId = teacherProvider.subjects.isNotEmpty ? teacherProvider.subjects.first.id : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tạo lớp mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên lớp',
                        hintText: 'VD: 12A1',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Môn học'),
                      items: teacherProvider.subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject.id,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSubjectId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả lớp',
                        hintText: 'VD: Lớp ôn thi THPT Quốc gia',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    final className = classNameController.text.trim();
                    final desc = descriptionController.text.trim();
                    final subjectId = selectedSubjectId;

                    if (className.isEmpty || subjectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đầy đủ tên lớp và môn học.')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    final success = await teacherProvider.createNewClass(
                      className: className,
                      subjectId: subjectId,
                      description: desc,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Đã tạo lớp $className thành công.' : 'Lỗi khi tạo lớp học.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Tạo'),
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
    final teacherProvider = context.watch<TeacherController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lớp'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context),
        label: const Text('Tạo lớp mới'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: teacherProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummary(teacherProvider),
                  const SizedBox(height: 16),
                  if (teacherProvider.classes.isEmpty)
                    const _EmptyState(message: 'Chưa có lớp nào được gán cho giáo viên này')
                  else
                    ...teacherProvider.classes.map(
                      (teacherClass) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ClassCard(
                          teacherClass: teacherClass,
                          subjectName: teacherProvider.getSubjectName(teacherClass.subjectId),
                          sampleStudents: teacherProvider.studentsForClass(teacherClass.id),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.teacherClassDetail,
                            arguments: teacherClass.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummary(TeacherController teacherProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(label: 'Lớp', value: teacherProvider.classes.length.toString()),
          ),
          Expanded(
            child: _SummaryTile(label: 'Học sinh', value: teacherProvider.totalStudents.toString()),
          ),
          Expanded(
            child: _SummaryTile(label: 'Tiến độ TB', value: '${teacherProvider.averageProgress.toStringAsFixed(0)}%'),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherClass teacherClass;
  final String subjectName;
  final List<TeacherStudentSummary> sampleStudents;
  final VoidCallback onTap;

  const _ClassCard({
    required this.teacherClass,
    required this.subjectName,
    required this.sampleStudents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topStudents = sampleStudents.take(3).toList();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    teacherClass.className,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 8),
            Text(subjectName, style: TextStyle(color: Colors.blueGrey.shade700)),
            const SizedBox(height: 8),
            Text(teacherClass.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag(label: '${teacherClass.studentCount} học sinh'),
                _Tag(label: '${sampleStudents.length} hồ sơ mẫu'),
              ],
            ),
            if (topStudents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Học sinh tiêu biểu', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...topStudents.map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        child: Text(student.name[0].toUpperCase()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(student.name)),
                      Text('${student.averageScore.toStringAsFixed(1)} điểm'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E5AA8))),
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
