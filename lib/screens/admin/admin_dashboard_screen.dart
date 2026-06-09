import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/admin_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

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
    await context.read<AdminProvider>().loadData();
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final report = provider.report;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleLogout();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
      _StatItem('Tổng user', report?.totalUsers.toString() ?? '0', Icons.people, Colors.blue),
      _StatItem('Tổng học sinh', report?.totalStudents.toString() ?? '0', Icons.school, Colors.green),
      _StatItem('Tổng giáo viên', report?.totalTeachers.toString() ?? '0', Icons.person_pin, Colors.orange),
      _StatItem('Tổng tài liệu', report?.totalDocuments.toString() ?? '0', Icons.description, Colors.purple),
      _StatItem('Tổng đề thi', report?.totalExams.toString() ?? '0', Icons.assignment, Colors.red),
      _StatItem('Số lượt làm bài', report?.totalExamAttempts.toString() ?? '0', Icons.bar_chart, Colors.teal),
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
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem('Người dùng', Icons.people, AppRoutes.adminUsers, Colors.blue),
      _ActionItem('Tài liệu', Icons.description, AppRoutes.adminDocuments, Colors.purple),
      _ActionItem('Đề & câu hỏi', Icons.quiz, AppRoutes.adminExams, Colors.orange),
      _ActionItem('Báo cáo', Icons.assessment, AppRoutes.adminReports, Colors.green),
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
              onTap: () => Navigator.pushNamed(context, item.route),
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
  final AdminProvider provider;

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