/// Service Locator for dependency injection of repositories
import 'package:thpt_exam_prep_app/repo_auth.dart';
import 'package:thpt_exam_prep_app/repo_subject.dart';
import 'package:thpt_exam_prep_app/repo_document.dart';
import 'package:thpt_exam_prep_app/repo_exam.dart';
import 'package:thpt_exam_prep_app/repo_progress.dart';
import 'package:thpt_exam_prep_app/repo_notification.dart';
import 'package:thpt_exam_prep_app/repo_teacher.dart';
import 'package:thpt_exam_prep_app/repo_admin.dart';

/// Service Locator class - singleton for accessing all repositories
class RepositoryService {
  static final RepositoryService _instance = RepositoryService._internal();

  late final AuthRepository _authRepo;
  late final SubjectRepository _subjectRepo;
  late final DocumentRepository _documentRepo;
  late final ExamRepository _examRepo;
  late final ProgressRepository _progressRepo;
  late final NotificationRepository _notificationRepo;
  late final TeacherRepository _teacherRepo;
  late final AdminRepository _adminRepo;

  factory RepositoryService() {
    return _instance;
  }

  static RepositoryService get instance => _instance;

  RepositoryService._internal() {
    _initializeRepositories();
  }

  void _initializeRepositories() {
    // Initialize all mock repositories
    // To switch to API implementation, just change these lines
    _authRepo = MockAuthRepository();
    _subjectRepo = MockSubjectRepository();
    _documentRepo = MockDocumentRepository();
    _examRepo = MockExamRepository();
    _progressRepo = MockProgressRepository();
    _notificationRepo = MockNotificationRepository();
    _teacherRepo = MockTeacherRepository();
    _adminRepo = MockAdminRepository();
  }

  // Getters for all repositories
  AuthRepository get auth => _authRepo;
  SubjectRepository get subject => _subjectRepo;
  DocumentRepository get document => _documentRepo;
  ExamRepository get exam => _examRepo;
  ProgressRepository get progress => _progressRepo;
  NotificationRepository get notification => _notificationRepo;
  TeacherRepository get teacher => _teacherRepo;
  AdminRepository get admin => _adminRepo;

  // Backward-compatible aliases for older screen code.
  AuthRepository get authRepository => _authRepo;
  SubjectRepository get subjectRepository => _subjectRepo;
  DocumentRepository get documentRepository => _documentRepo;
  ExamRepository get examRepository => _examRepo;
  ProgressRepository get progressRepository => _progressRepo;
  NotificationRepository get notificationRepository => _notificationRepo;
  TeacherRepository get teacherRepository => _teacherRepo;
  AdminRepository get adminRepository => _adminRepo;

  /// Helper method for easy access from anywhere in the app
  static RepositoryService getInstance() => _instance;
}
