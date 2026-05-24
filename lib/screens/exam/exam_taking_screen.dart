import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/exam_provider.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class ExamTakingScreen extends StatefulWidget {
  final Exam exam;

  const ExamTakingScreen({
    super.key,
    required this.exam,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  late final RepositoryService _repositoryService;
  late ExamProvider _examProvider;
  bool _isLoadingExam = true;
  bool _providerAttached = false;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _examProvider = context.read<ExamProvider>();
    if (!_providerAttached) {
      _providerAttached = true;
    }
    if (_isLoadingExam) {
      _loadExam();
    }
  }

  Future<void> _loadExam() async {
    final authProvider = context.read<AuthProvider>();
    final studentId = authProvider.currentUser?.id ?? 'student_001';
    final questions = await _repositoryService.exam.getQuestionsByExam(widget.exam.id);
    await _examProvider.startExam(
      exam: widget.exam,
      questions: questions,
      studentId: studentId,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingExam = false;
    });
  }

  Future<void> _handleSubmit(ExamProvider provider) async {
    if (provider.isSubmitted) return;

    final shouldSubmit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Nộp bài'),
              content: const Text('Bạn có chắc muốn nộp bài ngay bây giờ? Sau khi nộp sẽ không thể sửa đáp án.'),
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

    if (!shouldSubmit || !mounted) return;

    await provider.submitExam(confirmed: true);
  }

  void _goToResult() {
    if (_navigatedToResult || !mounted) return;
    _navigatedToResult = true;
    Navigator.pushReplacementNamed(context, AppRoutes.studentExamResult);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, _) {
        if (provider.isSubmitted && !_navigatedToResult) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _goToResult();
          });
        }

        if (_isLoadingExam || !provider.hasCurrentExam) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.exam.title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentQuestion = provider.currentQuestion;
        if (currentQuestion == null) {
          return const Scaffold(
            body: Center(child: Text('Không có câu hỏi nào')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.exam.title),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: provider.remainingTime.inSeconds <= 60
                          ? Colors.red.withOpacity(0.1)
                          : Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      provider.remainingTimeLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: provider.remainingTime.inSeconds <= 60 ? Colors.red : Colors.indigo,
                          ),
                    ),
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
                        final selectedId = provider.selectedOptionFor(currentQuestion.id);
                        final isSelected = selectedId == option.id;
                        final isCorrect = option.isCorrect;
                        final isLocked = provider.isSubmitted;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: isLocked
                                ? null
                                : () {
                                    provider.selectOption(currentQuestion.id, option.id);
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
                                          ? Colors.indigo
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      option.content,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                  if (isLocked && isCorrect)
                                    const Icon(Icons.check_circle, color: Colors.green),
                                  if (isLocked && isSelected && !isCorrect)
                                    const Icon(Icons.cancel, color: Colors.red),
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
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
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
                onPressed: provider.isSubmitted ? null : () => _handleSubmit(provider),
                icon: const Icon(Icons.send_rounded),
                label: Text(provider.isSubmitted ? 'Đã nộp bài' : 'Nộp bài'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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

  Widget _buildStatusBanner(BuildContext context, ExamProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.12),
            Colors.blue.withOpacity(0.08),
          ],
        ),
      ),
      child: Wrap(
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoPill(label: '${provider.currentQuestionIndex + 1}/${provider.questions.length} câu'),
          _InfoPill(label: '${provider.answeredCount} đã trả lời'),
          _InfoPill(label: provider.remainingTimeLabel),
          if (provider.isSubmitted)
            const _InfoPill(label: 'Đã nộp bài'),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context, ExamProvider provider, Question question) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBoard(BuildContext context, ExamProvider provider) {
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                        ? Colors.indigo
                        : isAnswered
                            ? Colors.green.withOpacity(0.15)
                            : Colors.white,
                    border: Border.all(
                      color: isCurrent
                          ? Colors.indigo
                          : isAnswered
                              ? Colors.green
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
                              ? Colors.green
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

  Widget _buildNavigationButtons(BuildContext context, ExamProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: provider.currentQuestionIndex == 0 || provider.isSubmitted
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
            onPressed: provider.currentQuestionIndex >= provider.questions.length - 1 || provider.isSubmitted
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
      return isSelected ? Colors.indigo : Colors.grey.shade300;
    }
    if (isCorrect) {
      return Colors.green;
    }
    if (isSelected) {
      return Colors.red;
    }
    return Colors.grey.shade300;
  }

  Color _optionBackgroundColor({
    required bool isSelected,
    required bool isCorrect,
    required bool isLocked,
  }) {
    if (!isLocked) {
      return isSelected ? Colors.indigo.withOpacity(0.08) : Colors.white;
    }
    if (isCorrect) {
      return Colors.green.withOpacity(0.08);
    }
    if (isSelected) {
      return Colors.red.withOpacity(0.08);
    }
    return Colors.white;
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}