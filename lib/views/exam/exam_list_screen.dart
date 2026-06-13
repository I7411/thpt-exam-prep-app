import 'package:flutter/material.dart';

import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';

class ExamListScreen extends StatefulWidget {
  final String? initialSubjectId;

  const ExamListScreen({super.key, this.initialSubjectId});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  late final RepositoryService _repositoryService;
  late Future<_ExamListData> _dataFuture;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _selectedSubjectId = widget.initialSubjectId;
    _dataFuture = _loadData();
  }

  Future<_ExamListData> _loadData() async {
    final examsFuture = _repositoryService.exam.getAllExams().timeout(
      const Duration(seconds: 12),
    );
    final subjectsFuture = _repositoryService.subject.getAllSubjects().timeout(
      const Duration(seconds: 12),
    );
    final exams = (await examsFuture).take(20).toList();
    final subjects = await subjectsFuture;
    return _ExamListData(exams: exams, subjects: subjects);
  }

  void _retryLoad() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thi thử'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<_ExamListData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Lỗi tải đề thi: ${snapshot.error}');
            return _ErrorState(onRetry: _retryLoad);
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjectById = <String, Subject>{
            for (final subject in data.subjects) subject.id: subject,
          };

          final publishedExams =
              data.exams.where((exam) => exam.isPublished).toList()..sort(
                (left, right) => right.createdAt.compareTo(left.createdAt),
              );
          final filteredExams = _selectedSubjectId == null
              ? publishedExams
              : publishedExams
                    .where((exam) => exam.subjectId == _selectedSubjectId)
                    .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.warm,
                    borderRadius: BorderRadius.circular(AppRadius.panel),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Luyện đề theo thời gian thật để quen nhịp thi.',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: data.subjects.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedSubjectId == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedSubjectId = null;
                          });
                        },
                      );
                    }

                    final subject = data.subjects[index - 1];
                    return FilterChip(
                      label: Text(subject.name),
                      selected: _selectedSubjectId == subject.id,
                      onSelected: (_) {
                        setState(() {
                          _selectedSubjectId = subject.id;
                        });
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: filteredExams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có đề thi phù hợp',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredExams.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exam = filteredExams[index];
                          final subjectName =
                              subjectById[exam.subjectId]?.name ?? 'Môn học';
                          return _ExamCard(
                            exam: exam,
                            subjectName: subjectName,
                            difficulty: _estimateDifficulty(exam),
                            onStart: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.studentExamTaking,
                                arguments: exam,
                              );
                            },
                            onReview: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.studentExamReviewMode,
                                arguments: exam.id,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _estimateDifficulty(Exam exam) {
    if (exam.durationMinutes <= 60 || exam.questionCount <= 4) {
      return 'Dễ';
    }
    if (exam.durationMinutes <= 90) {
      return 'Trung bình';
    }
    return 'Khó';
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lỗi tải đề thi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Không thể tải danh sách đề thi. Vui lòng kiểm tra mạng và thử lại.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamListData {
  final List<Exam> exams;
  final List<Subject> subjects;

  const _ExamListData({required this.exams, required this.subjects});
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String subjectName;
  final String difficulty;
  final VoidCallback onStart;
  final VoidCallback onReview;

  const _ExamCard({
    required this.exam,
    required this.subjectName,
    required this.difficulty,
    required this.onStart,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _difficultyColor(difficulty);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: difficultyColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.quiz_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subjectName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: '${exam.questionCount} câu',
                color: AppColors.primary,
              ),
              _InfoChip(
                label: '${exam.durationMinutes} phút',
                color: AppColors.secondary,
              ),
              _InfoChip(label: difficulty, color: difficultyColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            exam.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.psychology_rounded),
                  label: const Text('Ôn tập'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Làm bài'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Dễ':
        return AppColors.success;
      case 'Trung bình':
        return AppColors.accent;
      default:
        return AppColors.error;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
      side: BorderSide.none,
    );
  }
}
