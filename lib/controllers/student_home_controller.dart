import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';

class StudentHomeController extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  StudentHomeData? _homeData;
  String? _loadedStudentId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StudentHomeData? get homeData => _homeData;
  bool get hasData => _homeData != null;

  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _homeData = null;
    _loadedStudentId = null;
    notifyListeners();
  }

  Future<void> retryLoad(String studentId) async {
    await loadHomeData(studentId, forceRefresh: true);
  }

  Future<void> refresh(String studentId) async {
    await loadHomeData(studentId, forceRefresh: true);
  }

  Future<void> loadHomeData(
    String studentId, {
    bool forceRefresh = false,
  }) async {
    if (studentId.isEmpty) return;

    if (_isLoading) return;

    if (!forceRefresh && _loadedStudentId == studentId && _homeData != null) {
      return;
    }

    if (_loadedStudentId != studentId) {
      _homeData = null; // Clear old user data
    }

    _loadedStudentId = studentId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final subjectsFuture = _repositoryService.subject
          .getAllSubjects()
          .timeout(const Duration(seconds: 12));
      final documentsFuture = _repositoryService.document
          .getAllDocuments()
          .timeout(const Duration(seconds: 12));
      final examsFuture = _repositoryService.exam.getAllExams().timeout(
        const Duration(seconds: 12),
      );
      final progressStatsFuture = _repositoryService.progress
          .getProgressByStudent(studentId)
          .timeout(const Duration(seconds: 12));
      final averageScoreFuture = _repositoryService.progress
          .getAverageScoreByStudent(studentId)
          .timeout(const Duration(seconds: 12));
      final totalExamsFuture = _repositoryService.progress
          .getTotalExamsByStudent(studentId)
          .timeout(const Duration(seconds: 12));
      final examsPassedFuture = _repositoryService.progress
          .getExamsPassedByStudent(studentId)
          .timeout(const Duration(seconds: 12));

      final favoritesFuture = FirebaseFirestore.instance
          .collection('saved_materials')
          .where('userId', isEqualTo: studentId)
          .where('isFavorite', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final learnedCountFuture = _repositoryService.progress
          .getTotalLearnedDocuments(studentId)
          .timeout(const Duration(seconds: 10));

      final subjects = await subjectsFuture;
      final documents = (await documentsFuture).take(20).toList();
      final exams = (await examsFuture).take(20).toList();
      final progressStats = await progressStatsFuture;
      final averageScore = await averageScoreFuture;
      final totalExams = await totalExamsFuture;
      final examsPassed = await examsPassedFuture;
      final favoritesSnapshot = await favoritesFuture;

      final favoritesMap = <String, DateTime>{};
      for (final doc in favoritesSnapshot.docs) {
        final data = doc.data();
        final materialId = data['materialId'] as String?;
        final favoriteAtVal = data['favoriteAt'];
        if (materialId != null) {
          DateTime favTime = DateTime.now();
          if (favoriteAtVal is Timestamp) {
            favTime = favoriteAtVal.toDate();
          } else if (favoriteAtVal is String) {
            favTime = DateTime.tryParse(favoriteAtVal) ?? DateTime.now();
          }
          favoritesMap[materialId] = favTime;
        }
      }

      final totalLearnedDocuments = await learnedCountFuture;

      _homeData = StudentHomeData(
        subjects: subjects,
        documents: documents,
        exams: exams,
        progressStats: progressStats,
        averageScore: averageScore,
        totalExams: totalExams,
        examsPassed: examsPassed,
        totalLearnedDocuments: totalLearnedDocuments,
        favoritesMap: favoritesMap,
      );
    } catch (error, stackTrace) {
      _errorMessage = 'Không thể tải trang chủ. Vui lòng thử lại.';
      debugPrint('Lỗi tải trang chủ học sinh: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
