import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';
import 'package:thpt_exam_prep_app/controllers/progress_controller.dart';

class LearningController extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  List<Subject> _subjects = [];
  List<StudyDocument> _documents = [];
  final List<StudyDocument> _learnedDocuments = [];
  final Set<String> _favoriteDocumentIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<StudyDocument> get documents => List.unmodifiable(_documents);
  List<StudyDocument> get learnedDocuments =>
      List.unmodifiable(_learnedDocuments);
  Set<String> get favoriteDocumentIds => Set.unmodifiable(_favoriteDocumentIds);

  Future<void> loadFavorites(String userId) async {
    if (userId.isEmpty) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saved_materials')
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .get();
      _favoriteDocumentIds.clear();
      for (var doc in snapshot.docs) {
        final materialId = doc.data()['materialId'] as String?;
        if (materialId != null) {
          _favoriteDocumentIds.add(materialId);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: ');
    }
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subjects = await _repositoryService.subject.getAllSubjects();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách môn học: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDocuments(String subjectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (subjectId.isEmpty) {
        _documents = await _repositoryService.document.getAllDocuments();
      } else {
        _documents = await _repositoryService.document.getDocumentsBySubject(
          subjectId,
        );
      }
    } catch (e) {
      _errorMessage = 'Không thể tải tài liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Subject?> getSubjectById(String id) async {
    return await _repositoryService.subject.getSubjectById(id);
  }

  Future<bool> checkIsFavorite(String userId, String documentId) async {
    if (userId.isEmpty || documentId.isEmpty) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('saved_materials')
          .doc('${userId}_$documentId')
          .get();
      return doc.exists && doc.data()?['isFavorite'] == true;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  Future<bool> checkIsLearned(String userId, String documentId) async {
    if (userId.isEmpty || documentId.isEmpty) return false;
    try {
      final learnedDoc = await FirebaseFirestore.instance
          .collection('learned_materials')
          .doc('${userId}_$documentId')
          .get();
      return learnedDoc.exists;
    } catch (e) {
      debugPrint('Error checking learned: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(
    String userId,
    String documentId,
    bool isFavorite,
  ) async {
    if (userId.isEmpty || documentId.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('saved_materials')
          .doc('${userId}_$documentId');

      if (isFavorite) {
        await docRef.set({
          'userId': userId,
          'materialId': documentId,
          'isFavorite': true,
          'favoriteAt': FieldValue.serverTimestamp(),
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<bool> markDocumentAsLearned(
    StudyDocument document,
    String userId,
    ProgressController progressCtrl,
  ) async {
    if (userId.isEmpty) return false;
    try {
      final success = await progressCtrl.markDocumentAsLearned(document);
      if (success) {
        if (!_learnedDocuments.any((doc) => doc.id == document.id)) {
          _learnedDocuments.add(document);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('Error marking document as learned: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLearnedHistory(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final learnedSnapshot = await FirebaseFirestore.instance
          .collection('learned_materials')
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10));

      final learnedList = <Map<String, dynamic>>[];
      for (final doc in learnedSnapshot.docs) {
        final data = doc.data();
        DateTime learnedAt = DateTime.now();
        final learnedAtVal = data['learnedAt'];
        if (learnedAtVal is Timestamp) {
          learnedAt = learnedAtVal.toDate();
        } else if (learnedAtVal is String) {
          learnedAt = DateTime.tryParse(learnedAtVal) ?? DateTime.now();
        }

        learnedList.add({
          'materialId': data['materialId'] as String? ?? '',
          'learnedAt': learnedAt,
        });
      }
      learnedList.sort(
        (a, b) =>
            (b['learnedAt'] as DateTime).compareTo(a['learnedAt'] as DateTime),
      );
      return learnedList;
    } catch (e) {
      debugPrint('Error getting learned history: $e');
      return [];
    }
  }

  Future<List<StudyDocument>> getAllDocuments() async {
    try {
      return await _repositoryService.document.getAllDocuments();
    } catch (e) {
      debugPrint('Error getting all docs: $e');
      return [];
    }
  }
}
