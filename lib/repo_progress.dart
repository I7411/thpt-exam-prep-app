/// Progress repository for tracking student progress
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';

abstract class ProgressRepository {
  Future<List<ProgressStat>> getProgressByStudent(String studentId);
  Future<ProgressStat?> getProgressByStudentSubject(String studentId, String subjectId);
  Future<void> updateProgress(ProgressStat progress);
  Future<void> createProgress(ProgressStat progress);
  Future<double> getAverageScoreByStudent(String studentId);
  Future<int> getTotalExamsByStudent(String studentId);
  Future<int> getExamsPassedByStudent(String studentId);
}

/// Mock implementation
class MockProgressRepository implements ProgressRepository {
  final List<ProgressStat> _progressStats = List.from(MockProgressData.progressStats);

  @override
  Future<List<ProgressStat>> getProgressByStudent(String studentId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _progressStats.where((p) => p.studentId == studentId).toList();
  }

  @override
  Future<ProgressStat?> getProgressByStudentSubject(
    String studentId,
    String subjectId,
  ) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _progressStats.firstWhere(
        (p) => p.studentId == studentId && p.subjectId == subjectId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProgress(ProgressStat progress) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _progressStats.indexWhere((p) => p.id == progress.id);
    if (index >= 0) {
      _progressStats[index] = progress;
    }
  }

  @override
  Future<void> createProgress(ProgressStat progress) async {
    await Future.delayed(Duration(milliseconds: 300));
    _progressStats.add(progress);
  }

  @override
  Future<double> getAverageScoreByStudent(String studentId) async {
    await Future.delayed(Duration(milliseconds: 300));
    final stats = _progressStats.where((p) => p.studentId == studentId).toList();
    if (stats.isEmpty) return 0.0;

    double totalScore = 0;
    for (var stat in stats) {
      totalScore += stat.averageScore;
    }
    return totalScore / stats.length;
  }

  @override
  Future<int> getTotalExamsByStudent(String studentId) async {
    await Future.delayed(Duration(milliseconds: 300));
    int total = 0;
    for (var stat in _progressStats.where((p) => p.studentId == studentId)) {
      total += stat.totalExamsTaken;
    }
    return total;
  }

  @override
  Future<int> getExamsPassedByStudent(String studentId) async {
    await Future.delayed(Duration(milliseconds: 300));
    int passed = 0;
    for (var stat in _progressStats.where((p) => p.studentId == studentId)) {
      passed += stat.examsPassed;
    }
    return passed;
  }
}
