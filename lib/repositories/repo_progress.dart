/// Progress repository for tracking student progress
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
  /// Returns the number of unique documents learned by this student.
  Future<int> getTotalLearnedDocuments(String studentId);
  /// Writes the document to learned_materials (idempotent) and updates
  /// progress_stats.documentsRead for the student.
  Future<void> markDocumentAsLearned({
    required String userId,
    required String materialId,
    required String title,
    required String subjectId,
  });
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

  // ── Mock implementations of new document-learned methods ──

  final Set<String> _learnedDocKeys = {};

  @override
  Future<int> getTotalLearnedDocuments(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _learnedDocKeys.where((k) => k.startsWith('${studentId}_')).length;
  }

  @override
  Future<void> markDocumentAsLearned({
    required String userId,
    required String materialId,
    required String title,
    required String subjectId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _learnedDocKeys.add('${userId}_$materialId');
  }
}

/// Real Firestore Progress Repository
class FirestoreProgressRepository implements ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StudentProgress> _getOrCreateStudentProgress(String studentId) async {
    try {
      final doc = await _firestore.collection('progress_stats').doc(studentId).get();
      if (doc.exists) {
        return StudentProgress.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Lỗi tải tiến độ học sinh từ Firestore: $e');
    }
    return StudentProgress.zero(studentId);
  }

  @override
  Future<List<ProgressStat>> getProgressByStudent(String studentId) async {
    final progress = await _getOrCreateStudentProgress(studentId);
    return progress.subjectProgress;
  }

  @override
  Future<ProgressStat?> getProgressByStudentSubject(String studentId, String subjectId) async {
    final progress = await _getOrCreateStudentProgress(studentId);
    try {
      return progress.subjectProgress.firstWhere((p) => p.subjectId == subjectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProgress(ProgressStat progress) async {
    await createProgress(progress);
  }

  @override
  Future<void> createProgress(ProgressStat progress) async {
    try {
      final studentProgress = await _getOrCreateStudentProgress(progress.studentId);
      
      final currentList = List<ProgressStat>.from(studentProgress.subjectProgress);
      final index = currentList.indexWhere((p) => p.subjectId == progress.subjectId);
      if (index >= 0) {
        currentList[index] = progress;
      } else {
        currentList.add(progress);
      }

      // Calculate totals
      int totalExams = 0;
      int totalDocs = 0;
      double totalScore = 0.0;
      double totalCompletion = 0.0;

      for (final p in currentList) {
        totalExams += p.totalExamsTaken;
        totalDocs += p.totalDocumentsRead;
        totalScore += p.averageScore * p.totalExamsTaken;
        totalCompletion += p.completionPercentage;
      }

      final avgScore = totalExams == 0 ? 0.0 : totalScore / totalExams;
      final avgCompletion = currentList.isEmpty ? 0.0 : totalCompletion / currentList.length;

      final updatedProgress = studentProgress.copyWith(
        totalExamsCompleted: totalExams,
        averageScore: avgScore,
        documentsRead: totalDocs,
        activeSubjects: currentList.length,
        overallProgressPercentage: avgCompletion,
        subjectProgress: currentList,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('progress_stats')
          .doc(progress.studentId)
          .set(updatedProgress.toFirestore(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Lỗi cập nhật tiến độ học sinh lên Firestore: $e');
    }
  }

  @override
  Future<double> getAverageScoreByStudent(String studentId) async {
    final progress = await _getOrCreateStudentProgress(studentId);
    return progress.averageScore;
  }

  @override
  Future<int> getTotalExamsByStudent(String studentId) async {
    final progress = await _getOrCreateStudentProgress(studentId);
    return progress.totalExamsCompleted;
  }

  @override
  Future<int> getExamsPassedByStudent(String studentId) async {
    final progress = await _getOrCreateStudentProgress(studentId);
    return progress.subjectProgress.fold<int>(0, (total, p) => total + p.examsPassed);
  }

  // ── Document learned tracking ─────────────────────────────────────────────

  @override
  Future<int> getTotalLearnedDocuments(String studentId) async {
    try {
      final snap = await _firestore
          .collection('learned_materials')
          .where('userId', isEqualTo: studentId)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      final count = snap.count ?? 0;
      debugPrint('[Progress] getTotalLearnedDocuments: userId=$studentId, count=$count');
      return count;
    } catch (e) {
      debugPrint('[Progress] getTotalLearnedDocuments error: $e');
      return 0;
    }
  }

  @override
  Future<void> markDocumentAsLearned({
    required String userId,
    required String materialId,
    required String title,
    required String subjectId,
  }) async {
    debugPrint('[Progress] markDocumentAsLearned: userId=$userId, documentId=$materialId');

    // ── Step 1: write learned_materials/{userId}_{materialId} (idempotent) ──
    final docRef = _firestore
        .collection('learned_materials')
        .doc('${userId}_$materialId');

    final existing = await docRef.get().timeout(const Duration(seconds: 8));
    if (!existing.exists) {
      await docRef.set({
        'userId': userId,
        'materialId': materialId,
        'title': title,
        'subjectId': subjectId,
        'learnedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 8));
      debugPrint('[Progress] learned_materials written');
    } else {
      // Update learnedAt timestamp even on re-open; do NOT increment counter.
      await docRef.update({'learnedAt': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 8));
      debugPrint('[Progress] learned_materials already exists — updated learnedAt only');
    }

    // ── Step 2: recalculate total from source of truth ───────────────────────
    final count = await getTotalLearnedDocuments(userId);
    debugPrint('[Progress] documentsRead recalculated: $count');

    // ── Step 3: update progress_stats/{userId}.documentsRead ─────────────────
    try {
      await _firestore
          .collection('progress_stats')
          .doc(userId)
          .set({
            'studentId': userId,
            'documentsRead': count,
            'totalDocumentsRead': count, // legacy compat
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
      debugPrint('[Progress] progress_stats updated');
    } catch (e) {
      debugPrint('[Progress] Failed to update progress_stats: $e');
    }
  }
}
