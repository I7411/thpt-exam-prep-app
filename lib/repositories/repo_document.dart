/// Document repository for study materials
library;
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_documents.dart';

abstract class DocumentRepository {
  Future<List<StudyDocument>> getAllDocuments();
  Future<List<StudyDocument>> getDocumentsBySubject(String subjectId);
  Future<List<StudyDocument>> getDocumentsByTopic(String topicId);
  Future<StudyDocument?> getDocumentById(String id);
  Future<void> createDocument(StudyDocument document);
  Future<void> updateDocument(StudyDocument document);
  Future<void> deleteDocument(String id);
}

/// Mock implementation
class MockDocumentRepository implements DocumentRepository {
  final List<StudyDocument> _documents = List.from(MockDocumentsData.documents);

  @override
  Future<List<StudyDocument>> getAllDocuments() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _documents;
  }

  @override
  Future<List<StudyDocument>> getDocumentsBySubject(String subjectId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _documents.where((d) => d.subjectId == subjectId).toList();
  }

  @override
  Future<List<StudyDocument>> getDocumentsByTopic(String topicId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _documents.where((d) => d.topicId == topicId).toList();
  }

  @override
  Future<StudyDocument?> getDocumentById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createDocument(StudyDocument document) async {
    await Future.delayed(Duration(milliseconds: 300));
    _documents.add(document);
  }

  @override
  Future<void> updateDocument(StudyDocument document) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      _documents[index] = document;
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _documents.removeWhere((d) => d.id == id);
  }
}

