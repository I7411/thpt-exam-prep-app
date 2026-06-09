import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/providers/teacher_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthController>();
    final teacherProvider = context.read<TeacherController>();
    await teacherProvider.ensureLoaded(authProvider.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();

    return Consumer<TeacherController>(
      builder: (context, teacherProvider, _) {
        final teacher = authProvider.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: Text('Xin chÃ o, ${teacher?.fullName ?? 'GiÃ¡o viÃªn'}'),
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
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(context, teacher, teacherProvider),
                      const SizedBox(height: 16),
                      _buildStatsGrid(teacherProvider),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      const SizedBox(height: 16),
                      _buildClassPreview(context, teacherProvider),
                      const SizedBox(height: 16),
                      _buildSchedulePreview(teacherProvider),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, dynamic teacher, TeacherController teacherProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  (teacher?.fullName ?? 'G')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher?.fullName ?? 'GiÃ¡o viÃªn',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher?.bio ?? 'Quáº£n lÃ½ lá»›p há»c, Ä‘á» thi vÃ  lá»‹ch dáº¡y',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${teacherProvider.classes.length} lá»›p â€¢ ${teacherProvider.totalStudents} há»c sinh â€¢ ${teacherProvider.assignedExams.length} Ä‘á»',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(TeacherController teacherProvider) {
    final items = [
      _StatItem('Lá»›p phá»¥ trÃ¡ch', teacherProvider.classes.length.toString(), Icons.class_, Colors.blue),
      _StatItem('Há»c sinh', teacherProvider.totalStudents.toString(), Icons.groups, Colors.green),
      _StatItem('Äá» Ä‘Ã£ giao', teacherProvider.assignedExams.length.toString(), Icons.assignment, Colors.orange),
      _StatItem('Tiáº¿n Ä‘á»™ TB', '${teacherProvider.averageProgress.toStringAsFixed(0)}%', Icons.insights, Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _StatCard(item: item);
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem('Danh sÃ¡ch lá»›p', Icons.class_, AppRoutes.teacherClasses, Colors.blue),
      _ActionItem('NgÃ¢n hÃ ng cÃ¢u há»i', Icons.quiz, AppRoutes.teacherQuestions, Colors.orange),
      _ActionItem('Lá»‹ch giáº£ng dáº¡y', Icons.event_note, AppRoutes.teacherSchedule, Colors.green),
      _ActionItem('Há»“ sÆ¡', Icons.person, AppRoutes.teacherProfile, Colors.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thao tÃ¡c nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pushNamed(context, action.route),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: action.color.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: action.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassPreview(BuildContext context, TeacherController teacherProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lá»›p Ä‘ang phá»¥ trÃ¡ch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.teacherClasses),
              child: const Text('Xem táº¥t cáº£'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (teacherProvider.classes.isEmpty)
          const _EmptyState(message: 'ChÆ°a cÃ³ lá»›p nÃ o Ä‘Æ°á»£c gÃ¡n cho giÃ¡o viÃªn nÃ y')
        else
          ...teacherProvider.classes.take(2).map((teacherClass) {
            final subjectName = teacherProvider.getSubjectName(teacherClass.subjectId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.teacherClassDetail,
                  arguments: teacherClass.id,
                ),
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
                          Text(teacherClass.className, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(subjectName, style: TextStyle(color: Colors.blueGrey.shade700)),
                      const SizedBox(height: 8),
                      Text(teacherClass.description),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Chip(label: '${teacherClass.studentCount} há»c sinh', color: Colors.blue),
                          const SizedBox(width: 8),
                          _Chip(label: '${teacherProvider.studentsForClass(teacherClass.id).length} máº«u hiá»ƒn thá»‹', color: Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSchedulePreview(TeacherController teacherProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lá»‹ch sáº¯p tá»›i', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (teacherProvider.schedule.isEmpty)
          const _EmptyState(message: 'ChÆ°a cÃ³ lá»‹ch dáº¡y hoáº·c lá»‹ch giao Ä‘á»')
        else
          ...teacherProvider.schedule.take(3).map(
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
                        Container(
                          width: 44,
                          height: 44,
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
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(item.subtitle, style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.startTime.day.toString().padLeft(2, '0')}/${item.startTime.month.toString().padLeft(2, '0')}\n${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
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

class _ActionItem {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _ActionItem(this.title, this.icon, this.route, this.color);
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
