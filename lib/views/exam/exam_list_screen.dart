import 'package:flutter/material.dart';

import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class ExamListScreen extends StatefulWidget {
  final String? initialSubjectId;

  const ExamListScreen({
    super.key,
    this.initialSubjectId,
  });

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
    final exams = await _repositoryService.exam.getAllExams();
    final subjects = await _repositoryService.subject.getAllSubjects();
    return _ExamListData(exams: exams, subjects: subjects);
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
            return Center(child: Text('Lỗi tải đề thi: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjectById = <String, Subject>{
            for (final subject in data.subjects) subject.id: subject,
          };

          final publishedExams = data.exams.where((exam) => exam.isPublished).toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
          final filteredExams = _selectedSubjectId == null
              ? publishedExams
              : publishedExams.where((exam) => exam.subjectId == _selectedSubjectId).toList();

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: data.subjects.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exam = filteredExams[index];
                          final subjectName = subjectById[exam.subjectId]?.name ?? 'Môn học';
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

class _ExamListData {
  final List<Exam> exams;
  final List<Subject> subjects;

  const _ExamListData({
    required this.exams,
    required this.subjects,
  });
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String subjectName;
  final String difficulty;
  final VoidCallback onStart;

  const _ExamCard({
    required this.exam,
    required this.subjectName,
    required this.difficulty,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subjectName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: '${exam.questionCount} câu'),
                _InfoChip(label: '${exam.durationMinutes} phút'),
                _InfoChip(label: difficulty),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              exam.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu làm bài'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
    );
  }
}
