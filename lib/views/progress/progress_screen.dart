import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/exam_provider.dart';
import 'package:thpt_exam_prep_app/providers/progress_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final authProvider = context.read<AuthController>();
    final studentId = authProvider.currentUser?.id ?? 'student_001';
    context.read<ProgressController>().initialize(studentId);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressController>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.subjectProgress.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tiáº¿n Ä‘á»™ há»c táº­p'),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshExamHistory,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryGrid(context, provider),
                const SizedBox(height: 24),
                _buildStrengthCard(context, provider),
                const SizedBox(height: 24),
                Text(
                  'Tiáº¿n Ä‘á»™ theo mÃ´n',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...provider.subjectProgress.map((progress) {
                  final subjectName = provider.subjectName(progress.subjectId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubjectProgressCard(
                      subjectName: subjectName,
                      progress: progress,
                    ),
                  );
                }),
                if (provider.subjectProgress.isEmpty)
                  _EmptyState(
                    icon: Icons.timeline,
                    title: 'ChÆ°a cÃ³ tiáº¿n Ä‘á»™',
                    message: 'HÃ£y lÃ m má»™t vÃ i Ä‘á» thi Ä‘á»ƒ há»‡ thá»‘ng táº¡o dá»¯ liá»‡u tiáº¿n Ä‘á»™.',
                  ),
                const SizedBox(height: 24),
                Text(
                  'Lá»‹ch sá»­ bÃ i lÃ m',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...provider.recentHistory().map((result) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HistoryCard(result: result),
                  );
                }),
                if (provider.recentHistory().isEmpty)
                  _EmptyState(
                    icon: Icons.history,
                    title: 'ChÆ°a cÃ³ lá»‹ch sá»­ bÃ i lÃ m',
                    message: 'Sau khi ná»™p bÃ i thi thá»­, lá»‹ch sá»­ sáº½ xuáº¥t hiá»‡n á»Ÿ Ä‘Ã¢y.',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(BuildContext context, ProgressController provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _SummaryCard(
              label: 'Tá»•ng Ä‘á» Ä‘Ã£ lÃ m',
              value: '${provider.totalExamsTaken}',
              icon: Icons.quiz,
              color: Colors.indigo,
            ),
            _SummaryCard(
              label: 'Äiá»ƒm trung bÃ¬nh',
              value: provider.averageScore.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.orange,
            ),
            _SummaryCard(
              label: 'TÃ i liá»‡u Ä‘Ã£ Ä‘á»c',
              value: '${_estimateDocumentsFromProgress(provider)}',
              icon: Icons.description,
              color: Colors.blue,
            ),
            _SummaryCard(
              label: 'MÃ´n Ä‘ang cÃ³',
              value: '${provider.subjectProgress.length}',
              icon: Icons.menu_book,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrengthCard(BuildContext context, ProgressController provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.indigo.withOpacity(0.1), Colors.green.withOpacity(0.08)],
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nháº­n xÃ©t nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(provider.strongestSubjectLabel),
          const SizedBox(height: 6),
          Text(provider.weakestSubjectLabel),
          const SizedBox(height: 6),
          Text(
            provider.averageScore >= 7.5
                ? 'Tá»•ng thá»ƒ Ä‘ang á»•n, duy trÃ¬ nhá»‹p lÃ m Ä‘á» Ä‘á»u Ä‘á»ƒ tÄƒng Ä‘á»™ á»•n Ä‘á»‹nh.'
                : 'Cáº§n lÃ m thÃªm Ä‘á» vÃ  Ã´n láº¡i cÃ¡c mÃ´n Ä‘iá»ƒm tháº¥p Ä‘á»ƒ kÃ©o Ä‘iá»ƒm trung bÃ¬nh lÃªn.',
          ),
        ],
      ),
    );
  }

  int _estimateDocumentsFromProgress(ProgressController provider) {
    return provider.subjectProgress.fold(0, (total, progress) => total + progress.totalDocumentsRead);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final String subjectName;
  final ProgressStat progress;

  const _SubjectProgressCard({
    required this.subjectName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subjectName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${progress.completionPercentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.completionPercentage / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('Äá» Ä‘Ã£ lÃ m: ${progress.totalExamsTaken}'),
              Text('TÃ i liá»‡u: ${progress.totalDocumentsRead}'),
              Text('Äiá»ƒm TB: ${progress.averageScore.toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ExamResultData result;

  const _HistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final passed = result.score >= result.exam.passingScore;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.exam.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _StatusPill(
                label: passed ? 'Äáº¡t' : 'ChÆ°a Ä‘áº¡t',
                color: passed ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Äiá»ƒm: ${result.score.toStringAsFixed(1)} | ÄÃºng: ${result.correctCount} | Sai: ${result.wrongCount}',
          ),
          const SizedBox(height: 4),
          Text(
            'Thá»i gian: ${_formatDuration(result.timeSpent)} | HoÃ n thÃ nh: ${result.completionPercentage.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }
}
