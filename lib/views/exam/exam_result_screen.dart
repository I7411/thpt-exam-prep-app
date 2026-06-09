import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/exam_provider.dart';

class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamController>(
      builder: (context, provider, _) {
        final result = provider.currentResult;
        if (result == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kết quả thi'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có kết quả thi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.studentExams);
                    },
                    child: const Text('Về danh sách đề thi'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kết quả thi'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(context, result),
                    const SizedBox(height: 16),
                    _buildStatsGrid(context, result),
                    const SizedBox(height: 24),
                    Text(
                      'Chi tiết câu hỏi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...result.questions.map((question) {
                      final selectedId = result.selectedOptionFor(question.id);
                      final selectedOption = _findOption(question, selectedId);
                      final correctOption = question.options.firstWhere((option) => option.isCorrect);
                      final isCorrect = selectedOption != null && selectedOption.id == correctOption.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(
                          question: question,
                          selectedOption: selectedOption,
                          correctOption: correctOption,
                          isCorrect: isCorrect,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.studentExams);
                        },
                        child: const Text('Làm đề khác'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
                        },
                        child: const Text('Về trang chủ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, ExamResultData result) {
    final passed = result.score >= result.exam.passingScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: passed
              ? [Colors.green.shade500, Colors.green.shade300]
              : [Colors.orange.shade500, Colors.deepOrange.shade300],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.exam.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            passed ? 'Đạt yêu cầu' : 'Chưa đạt yêu cầu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '${result.score.toStringAsFixed(1)} điểm',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thời gian làm bài: ${_formatDuration(result.timeSpent)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ExamResultData result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _ResultStatCard(label: 'Đúng', value: '${result.correctCount}', color: Colors.green),
            _ResultStatCard(label: 'Sai', value: '${result.wrongCount}', color: Colors.red),
            _ResultStatCard(label: 'Hoàn thành', value: '${result.completionPercentage.toStringAsFixed(0)}%', color: Colors.indigo),
            _ResultStatCard(label: 'Thời gian', value: _formatDuration(result.timeSpent), color: Colors.orange),
          ],
        );
      },
    );
  }

  AnswerOption? _findOption(Question question, String? optionId) {
    if (optionId == null || optionId.isEmpty) {
      return null;
    }
    for (final option in question.options) {
      if (option.id == optionId) {
        return option;
      }
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Question question;
  final AnswerOption? selectedOption;
  final AnswerOption correctOption;
  final bool isCorrect;

  const _ReviewCard({
    required this.question,
    required this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: isCorrect ? Colors.green.withOpacity(0.25) : Colors.red.withOpacity(0.25),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          'Câu ${question.orderNumber}: ${question.content}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LabelChip(
                label: 'Đã chọn: ${selectedOption?.label ?? 'ChÆ°a chá»n'}',
                color: selectedOption == null ? Colors.grey : (isCorrect ? Colors.green : Colors.red),
              ),
              _LabelChip(
                label: 'Đáp án đúng: ${correctOption.label}',
                color: Colors.green,
              ),
            ],
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lời giải',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LabelChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
