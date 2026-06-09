import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/admin_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminController>();
    final report = provider.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BÃ¡o cÃ¡o há»‡ thá»‘ng'),
        actions: [IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _TopCards(report: report),
                  const SizedBox(height: 16),
                  _SubjectScores(provider: provider),
                  const SizedBox(height: 16),
                  _DocumentStats(provider: provider),
                ],
              ),
      ),
    );
  }
}

class _TopCards extends StatelessWidget {
  final AdminReportStat? report;

  const _TopCards({required this.report});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReportCard(label: 'LÆ°á»£t lÃ m bÃ i', value: report?.totalExamAttempts.toString() ?? '0', color: Colors.blue),
      _ReportCard(label: 'Äiá»ƒm TB', value: report?.averageExamScore.toStringAsFixed(1) ?? '0.0', color: Colors.green),
      _ReportCard(label: 'Tá»· lá»‡ Ä‘áº¡t', value: '${report?.examPassRate ?? 0}%', color: Colors.orange),
      _ReportCard(label: 'NgÆ°á»i dÃ¹ng hoáº¡t Ä‘á»™ng', value: report?.activeUsersThisWeek.toString() ?? '0', color: Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _SubjectScores extends StatelessWidget {
  final AdminController provider;

  const _SubjectScores({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Äiá»ƒm trung bÃ¬nh theo mÃ´n', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...provider.subjectReports.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.12), child: Text(item.subject.name[0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.subject.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${item.documentCount} tÃ i liá»‡u â€¢ ${item.examCount} Ä‘á» â€¢ ${item.questionCount} cÃ¢u'),
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

class _DocumentStats extends StatelessWidget {
  final AdminController provider;

  const _DocumentStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thá»‘ng kÃª sá»‘ tÃ i liá»‡u', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: provider.subjectReports
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.subject.name)),
                          Text('${item.documentCount} tÃ i liá»‡u'),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
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
