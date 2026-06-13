/// Subject repository for managing subjects
library;

import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_subjects.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getAllSubjects();
  Future<Subject?> getSubjectById(String id);
  Future<void> createSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);
}

/// Mock implementation
class MockSubjectRepository implements SubjectRepository {
  final List<Subject> _subjects = List.from(MockSubjectsData.subjects);

  @override
  Future<List<Subject>> getAllSubjects() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _subjects;
  }

  @override
  Future<Subject?> getSubjectById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createSubject(Subject subject) async {
    await Future.delayed(Duration(milliseconds: 300));
    _subjects.add(subject);
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      _subjects[index] = subject;
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _subjects.removeWhere((s) => s.id == id);
  }
}
