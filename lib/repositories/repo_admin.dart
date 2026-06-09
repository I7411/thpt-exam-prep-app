/// Admin repository for admin-specific operations
library;
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

