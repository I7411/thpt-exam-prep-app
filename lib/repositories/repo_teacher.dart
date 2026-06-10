// Teacher repository for teacher-specific operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:thpt_exam_prep_app/models.dart';

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
  final List<ExamAttempt> _attempts = [];

  @override
  Future<List<TeacherClass>> getClassesByTeacher(String teacherId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherIds', arrayContains: teacherId)
          .get()
          .timeout(const Duration(seconds: 12));
      
      if (snapshot.docs.isEmpty) {
        // Fallback to teacherId query
        final snapshot2 = await FirebaseFirestore.instance
            .collection('classes')
            .where('teacherId', isEqualTo: teacherId)
            .get()
            .timeout(const Duration(seconds: 12));
        return snapshot2.docs.map((doc) => TeacherClass.fromFirestore(doc)).toList();
      }
      return snapshot.docs.map((doc) => TeacherClass.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Lỗi lấy danh sách lớp học: $e');
      return [];
    }
  }

  @override
  Future<TeacherClass?> getClassById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 12));
      if (!doc.exists) return null;
      return TeacherClass.fromFirestore(doc);
    } catch (e) {
      debugPrint('Lỗi lấy chi tiết lớp học: $e');
      return null;
    }
  }

  @override
  Future<void> createClass(TeacherClass teacherClass) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(teacherClass.id)
          .set(teacherClass.toFirestore())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Lỗi tạo lớp học: $e');
    }
  }

  @override
  Future<void> updateClass(TeacherClass teacherClass) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(teacherClass.id)
          .update(teacherClass.toFirestore())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Lỗi cập nhật lớp học: $e');
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(id)
          .delete()
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Lỗi xóa lớp học: $e');
    }
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
