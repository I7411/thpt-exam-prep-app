/// Application route definitions
class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Authentication
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Student Routes
  static const String studentHome = '/student/home';
  static const String studentSubjects = '/student/subjects';
  static const String studentDocuments = '/student/documents';
  static const String studentDocumentDetail = '/student/document-detail';
  static const String studentExams = '/student/exams';
  static const String studentExamTaking = '/student/exam-taking';
  static const String studentExamResult = '/student/exam-result';
  static const String studentProgress = '/student/progress';
  static const String studentHistory = '/student/history';
  static const String studentNotifications = '/student/notifications';
  static const String studentProfile = '/student/profile';
  static const String studentTeacherRequests = '/student/teacher-requests';

  // Exam flow aliases
  static const String examList = studentExams;
  static const String examTaking = studentExamTaking;
  static const String examResult = studentExamResult;

  // Teacher Routes
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherClasses = '/teacher/classes';
  static const String teacherClassDetail = '/teacher/class-detail';
  static const String teacherQuestions = '/teacher/questions';
  static const String teacherSchedule = '/teacher/schedule';
  static const String teacherProfile = '/teacher/profile';
  static const String teacherStudents = '/teacher/students';
  static const String teacherExams = '/teacher/exams';
  static const String teacherExamCreate = '/teacher/exam-create';
  static const String teacherQuestionCreate = '/teacher/question-create';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminDocuments = '/admin/documents';
  static const String adminExams = '/admin/exams';
  static const String adminReports = '/admin/reports';

  // Admin route aliases
  static const String adminUserManagement = adminUsers;
  static const String adminDocumentManagement = adminDocuments;
  static const String adminExamQuestionManagement = adminExams;

  /// Get all routes as a list
  static List<String> getAllRoutes() {
    return [
      splash,
      login,
      register,
      forgotPassword,
      studentHome,
      studentSubjects,
      studentDocuments,
      studentDocumentDetail,
      studentExams,
      studentExamTaking,
      studentExamResult,
      studentProgress,
      studentHistory,
      studentNotifications,
      studentProfile,
      studentTeacherRequests,
      teacherDashboard,
      teacherClasses,
      teacherClassDetail,
      teacherQuestions,
      teacherSchedule,
      teacherProfile,
      teacherStudents,
      teacherExams,
      teacherExamCreate,
      teacherQuestionCreate,
      adminDashboard,
      adminUsers,
      adminDocuments,
      adminExams,
      adminReports,
    ];
  }
}
