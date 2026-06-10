import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_documents.dart';
import 'package:thpt_exam_prep_app/data/mock/mock_exams.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';
import 'package:thpt_exam_prep_app/repositories/repo_notification.dart';

class AdminDocumentSummary {
  final StudyDocument document;
  final String subjectName;
  final String status;

  const AdminDocumentSummary({
    required this.document,
    required this.subjectName,
    required this.status,
  });
}

class AdminExamSummary {
  final Exam exam;
  final Subject subject;
  final int questionCount;
  final String difficulty;
  final String status;

  const AdminExamSummary({
    required this.exam,
    required this.subject,
    required this.questionCount,
    required this.difficulty,
    required this.status,
  });
}

class AdminSubjectReport {
  final Subject subject;
  final int documentCount;
  final int examCount;
  final int questionCount;
  final double averageScore;

  const AdminSubjectReport({
    required this.subject,
    required this.documentCount,
    required this.examCount,
    required this.questionCount,
    required this.averageScore,
  });
}

class AdminController extends ChangeNotifier {
  bool _isLoading = false;
  AdminReportStat? _report;
  List<AppUser> _users = [];
  List<StudyDocument> _documents = [];
  List<Exam> _exams = [];
  List<Subject> _subjects = [];
  List<AdminDocumentSummary> _documentSummaries = [];
  List<AdminExamSummary> _examSummaries = [];
  List<AdminSubjectReport> _subjectReports = [];

  bool get isLoading => _isLoading;
  AdminReportStat? get report => _report;
  List<AppUser> get users => List.unmodifiable(_users);
  List<StudyDocument> get documents => List.unmodifiable(_documents);
  List<Exam> get exams => List.unmodifiable(_exams);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<AdminDocumentSummary> get documentSummaries =>
      List.unmodifiable(_documentSummaries);
  List<AdminExamSummary> get examSummaries => List.unmodifiable(_examSummaries);
  List<AdminSubjectReport> get subjectReports =>
      List.unmodifiable(_subjectReports);

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final service = RepositoryService.instance;
      final loadedReport = await service.admin.getSystemReport().timeout(
        const Duration(seconds: 12),
      );
      final loadedUsers = (await service.admin.getAllUsers().timeout(
        const Duration(seconds: 12),
      )).take(50).toList();
      final loadedDocuments = List<StudyDocument>.from(
        MockDocumentsData.documents,
      ).take(20).toList();
      final loadedExams = List<Exam>.from(
        MockExamsData.exams,
      ).take(20).toList();
      final loadedSubjects = await service.subject.getAllSubjects().timeout(
        const Duration(seconds: 12),
      );

