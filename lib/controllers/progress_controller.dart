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

  /// The source-of-truth document count, loaded from Firestore
  /// `learned_materials` collection (count query) or `progress_stats`.
  int _totalLearnedDocuments = 0;

  bool get isLoading => _isLoading;
  String? get studentId => _studentId;
  List<ProgressStat> get subjectProgress => List.unmodifiable(_subjectProgress);
  List<ExamResultData> get examHistory => List.unmodifiable(_examHistory);
  List<Subject> get subjects => List.unmodifiable(_subjects);

  int get totalExamsTaken =>
      _subjectProgress.fold(0, (total, item) => total + item.totalExamsTaken);

  /// Total documents learned — comes from `learned_materials` count query,
  /// NOT from summing ProgressStat.totalDocumentsRead (which is always 0
  /// because document reads are tracked separately).
  int get totalLearnedDocuments => _totalLearnedDocuments;

  /// @deprecated — kept for backward-compat. Prefer [totalLearnedDocuments].
  int get totalDocumentsRead => _totalLearnedDocuments;

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

      // Load learned-documents count from the repository (Firestore count query).
      _totalLearnedDocuments = await _repositoryService.progress
          .getTotalLearnedDocuments(studentId)
          .timeout(const Duration(seconds: 10));

      debugPrint('[Progress] Progress screen loaded documentsRead=$_totalLearnedDocuments');

      final localHistory = await _localRepository.getExamHistory(studentId);
      _examHistory = localHistory;
    } catch (e) {
      debugPrint('Không tải được tiến độ học tập: $e');
      _subjectProgress = <ProgressStat>[];
      _examHistory = <ExamResultData>[];
      // Keep _totalLearnedDocuments as last known value (or 0 on first load).
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Mark document as learned ──────────────────────────────────────────────

  /// Marks the given document as learned for the current student.
  ///
  /// Behaviour:
  /// - Writes `learned_materials/{userId}_{documentId}` (idempotent).
  /// - Recalculates `documentsRead` from source of truth (count query).
  /// - Updates `progress_stats/{userId}.documentsRead` in Firestore.
  /// - Updates in-memory `_totalLearnedDocuments` and calls `notifyListeners()`.
  ///
  /// Returns `true` on success, `false` on Firestore failure.
  Future<bool> markDocumentAsLearned(StudyDocument document) async {
    final uid = _studentId;
    if (uid == null || uid.isEmpty) {
      debugPrint('[Progress] markDocumentAsLearned skipped: no studentId');
      return false;
    }

    try {
      await _repositoryService.progress.markDocumentAsLearned(
        userId: uid,
        materialId: document.id,
        title: document.title,
        subjectId: document.subjectId,
      );

      // Refresh count from source of truth.
      final count = await _repositoryService.progress
          .getTotalLearnedDocuments(uid)
          .timeout(const Duration(seconds: 8));

      _totalLearnedDocuments = count;
      notifyListeners();
      debugPrint('[Progress] ProgressController updated documentsRead=$count');
      return true;
    } catch (e) {
      debugPrint('[Progress] markDocumentAsLearned error: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
