/// Teacher repository for teacher-specific operations
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';

abstract class TeacherRepository {
  Future<List<TeacherClass>> getClassesByTeacher(String teacherId);
  Future<TeacherClass?> getClassById(String id);
  Future<void> createClass(TeacherClass teacherClass);
  Future<void> updateClass(TeacherClass teacherClass);
  Future<void> deleteClass(String id);
  Future<List<ExamAttempt>> getStudentAttemptsByTeacher(String teacherId);
  Future<void> createExamAttempt(ExamAttempt attempt);
  Future<void> updateExamAttempt(ExamAttempt attempt);
}

/// Mock implementation
class MockTeacherRepository implements TeacherRepository {
  final List<TeacherClass> _classes = List.from(MockUsersData.teacherClasses);
  final List<ExamAttempt> _attempts = [];

  @override
  Future<List<TeacherClass>> getClassesByTeacher(String teacherId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _classes.where((c) => c.teacherId == teacherId).toList();
  }

  @override
  Future<TeacherClass?> getClassById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createClass(TeacherClass teacherClass) async {
    await Future.delayed(Duration(milliseconds: 300));
    _classes.add(teacherClass);
  }

  @override
  Future<void> updateClass(TeacherClass teacherClass) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _classes.indexWhere((c) => c.id == teacherClass.id);
    if (index >= 0) {
      _classes[index] = teacherClass;
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _classes.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<ExamAttempt>> getStudentAttemptsByTeacher(String teacherId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _attempts;
  }

  @override
  Future<void> createExamAttempt(ExamAttempt attempt) async {
    await Future.delayed(Duration(milliseconds: 300));
    _attempts.add(attempt);
  }

  @override
  Future<void> updateExamAttempt(ExamAttempt attempt) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _attempts.indexWhere((a) => a.id == attempt.id);
    if (index >= 0) {
      _attempts[index] = attempt;
    }
  }
}
