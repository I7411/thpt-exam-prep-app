// Teacher repository for teacher-specific operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  Future<int> getAcceptedStudentCount(String teacherId);
}

/// Mock implementation of TeacherRepository.
/// NOTE: In the current architecture, MockTeacherRepository is wired up as the active repository
/// provider by RepositoryService. To avoid breaking this architecture while ensuring real data
/// synchronization, it has been enhanced to query Cloud Firestore directly for accepted student counts.
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

  // Reads the actual Firestore data for accepted student counts instead of using mock data.
  @override
  Future<int> getAcceptedStudentCount(String teacherId) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      String verifiedTeacherId = teacherId;
      if (verifiedTeacherId != currentUid && currentUid != null) {
        verifiedTeacherId = currentUid;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('teacher_student_requests')
          .where('teacherId', isEqualTo: verifiedTeacherId)
          .where('status', isEqualTo: 'accepted')
          .get()
          .timeout(const Duration(seconds: 12));

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Lỗi khi truy vấn số lượng học sinh chấp nhận: $e');
      return 0;
    }
  }
}

