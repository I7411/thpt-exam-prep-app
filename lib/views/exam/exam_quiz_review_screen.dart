import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../controllers/exam_controller.dart';
import '../../models.dart';

class ExamQuizReviewScreen extends StatefulWidget {
  final String examId;

  const ExamQuizReviewScreen({super.key, required this.examId});

  @override
  State<ExamQuizReviewScreen> createState() => _ExamQuizReviewScreenState();
}

class _ExamQuizReviewScreenState extends State<ExamQuizReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trắc nghiệm ôn tập'),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<ExamController>(
        builder: (context, controller, _) {
          final exam = controller.reviewExam;
          final questions = controller.reviewQuestions;

          if (controller.isReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exam == null || questions.isEmpty) {
            return const Center(
              child: Text('Đề thi chưa có câu hỏi nào để ôn tập.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: questions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _QuizReviewCard(index: index + 1, question: question);
            },
          );
        },
      ),
    );
  }
}

class _QuizReviewCard extends StatelessWidget {
  final int index;
  final Question question;

  const _QuizReviewCard({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  question.content,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...question.options.map((option) {
            final isCorrect = option.isCorrect;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: isCorrect ? AppColors.success : AppColors.line,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isCorrect ? AppColors.success : AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      option.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isCorrect ? AppColors.success : AppColors.ink,
                        fontWeight: isCorrect
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Giải thích',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  (question.explanation.trim().isEmpty)
                      ? 'Chưa có lời giải chi tiết cho câu hỏi này.'
                      : question.explanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
