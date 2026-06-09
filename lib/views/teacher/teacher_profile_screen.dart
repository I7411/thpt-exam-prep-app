import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/providers/teacher_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
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

  Future<void> _logout() async {
    await context.read<AuthController>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();
    final teacherProvider = context.watch<TeacherController>();
    final teacher = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Há»“ sÆ¡ giÃ¡o viÃªn'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
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
                  _buildHeader(teacher),
                  const SizedBox(height: 16),
                  _buildStats(teacherProvider),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'ThÃ´ng tin tÃ i khoáº£n',
                    children: [
                      _InfoRow(label: 'Email', value: teacher?.email ?? '-'),
                      _InfoRow(label: 'TrÆ°á»ng', value: teacher?.schoolName ?? '-'),
                      _InfoRow(label: 'Vai trÃ²', value: teacher?.role.getDisplayName() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Thao tÃ¡c nhanh',
                    children: [
                      _ActionRow(
                        icon: Icons.class_,
                        title: 'Danh sÃ¡ch lá»›p',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.teacherClasses),
                      ),
                      _ActionRow(
                        icon: Icons.quiz,
                        title: 'NgÃ¢n hÃ ng cÃ¢u há»i',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.teacherQuestions),
                      ),
                      _ActionRow(
                        icon: Icons.event_note,
                        title: 'Lá»‹ch giáº£ng dáº¡y',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.teacherSchedule),
                      ),
                      _ActionRow(
                        icon: Icons.logout,
                        title: 'ÄÄƒng xuáº¥t',
                        onTap: _logout,
                        destructive: true,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(dynamic teacher) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.16),
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
                  teacher?.bio ?? 'Quáº£n lÃ½ lá»›p vÃ  Ä‘á» thi',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(TeacherController teacherProvider) {
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
        _ProfileStat(label: 'Lá»›p', value: teacherProvider.classes.length.toString(), color: Colors.blue),
        _ProfileStat(label: 'Há»c sinh', value: teacherProvider.totalStudents.toString(), color: Colors.green),
        _ProfileStat(label: 'Äá»', value: teacherProvider.assignedExams.length.toString(), color: Colors.orange),
        _ProfileStat(label: 'Tiáº¿n Ä‘á»™', value: '${teacherProvider.averageProgress.toStringAsFixed(0)}%', color: Colors.purple),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProfileStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({required this.icon, required this.title, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : Colors.blueGrey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
