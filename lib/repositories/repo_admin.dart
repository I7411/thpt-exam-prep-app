/// Admin repository for admin-specific operations
library;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';

abstract class AdminRepository {
  Future<AdminReportStat> getSystemReport();
  Future<void> updateSystemReport(AdminReportStat report);
  Future<List<AppUser>> getAllUsers();
  Future<List<AppUser>> getUsersByRole(UserRole role);
  Future<AppUser?> getUserById(String id);
  Future<void> createUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<void> deleteUser(String id);
  Future<List<Exam>> getAllExams();
  Future<List<StudyDocument>> getAllDocuments();
}

/// Mock implementation
class MockAdminRepository implements AdminRepository {
  late AdminReportStat _report = MockUsersData.adminReport;
  final List<AppUser> _users = [
    MockUsersData.studentUser,
    MockUsersData.teacherUser,
    MockUsersData.adminUser,
  ];
  final List<Exam> _exams = [];
  final List<StudyDocument> _documents = [];

  @override
  Future<AdminReportStat> getSystemReport() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _report;
  }

  @override
  Future<void> updateSystemReport(AdminReportStat report) async {
    await Future.delayed(Duration(milliseconds: 300));
    _report = report;
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _users;
  }

  @override
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _users.where((u) => u.role == role).toList();
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createUser(AppUser user) async {
    await Future.delayed(Duration(milliseconds: 300));
    _users.add(user);
    _report = _report.copyWith(
      totalUsers: _report.totalUsers + 1,
      totalStudents: user.role == UserRole.student ? _report.totalStudents + 1 : _report.totalStudents,
      totalTeachers: user.role == UserRole.teacher ? _report.totalTeachers + 1 : _report.totalTeachers,
    );
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    final user = _users.firstWhere((u) => u.id == id);
    _users.removeWhere((u) => u.id == id);

    int studentDelta = user.role == UserRole.student ? -1 : 0;
    int teacherDelta = user.role == UserRole.teacher ? -1 : 0;

    _report = _report.copyWith(
      totalUsers: _report.totalUsers - 1,
      totalStudents: _report.totalStudents + studentDelta,
      totalTeachers: _report.totalTeachers + teacherDelta,
    );
  }

  @override
  Future<List<Exam>> getAllExams() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _exams;
  }

  @override
  Future<List<StudyDocument>> getAllDocuments() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _documents;
  }
}

/// Real Firestore Admin Repository
class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AdminReportStat> getSystemReport() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.size;

      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final totalStudents = studentsSnapshot.size;

      final teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      final totalTeachers = teachersSnapshot.size;

      int totalDocs = 0;
      try {
        final docsSnap = await _firestore.collection('documents').get();
        totalDocs = docsSnap.size;
      } catch (_) {}

      int totalExams = 0;
      try {
        final examsSnap = await _firestore.collection('exams').get();
        totalExams = examsSnap.size;
      } catch (_) {}

      int totalAttempts = 0;
      try {
        final attemptsSnap = await _firestore.collection('exam_attempts').get();
        totalAttempts = attemptsSnap.size;
      } catch (_) {
        try {
          final attemptsSnap2 = await _firestore.collection('results').get();
          totalAttempts = attemptsSnap2.size;
        } catch (_) {}
      }

      return AdminReportStat(
        id: 'realtime_report',
        totalUsers: totalUsers,
        totalStudents: totalStudents,
        totalTeachers: totalTeachers,
        totalDocuments: totalDocs,
        totalExams: totalExams,
        totalExamAttempts: totalAttempts,
        averageExamScore: 0.0,
        examPassRate: 0,
        activeUsersThisWeek: 0,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Lỗi lấy thống kê admin: $e');
      return AdminReportStat(
        id: 'fallback_report',
        totalUsers: 0,
        totalStudents: 0,
        totalTeachers: 0,
        totalDocuments: 0,
        totalExams: 0,
        totalExamAttempts: 0,
        averageExamScore: 0.0,
        examPassRate: 0,
        activeUsersThisWeek: 0,
        generatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateSystemReport(AdminReportStat report) async {
    // Calculated dynamically
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  @override
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: role.toValue())
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  @override
  Future<void> createUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  @override
  Future<List<Exam>> getAllExams() async {
    try {
      final snapshot = await _firestore.collection('exams').get();
      return snapshot.docs
          .map((doc) => Exam.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<StudyDocument>> getAllDocuments() async {
    try {
      final snapshot = await _firestore.collection('documents').get();
      return snapshot.docs
          .map((doc) => StudyDocument.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

