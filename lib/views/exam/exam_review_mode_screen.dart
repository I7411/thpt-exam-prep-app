import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../controllers/exam_controller.dart';
import '../../core/routes/app_routes.dart';

class ExamReviewModeScreen extends StatefulWidget {
  final String examId;

  const ExamReviewModeScreen({super.key, required this.examId});

  @override
  State<ExamReviewModeScreen> createState() => _ExamReviewModeScreenState();
}

class _ExamReviewModeScreenState extends State<ExamReviewModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamController>().loadExamReview(widget.examId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ôn tập đề thi'),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<ExamController>(
        builder: (context, controller, _) {
          if (controller.isReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.reviewErrorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    controller.reviewErrorMessage!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      controller.loadExamReview(widget.examId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final exam = controller.reviewExam;
          if (exam == null) {
            return const Center(
              child: Text('Không tìm thấy đề thi để ôn tập.'),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadius.panel),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                exam.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.list_alt_rounded,
                              label: '${exam.questionCount} câu',
                            ),
                            _InfoChip(
                              icon: Icons.timer_rounded,
                              label: '${exam.durationMinutes} phút',
                            ),
                            _InfoChip(
                              icon: Icons.stars_rounded,
                              label: 'Đạt: ${exam.passingScore}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Chọn chế độ ôn tập',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mode 1: Quiz Review
                  _ModeCard(
                    title: 'Trắc nghiệm ôn tập',
                    description:
                        'Ôn lại kiến thức bằng các câu hỏi trắc nghiệm trong đề.',
                    icon: Icons.check_circle_outline_rounded,
                    colors: const [Color(0xFF4ADE80), Color(0xFF10B981)],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentExamQuizReview,
                        arguments: widget.examId,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mode 2: Blast Game
                  _ModeCard(
                    title: 'Blast Game',
                    description:
                        'Ghép thuật ngữ với định nghĩa đúng. Bắn hạ tiểu hành tinh đúng trước khi hết thời gian.',
                    icon: Icons.rocket_launch_rounded,
                    colors: const [Color(0xFF818CF8), Color(0xFF6366F1)],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentExamBlastGame,
                        arguments: widget.examId,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Mode 3: Block Puzzle
                  _ModeCard(
                    title: 'Khối hộp',
                    description:
                        'Trả lời câu hỏi để nhận khối hình, lấp đầy hàng hoặc cột để ghi điểm.',
                    icon: Icons.extension_rounded,
                    colors: const [Color(0xFFF472B6), Color(0xFFE11D48)],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentExamBlockPuzzleGame,
                        arguments: widget.examId,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors[1],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.line,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
