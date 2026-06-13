import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';

class ExamTakingScreen extends StatefulWidget {
  final Exam exam;

  const ExamTakingScreen({super.key, required this.exam});

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  late ExamController _examProvider;
  bool _isLoadingExam = true;
  bool _providerAttached = false;
  bool _navigatedToResult = false;

  /// Local flag to prevent double-tap on submit while dialog is open
  /// or the submit flow is running.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _examProvider = context.read<ExamController>();
    if (!_providerAttached) {
      _providerAttached = true;
    }
    if (_isLoadingExam) {
      _loadExam();
    }
  }

  Future<void> _loadExam() async {
    final authProvider = context.read<AuthController>();
    final studentId = authProvider.currentUser?.id ?? 'student_001';

    await _examProvider.startExam(exam: widget.exam, studentId: studentId);
    if (!mounted) return;

    if (_examProvider.questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đề thi chưa có câu hỏi.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _isLoadingExam = false;
    });
  }

  Future<void> _handleSubmit(ExamController provider) async {
    // Prevent double-submit: check both local flag and provider flag.
    if (_isSubmitting || provider.isSubmitted || provider.isSubmitting) return;

    final totalQuestions = provider.questions.length;
    final answeredQuestions = provider.answeredCount;
    final unansweredQuestions = totalQuestions - answeredQuestions;

    String contentText = 'Bạn có chắc muốn nộp bài ngay bây giờ?';
    if (unansweredQuestions > 0) {
      contentText +=
          '\n\nBạn vẫn còn $unansweredQuestions câu hỏi chưa trả lời.';
    }
    contentText += '\n\nSau khi nộp bài, bạn sẽ xem được kết quả đánh giá.';

    debugPrint('[ExamSubmit] Confirm dialog opened');

    final shouldSubmit =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Nộp bài'),
              content: Text(contentText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Nộp bài'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSubmit) {
      debugPrint('[ExamSubmit] User cancelled');
      return;
    }
    if (!mounted) return;

    debugPrint('[ExamSubmit] User confirmed');

    // Lock UI immediately to prevent any subsequent taps.
    setState(() => _isSubmitting = true);

    try {
      // submitExam() now returns immediately after building the result and
      // calling notifyListeners(). Background I/O happens inside the controller.
      await provider.submitExam(confirmed: true);
      debugPrint(
        '[ExamSubmit] submitExam() returned — navigation will fire via addPostFrameCallback',
      );
    } catch (e, st) {
      debugPrint('[ExamSubmit] Error during submit: $e');
      debugPrint('[ExamSubmit] StackTrace: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể nộp bài. Vui lòng thử lại.'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
    // NOTE: We do NOT reset _isSubmitting to false on success because the
    // screen is replaced by pushReplacementNamed and setState would be a no-op
    // (or throw a "called after dispose" error).
  }

  void _goToResult(ExamController provider) {
    if (_navigatedToResult || !mounted) return;
    _navigatedToResult = true;
    debugPrint('[ExamSubmit] Navigating to result screen');
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.studentExamResult,
      arguments: provider.currentResult,
    );
    debugPrint('[ExamSubmit] Navigation done');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamController>(
      builder: (context, provider, _) {
        // Trigger navigation on the next frame when the exam is marked submitted.
        if (provider.isSubmitted && !_navigatedToResult) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _goToResult(provider);
          });
        }

        if (_isLoadingExam || !provider.hasCurrentExam) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.exam.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentQuestion = provider.currentQuestion;
        if (currentQuestion == null) {
          return const Scaffold(
            body: Center(child: Text('Không có câu hỏi nào')),
          );
        }

        // True when we should block the submit button.
        final submitBlocked =
            provider.isSubmitted || provider.isSubmitting || _isSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.exam.title),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: _TimerBadge(
                    label: provider.remainingTimeLabel,
                    isUrgent: provider.remainingTime.inSeconds <= 60,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildStatusBanner(context, provider),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionHeader(context, provider, currentQuestion),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion.content,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...currentQuestion.options.map((option) {
                        final selectedId = provider.selectedOptionFor(
                          currentQuestion.id,
                        );
                        final isSelected = selectedId == option.id;
                        final isCorrect = option.isCorrect;
                        final isLocked = provider.isSubmitted;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: isLocked
                                ? null
                                : () {
                                    provider.selectOption(
                                      currentQuestion.id,
                                      option.id,
                                    );
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _optionBorderColor(
                                    isSelected: isSelected,
                                    isCorrect: isCorrect,
                                    isLocked: isLocked,
                                  ),
                                  width: 1.2,
                                ),
                                color: _optionBackgroundColor(
                                  isSelected: isSelected,
                                  isCorrect: isCorrect,
                                  isLocked: isLocked,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(height: 1.4),
                                    ),
                                  ),
                                  if (isLocked && isCorrect)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                    ),
                                  if (isLocked && isSelected && !isCorrect)
                                    const Icon(
                                      Icons.cancel,
                                      color: AppColors.error,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      _buildQuestionBoard(context, provider),
                      const SizedBox(height: 16),
                      _buildNavigationButtons(context, provider),
                      const SizedBox(height: 16),
                      if (provider.isSubmitted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Text(
                            'Bài đã được nộp, không thể sửa đáp án nữa.',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                // Disable button while submitting or already submitted.
                onPressed: submitBlocked ? null : () => _handleSubmit(provider),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  provider.isSubmitted
                      ? 'Đã nộp bài'
                      : _isSubmitting
                      ? 'Đang nộp bài...'
                      : 'Nộp bài',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(BuildContext context, ExamController provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Wrap(
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoPill(
            label:
                '${provider.currentQuestionIndex + 1}/${provider.questions.length} câu',
          ),
          _InfoPill(label: '${provider.answeredCount} đã trả lời'),
          _InfoPill(label: provider.remainingTimeLabel),
          if (provider.isSubmitted) const _InfoPill(label: 'Đã nộp bài'),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(
    BuildContext context,
    ExamController provider,
    Question question,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${question.orderNumber}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Câu ${question.orderNumber}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBoard(BuildContext context, ExamController provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảng số câu',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(provider.questions.length, (index) {
              final question = provider.questions[index];
              final isCurrent = index == provider.currentQuestionIndex;
              final isAnswered = provider.isQuestionAnswered(question.id);
              return InkWell(
                onTap: () => provider.goToQuestion(index),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.primary
                        : isAnswered
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.white,
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : isAnswered
                          ? AppColors.success
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? Colors.white
                          : isAnswered
                          ? AppColors.success
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ExamController provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                provider.currentQuestionIndex == 0 || provider.isSubmitted
                ? null
                : provider.previousQuestion,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Câu trước'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                provider.currentQuestionIndex >=
                        provider.questions.length - 1 ||
                    provider.isSubmitted
                ? null
                : provider.nextQuestion,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Câu sau'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _optionBorderColor({
    required bool isSelected,
    required bool isCorrect,
    required bool isLocked,
  }) {
    if (!isLocked) {
      return isSelected ? AppColors.primary : Colors.grey.shade300;
    }
    if (isCorrect) {
      return AppColors.success;
    }
    if (isSelected) {
      return AppColors.error;
    }
    return Colors.grey.shade300;
  }

  Color _optionBackgroundColor({
    required bool isSelected,
    required bool isCorrect,
    required bool isLocked,
  }) {
    if (!isLocked) {
      return isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.white;
    }
    if (isCorrect) {
      return AppColors.success.withValues(alpha: 0.08);
    }
    if (isSelected) {
      return AppColors.error.withValues(alpha: 0.08);
    }
    return Colors.white;
  }
}

/// Timer badge extracted as a const-friendly widget to avoid full rebuilds.
class _TimerBadge extends StatelessWidget {
  final String label;
  final bool isUrgent;

  const _TimerBadge({required this.label, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isUrgent ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
