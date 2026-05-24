import 'package:flutter/material.dart';
import 'package:thpt_exam_prep_app/mock_documents.dart';
import 'package:thpt_exam_prep_app/mock_exams.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

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

class AdminProvider extends ChangeNotifier {
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
  List<AdminDocumentSummary> get documentSummaries => List.unmodifiable(_documentSummaries);
  List<AdminExamSummary> get examSummaries => List.unmodifiable(_examSummaries);
  List<AdminSubjectReport> get subjectReports => List.unmodifiable(_subjectReports);

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final service = RepositoryService.instance;
    final loadedReport = await service.admin.getSystemReport();
    final loadedUsers = await service.admin.getAllUsers();
    final loadedDocuments = List<StudyDocument>.from(MockDocumentsData.documents);
    final loadedExams = List<Exam>.from(MockExamsData.exams);
    final loadedSubjects = await service.subject.getAllSubjects();

    _report = loadedReport.copyWith(
      totalDocuments: loadedDocuments.length,
      totalExams: loadedExams.length,
      totalUsers: loadedUsers.length,
      totalStudents: loadedUsers.where((user) => user.role == UserRole.student).length,
      totalTeachers: loadedUsers.where((user) => user.role == UserRole.teacher).length,
      totalExamAttempts: MockExamsData.questions.length * 6,
    );
    _users = loadedUsers;
    _documents = loadedDocuments;
    _exams = loadedExams;
    _subjects = loadedSubjects;
    _documentSummaries = _buildDocumentSummaries(loadedDocuments, loadedSubjects);
    _examSummaries = await _buildExamSummaries(service, loadedExams, loadedSubjects);
    _subjectReports = _buildSubjectReports(loadedSubjects, loadedDocuments, loadedExams, loadedExams, _examSummaries);

    _isLoading = false;
    notifyListeners();
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

  List<AdminDocumentSummary> _buildDocumentSummaries(List<StudyDocument> documents, List<Subject> subjects) {
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
      final subject = subjectById(exam.subjectId) ?? subjects.firstWhere((item) => item.id == exam.subjectId, orElse: () => subjects.first);
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
      final subjectDocuments = documents.where((document) => document.subjectId == subject.id).length;
      final subjectExams = exams.where((exam) => exam.subjectId == subject.id).length;
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
}