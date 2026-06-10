import 'package:flutter/foundation.dart';

import 'package:thpt_exam_prep_app/data/local/app_database.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class ProgressController extends ChangeNotifier {
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

  int get totalExamsTaken =>
      _subjectProgress.fold(0, (total, item) => total + item.totalExamsTaken);

  int get totalDocumentsRead => _subjectProgress.fold(
    0,
    (total, item) => total + item.totalDocumentsRead,
  );

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

    try {
      final subjectFuture = _repositoryService.subject.getAllSubjects().timeout(
        const Duration(seconds: 12),
      );

      _subjects = await subjectFuture;

      final firestoreProgress = await _repositoryService.progress
          .getProgressByStudent(studentId)
          .timeout(const Duration(seconds: 12));
      _subjectProgress = firestoreProgress;

      final localHistory = await _localRepository.getExamHistory(studentId);
      _examHistory = localHistory;
    } catch (e) {
      debugPrint('Không tải được tiến độ học tập: $e');
      _subjectProgress = <ProgressStat>[];
      _examHistory = <ExamResultData>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      ..sort(
        (left, right) =>
            right.attempt.startedAt.compareTo(left.attempt.startedAt),
      );
    return history.take(limit).toList();
  }

  Future<void> refreshExamHistory() async {
    if (_studentId == null) return;

    await initialize(_studentId!, force: true);
    notifyListeners();
  }
}
