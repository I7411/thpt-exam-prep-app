import 'package:flutter/foundation.dart';

import 'package:thpt_exam_prep_app/data/local/app_database.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers/exam_provider.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class ProgressProvider extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();
  final AppLocalRepository _localRepository = AppLocalRepository.instance;

  bool _isLoading = false;
  String? _studentId;
  List<ProgressStat> _subjectProgress = <ProgressStat>[];
  List<ExamResultData> _examHistory = <ExamResultData>[];
  List<Subject> _subjects = <Subject>[];

  bool get isLoading => _isLoading;
  String? get studentId => _studentId;
  List<ProgressStat> get subjectProgress => List.unmodifiable(_subjectProgress);
  List<ExamResultData> get examHistory => List.unmodifiable(_examHistory);
  List<Subject> get subjects => List.unmodifiable(_subjects);

  int get totalExamsTaken => _subjectProgress.fold(0, (total, item) => total + item.totalExamsTaken);

  int get totalDocumentsRead => _subjectProgress.fold(0, (total, item) => total + item.totalDocumentsRead);

  double get averageScore {
    var weightedScore = 0.0;
    var totalWeight = 0;

    for (final progress in _subjectProgress) {
      weightedScore += progress.averageScore * progress.totalExamsTaken;
      totalWeight += progress.totalExamsTaken;
    }

    if (totalWeight == 0) return 0;
    return weightedScore / totalWeight;
  }

  Future<void> initialize(String studentId, {bool force = false}) async {
    if (!force && _studentId == studentId && _subjectProgress.isNotEmpty) {
      return;
    }

    _studentId = studentId;
    _isLoading = true;
    notifyListeners();

    final subjectFuture = _repositoryService.subject.getAllSubjects();
    final localProgressFuture = _localRepository.getProgressStats(studentId);
    final localHistoryFuture = _localRepository.getExamHistory(studentId);

    _subjects = await subjectFuture;

    final localProgress = await localProgressFuture;
    if (localProgress.isNotEmpty) {
      _subjectProgress = localProgress;
    } else {
      final mockProgress = await _repositoryService.progress.getProgressByStudent(studentId);
      _subjectProgress = mockProgress.isNotEmpty ? mockProgress : _buildMockProgress(studentId);
    }

    final localHistory = await localHistoryFuture;
    if (localHistory.isNotEmpty) {
      _examHistory = localHistory;
    } else {
      _examHistory = await _buildMockHistory(studentId);
    }

    _isLoading = false;
    notifyListeners();
  }

  ProgressStat? progressForSubject(String subjectId) {
    for (final progress in _subjectProgress) {
      if (progress.subjectId == subjectId) {
        return progress;
      }
    }
    return null;
  }

  String subjectName(String subjectId) {
    for (final subject in _subjects) {
      if (subject.id == subjectId) {
        return subject.name;
      }
    }
    return 'Môn học';
  }

  String get strongestSubjectLabel {
    if (_subjectProgress.isEmpty) return 'Chưa có dữ liệu mạnh nổi bật';

    final strongest = _subjectProgress.reduce((left, right) {
      return left.averageScore >= right.averageScore ? left : right;
    });
    return '${subjectName(strongest.subjectId)} đang là môn mạnh nhất (${strongest.averageScore.toStringAsFixed(1)} điểm)';
  }

  String get weakestSubjectLabel {
    if (_subjectProgress.isEmpty) return 'Chưa có dữ liệu để xác định môn yếu';

    final weakest = _subjectProgress.reduce((left, right) {
      return left.averageScore <= right.averageScore ? left : right;
    });
    return '${subjectName(weakest.subjectId)} cần ưu tiên cải thiện (${weakest.averageScore.toStringAsFixed(1)} điểm)';
  }

  List<ExamResultData> recentHistory({int limit = 20}) {
    final history = List<ExamResultData>.from(_examHistory)
      ..sort((left, right) => right.attempt.startedAt.compareTo(left.attempt.startedAt));
    return history.take(limit).toList();
  }

  Future<void> refreshExamHistory() async {
    if (_studentId == null) return;

    await initialize(_studentId!, force: true);
    notifyListeners();
  }

  List<ProgressStat> _buildMockProgress(String studentId) {
    final fallback = MockProgressData.progressStats.where((progress) => progress.studentId == studentId).toList();
    return fallback.isNotEmpty ? fallback : MockProgressData.progressStats;
  }

  Future<List<ExamResultData>> _buildMockHistory(String studentId) async {
    final exams = await _repositoryService.exam.getAllExams();
    final results = <ExamResultData>[];

    for (final exam in exams.take(3)) {
      final questions = await _repositoryService.exam.getQuestionsByExam(exam.id);
      if (questions.isEmpty) continue;

      final answers = <ExamAnswer>[];
      final selectedOptionIds = <String, String>{};
      var correctCount = 0;

      for (final question in questions) {
        final correctOption = question.options.firstWhere((option) => option.isCorrect);
        final wrongOption = question.options.firstWhere((option) => !option.isCorrect);
        final chooseCorrect = question.orderNumber.isEven;
        final selectedOption = chooseCorrect ? correctOption : wrongOption;
        final isCorrect = selectedOption.isCorrect;
        if (isCorrect) correctCount++;
        selectedOptionIds[question.id] = selectedOption.id;
        answers.add(
          ExamAnswer(
            id: 'mock_${exam.id}_${question.id}',
            examAttemptId: 'mock_attempt_${exam.id}',
            questionId: question.id,
            selectedOptionId: selectedOption.id,
            answeredAt: DateTime.now().subtract(Duration(days: question.orderNumber)),
            isCorrect: isCorrect,
            earnedScore: isCorrect ? question.score : 0,
          ),
        );
      }

      final wrongCount = questions.length - correctCount;
      final startedAt = DateTime.now().subtract(const Duration(days: 2, minutes: 30));
      final completedAt = startedAt.add(const Duration(minutes: 28));
      final double score = questions.isEmpty ? 0.0 : (correctCount / questions.length) * exam.totalScore;
      final attempt = ExamAttempt(
        id: 'mock_attempt_${exam.id}',
        examId: exam.id,
        studentId: studentId,
        startedAt: startedAt,
        completedAt: completedAt,
        score: score.toDouble(),
        isPassed: score >= exam.passingScore,
        answeredQuestionCount: questions.length,
        totalQuestionCount: questions.length,
        isSubmitted: true,
      );

      results.add(
        ExamResultData(
          exam: exam,
          questions: questions,
          selectedOptionIds: selectedOptionIds,
          answers: answers,
          attempt: attempt,
          studentId: studentId,
          correctCount: correctCount,
          wrongCount: wrongCount,
          score: score.toDouble(),
          completionPercentage: questions.isEmpty ? 0 : (correctCount / questions.length) * 100,
          timeSpent: completedAt.difference(startedAt),
          autoSubmitted: false,
        ),
      );
    }

    return results;
  }
}