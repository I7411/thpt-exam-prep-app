import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/providers/teacher_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';
import 'package:thpt_exam_prep_app/models.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final String? classId;

  const TeacherClassDetailScreen({super.key, this.classId});

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
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
    await context.read<TeacherController>().ensureLoaded(authProvider.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherController>();
    final teacherClass = widget.classId == null ? teacherProvider.classes.firstOrNull : teacherProvider.classById(widget.classId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiáº¿t lá»›p'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: teacherProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : teacherClass == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: const [
                      _EmptyState(message: 'KhÃ´ng tÃ¬m tháº¥y lá»›p há»c phÃ¹ há»£p'),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(context, teacherProvider, teacherClass),
                      const SizedBox(height: 16),
                      _buildStats(teacherProvider, teacherClass),
                      const SizedBox(height: 16),
                      _buildStudents(teacherProvider, teacherClass),
                      const SizedBox(height: 16),
                      _buildRelatedExams(teacherProvider, teacherClass),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TeacherController teacherProvider, TeacherClass teacherClass) {
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
          Text(teacherClass.className, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subjectName, style: TextStyle(color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 8),
          Text(teacherClass.description, style: TextStyle(color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildStats(TeacherController teacherProvider, TeacherClass teacherClass) {
    final students = teacherProvider.studentsForClass(teacherClass.id);
    final averageScore = students.isEmpty ? 0.0 : students.map((student) => student.averageScore).reduce((left, right) => left + right) / students.length;
    final averageProgress = students.isEmpty ? 0.0 : students.map((student) => student.completionPercentage).reduce((left, right) => left + right) / students.length;
    final passed = students.fold<int>(0, (sum, student) => sum + student.examsPassed);

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
        _DetailStatCard(label: 'Há»c sinh', value: teacherClass.studentCount.toString(), icon: Icons.groups, color: Colors.blue),
        _DetailStatCard(label: 'Tiáº¿n Ä‘á»™ TB', value: '${averageProgress.toStringAsFixed(0)}%', icon: Icons.insights, color: Colors.green),
        _DetailStatCard(label: 'Äiá»ƒm TB', value: averageScore.toStringAsFixed(1), icon: Icons.grade, color: Colors.orange),
        _DetailStatCard(label: 'Äáº¡t bÃ i', value: passed.toString(), icon: Icons.verified, color: Colors.purple),
      ],
    );
  }

  Widget _buildStudents(TeacherController teacherProvider, TeacherClass teacherClass) {
    final students = teacherProvider.studentsForClass(teacherClass.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Há»c sinh tiÃªu biá»ƒu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (students.isEmpty)
          const _EmptyState(message: 'ChÆ°a cÃ³ dá»¯ liá»‡u há»c sinh máº«u')
        else
          ...students.map(
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
                        CircleAvatar(child: Text(student.name[0].toUpperCase())),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(student.email, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${student.averageScore.toStringAsFixed(1)} Ä‘', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: student.completionPercentage / 100),
                    const SizedBox(height: 8),
                    Text('${student.completionPercentage.toStringAsFixed(0)}% hoÃ n thÃ nh â€¢ ${student.totalExamsTaken} bÃ i â€¢ ${student.streakDays} ngÃ y liÃªn tiáº¿p'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedExams(TeacherController teacherProvider, TeacherClass teacherClass) {
    final exams = teacherProvider.assignedExams.where((exam) => exam.subjectId == teacherClass.subjectId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Äá» liÃªn quan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (exams.isEmpty)
          const _EmptyState(message: 'ChÆ°a cÃ³ Ä‘á» thi nÃ o cho mÃ´n nÃ y')
        else
          ...exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.pushNamed(context, AppRoutes.teacherQuestions),
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
                            Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${exam.questionCount} cÃ¢u â€¢ ${exam.durationMinutes} phÃºt'),
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
          onPressed: () => Navigator.pushNamed(context, AppRoutes.teacherQuestions),
          icon: const Icon(Icons.quiz),
          label: const Text('Má»Ÿ ngÃ¢n hÃ ng cÃ¢u há»i'),
        ),
      ],
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DetailStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
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
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
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
