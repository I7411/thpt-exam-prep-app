import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';
import 'package:thpt_exam_prep_app/controllers/progress_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

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
            title: const Text('Tiến độ học tập'),
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
                  'Tiến độ theo môn',
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
                    title: 'Chưa có tiến độ',
                    message: 'Hãy làm một vài đề thi để hệ thống tạo dữ liệu tiến độ.',
                  ),
                const SizedBox(height: 24),
                Text(
                  'Lịch sử bài làm',
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
                    title: 'Chưa có lịch sử bài làm',
                    message: 'Sau khi nộp bài thi thử, lịch sử sẽ xuất hiện ở đây.',
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
              label: 'Tổng đề đã làm',
              value: '${provider.totalExamsTaken}',
              icon: Icons.quiz,
              color: AppColors.primary,
            ),
            _SummaryCard(
              label: 'Điểm trung bình',
              value: provider.averageScore.toStringAsFixed(1),
              icon: Icons.star,
              color: AppColors.accent,
            ),
            // Uses the source-of-truth count from learned_materials collection,
            // NOT from ProgressStat.totalDocumentsRead (always 0).
            _SummaryCard(
              label: 'Tài liệu đã đọc',
              value: '${provider.totalLearnedDocuments}',
              icon: Icons.description,
              color: AppColors.secondary,
            ),
            _SummaryCard(
              label: 'Môn đang có',
              value: '${provider.subjectProgress.length}',
              icon: Icons.menu_book,
              color: AppColors.success,
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
        borderRadius: BorderRadius.circular(AppRadius.panel),
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.success.withOpacity(0.08)],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhận xét nhanh',
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
                ? 'Tổng thể đang ổn, duy trì nhịp làm đề đều để tăng độ ổn định.'
                : 'Cần làm thêm đề và ôn lại các môn điểm thấp để kéo điểm trung bình lên.',
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(AppRadius.card),
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
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
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
                      color: AppColors.primary,
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
              Text('Đề đã làm: ${progress.totalExamsTaken}'),
              Text('Tài liệu: ${progress.totalDocumentsRead}'),
              Text('Điểm TB: ${progress.averageScore.toStringAsFixed(1)}'),
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
                label: passed ? 'Đạt' : 'Chưa đạt',
                color: passed ? AppColors.success : AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Điểm: ${result.score.toStringAsFixed(1)} | Đúng: ${result.correctCount} | Sai: ${result.wrongCount}',
          ),
          const SizedBox(height: 4),
          Text(
            'Thời gian: ${_formatDuration(result.timeSpent)} | Hoàn thành: ${result.completionPercentage.toStringAsFixed(0)}%',
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