      _report = loadedReport.copyWith(
        totalDocuments: loadedReport.totalDocuments > 0 ? loadedReport.totalDocuments : loadedDocuments.length,
        totalExams: loadedReport.totalExams > 0 ? loadedReport.totalExams : loadedExams.length,
        totalUsers: loadedReport.totalUsers > 0 ? loadedReport.totalUsers : loadedUsers.length,
        totalStudents: loadedReport.totalStudents > 0 ? loadedReport.totalStudents : loadedUsers.where((user) => user.role == UserRole.student).length,
        totalTeachers: loadedReport.totalTeachers > 0 ? loadedReport.totalTeachers : loadedUsers.where((user) => user.role == UserRole.teacher).length,
        totalExamAttempts: loadedReport.totalExamAttempts > 0 ? loadedReport.totalExamAttempts : MockExamsData.questions.length * 6,
      );
      _users = loadedUsers;
      _documents = loadedDocuments;
      _exams = loadedExams;
      _subjects = loadedSubjects;
      _documentSummaries = _buildDocumentSummaries(
        loadedDocuments,
        loadedSubjects,
      );
      _examSummaries = await _buildExamSummaries(
        service,
        loadedExams,
        loadedSubjects,
      );
      _subjectReports = _buildSubjectReports(
        loadedSubjects,
        loadedDocuments,
        loadedExams,
        loadedExams,
        _examSummaries,
      );
    } catch (e) {
      debugPrint('Không tải được dữ liệu admin: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Subject? subjectById(String subjectId) {
    try {
      return _subjects.firstWhere((subject) => subject.id == subjectId);
    } catch (e) {
      return null;
    }
  }

  String subjectName(String subjectId) {
    return subjectById(subjectId)?.name ?? subjectId;
  }

  List<AdminDocumentSummary> _buildDocumentSummaries(
    List<StudyDocument> documents,
    List<Subject> subjects,
  ) {
    return documents.map((document) {
      final subject = subjectById(document.subjectId);
      final status = document.updatedAt != null ? 'Updated' : 'Draft';
      return AdminDocumentSummary(
        document: document,
        subjectName: subject?.name ?? 'Môn học',
        status: status,
      );
    }).toList();
  }

  Future<List<AdminExamSummary>> _buildExamSummaries(
    RepositoryService service,
    List<Exam> exams,
    List<Subject> subjects,
  ) async {
    final summaries = <AdminExamSummary>[];
    for (final exam in exams) {
      final subject =
          subjectById(exam.subjectId) ??
          subjects.firstWhere(
            (item) => item.id == exam.subjectId,
            orElse: () => subjects.first,
          );
      final questions = await service.exam.getQuestionsByExam(exam.id);
      summaries.add(
        AdminExamSummary(
          exam: exam,
          subject: subject,
          questionCount: questions.length,
          difficulty: _difficultyLabel(questions.length),
          status: exam.isPublished ? 'Published' : 'Draft',
        ),
      );
    }
    return summaries;
  }

  List<AdminSubjectReport> _buildSubjectReports(
    List<Subject> subjects,
    List<StudyDocument> documents,
    List<Exam> exams,
    List<Exam> allExams,
    List<AdminExamSummary> examSummaries,
  ) {
    return subjects.map((subject) {
      final subjectDocuments = documents
          .where((document) => document.subjectId == subject.id)
          .length;
      final subjectExams = exams
          .where((exam) => exam.subjectId == subject.id)
          .length;
      final subjectQuestions = examSummaries
          .where((summary) => summary.subject.id == subject.id)
          .fold<int>(0, (sum, summary) => sum + summary.questionCount);
      final averageScore = _estimateAverageScore(subject.id);
      return AdminSubjectReport(
        subject: subject,
        documentCount: subjectDocuments,
        examCount: subjectExams,
        questionCount: subjectQuestions,
        averageScore: averageScore,
      );
    }).toList();
  }

  double _estimateAverageScore(String subjectId) {
    final base = subjectId.hashCode.abs() % 40;
    return 5.5 + (base / 20.0);
  }

  String _difficultyLabel(int questionCount) {
    if (questionCount <= 3) return 'Easy';
    if (questionCount <= 5) return 'Medium';
    return 'Hard';
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = RepositoryService.instance;
      // To create a Firebase Auth user without signing them in (and signing out the admin):
      // We initialize a temporary secondary FirebaseApp instance
      final tempApp = await Firebase.initializeApp(
        name: 'TempUserApp',
        options: Firebase.app().options,
      );
      final userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      final uid = userCredential.user!.uid;

      // Save profile to Firestore
      final newUser = AppUser(
        id: uid,
        email: email,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );
      await service.admin.createUser(newUser);
      await tempApp.delete();

      // Reload users list
      await loadData();
    } catch (e) {
      debugPrint('Lỗi tạo user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(AppUser user) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = RepositoryService.instance;
      await service.admin.updateUser(user);
      await loadData();
    } catch (e) {
      debugPrint('Lỗi cập nhật user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = RepositoryService.instance;
      await service.admin.deleteUser(uid);
      await loadData();
    } catch (e) {
      debugPrint('Lỗi xóa user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendSystemNotification({
    required String title,
    required String body,
    required String targetRole, // "student" | "teacher" | "admin" | "all"
    required NotificationType type,
    required String senderId,
    required String senderRole,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = RepositoryService.instance;
      final notificationRepo = service.notification as FirestoreNotificationRepository;
      await notificationRepo.createBroadcastNotification(
        title: title,
        body: body,
        type: type,
        senderId: senderId,
        senderRole: senderRole,
        targetRole: targetRole,
      );
    } catch (e) {
      debugPrint('Lỗi gửi thông báo hệ thống: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
