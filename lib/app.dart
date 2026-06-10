import 'package:flutter/material.dart';

import 'app_config.dart';
import 'app_navigation.dart';
import 'core/routes/app_routes.dart';
import 'app_theme.dart';

import 'models.dart';
import 'controllers/exam_controller.dart';
import 'views/placeholder_screen.dart';

// ================= ADMIN =================
import 'views/admin/admin_dashboard_screen.dart';
import 'views/admin/admin_document_management_screen.dart';
import 'views/admin/admin_exam_question_management_screen.dart';
import 'views/admin/admin_reports_screen.dart';
import 'views/admin/admin_user_management_screen.dart';

// ================= EXAM =================
import 'views/exam/exam_list_screen.dart';
import 'views/exam/exam_result_screen.dart';
import 'views/exam/exam_taking_screen.dart';

// ================= NOTIFICATION =================
import 'views/notification/notification_screen.dart';

// ================= PROGRESS =================
import 'views/progress/progress_screen.dart';
import 'views/student/student_history_screen.dart';

// ================= PROFILE =================
import 'views/profile/student_profile_screen.dart';
import 'views/student/student_teacher_requests_screen.dart';

// ================= TEACHER =================
import 'views/teacher/teacher_class_detail_screen.dart';
import 'views/teacher/teacher_class_list_screen.dart';
import 'views/teacher/teacher_dashboard_screen.dart';
import 'views/teacher/teacher_profile_screen.dart';
import 'views/teacher/teacher_question_bank_screen.dart';
import 'views/teacher/teacher_schedule_screen.dart';
import 'views/teacher/teacher_students_screen.dart';
import 'views/teacher/teacher_exam_management_screen.dart';
import 'views/teacher/teacher_exam_create_screen.dart';
import 'views/teacher/teacher_question_create_screen.dart';

// ================= NEW SCREENS =================
import 'views/document_detail_screen.dart';
import 'views/document_list_screen.dart';

import 'views/forgot_password_screen.dart';
import 'views/login_screen.dart';
import 'views/register_screen.dart';

import 'views/splash_screen.dart';
import 'views/student_main_screen.dart';
import 'views/subject_list_screen.dart';

class ThptSmartLearnApp extends StatefulWidget {
  const ThptSmartLearnApp({super.key});

  @override
  State<ThptSmartLearnApp> createState() => _ThptSmartLearnAppState();
}

class _ThptSmartLearnAppState extends State<ThptSmartLearnApp> {
  @override
  void initState() {
    super.initState();

    if (AppConfig.enableDevTools) {
      AppConfig.printConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,

      navigatorKey: appNavigatorKey,

      initialRoute: AppRoutes.splash,

      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ===================================================
      // SPLASH & ROOT
      // ===================================================
      case '/':
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      // ===================================================
      // LOGIN
      // ===================================================
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      // ===================================================
      // REGISTER
      // ===================================================
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      // ===================================================
      // FORGOT PASSWORD
      // ===================================================
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      // ===================================================
      // STUDENT
      // ===================================================
      case AppRoutes.studentHome:
        return MaterialPageRoute(
          builder: (_) => const StudentMainScreen(),
          settings: settings,
        );

      case AppRoutes.studentSubjects:
        return MaterialPageRoute(
          builder: (_) => const SubjectListScreen(),
          settings: settings,
        );

      case AppRoutes.studentDocuments:
        return MaterialPageRoute(
          builder: (_) => DocumentListScreen(
            initialSubjectId: args is String ? args : null,
          ),
          settings: settings,
        );

      case AppRoutes.studentDocumentDetail:
        if (args is! StudyDocument) {
          return MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(
              routeName: 'Document Detail',
              description: 'Dữ liệu tài liệu không hợp lệ.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(document: args),
          settings: settings,
        );

      // ===================================================
      // EXAM
      // ===================================================
      case AppRoutes.studentExams:
        return MaterialPageRoute(
          builder: (_) =>
              ExamListScreen(initialSubjectId: args is String ? args : null),
          settings: settings,
        );

      case AppRoutes.studentExamTaking:
        if (args is! Exam) {
          return MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(
              routeName: 'Taking Exam',
              description: 'Thiếu dữ liệu đề thi.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => ExamTakingScreen(exam: args),
          settings: settings,
        );

      case AppRoutes.studentExamResult:
        final resultArg = args is ExamResultData ? args : null;
        return MaterialPageRoute(
          builder: (_) => ExamResultScreen(result: resultArg),
          settings: settings,
        );

      // ===================================================
      // PROGRESS
      // ===================================================
      case AppRoutes.studentProgress:
        return MaterialPageRoute(
          builder: (_) => const ProgressScreen(),
          settings: settings,
        );

      case AppRoutes.studentHistory:
        final initialTab = args is int ? args : 0;
        return MaterialPageRoute(
          builder: (_) => StudentHistoryScreen(initialTab: initialTab),
          settings: settings,
        );

      // ===================================================
      // NOTIFICATION
      // ===================================================
      case AppRoutes.studentNotifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      // ===================================================
      // PROFILE
      // ===================================================
      case AppRoutes.studentProfile:
        return MaterialPageRoute(
          builder: (_) => const StudentProfileScreen(),
          settings: settings,
        );

      case AppRoutes.studentTeacherRequests:
        return MaterialPageRoute(
          builder: (_) => const StudentTeacherRequestsScreen(),
          settings: settings,
        );

      // ===================================================
      // TEACHER
      // ===================================================
      case AppRoutes.teacherDashboard:
        return MaterialPageRoute(
          builder: (_) => const TeacherDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.teacherClasses:
        return MaterialPageRoute(
          builder: (_) => const TeacherClassListScreen(),
          settings: settings,
        );

      case AppRoutes.teacherClassDetail:
        return MaterialPageRoute(
          builder: (_) =>
              TeacherClassDetailScreen(classId: args is String ? args : null),
          settings: settings,
        );

      case AppRoutes.teacherQuestions:
        return MaterialPageRoute(
          builder: (_) => const TeacherQuestionBankScreen(),
          settings: settings,
        );

      case AppRoutes.teacherSchedule:
        return MaterialPageRoute(
          builder: (_) => const TeacherScheduleScreen(),
          settings: settings,
        );

      case AppRoutes.teacherProfile:
        return MaterialPageRoute(
          builder: (_) => const TeacherProfileScreen(),
          settings: settings,
        );

      case AppRoutes.teacherStudents:
        return MaterialPageRoute(
          builder: (_) => const TeacherStudentsScreen(),
          settings: settings,
        );

      case AppRoutes.teacherExams:
        return MaterialPageRoute(
          builder: (_) => const TeacherExamManagementScreen(),
          settings: settings,
        );

      case AppRoutes.teacherExamCreate:
        return MaterialPageRoute(
          builder: (_) => const TeacherExamCreateScreen(),
          settings: settings,
        );

      case AppRoutes.teacherQuestionCreate:
        final mapArgs = args as Map<String, dynamic>?;
        final examId = mapArgs?['examId'] as String?;
        final examTitle = mapArgs?['examTitle'] as String?;
        if (examId == null || examId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Không tìm thấy ID đề thi.',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vui lòng chọn đề thi hợp lệ để tạo câu hỏi.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => appNavigatorKey.currentState?.pop(),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => TeacherQuestionCreateScreen(
            examId: examId,
            examTitle: examTitle ?? 'Đề thi',
          ),
          settings: settings,
        );

      // ===================================================
      // ADMIN
      // ===================================================
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminUserManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminDocuments:
        return MaterialPageRoute(
          builder: (_) => const AdminDocumentManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminExams:
        return MaterialPageRoute(
          builder: (_) => const AdminExamQuestionManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminReports:
        return MaterialPageRoute(
          builder: (_) => const AdminReportsScreen(),
          settings: settings,
        );

      // ===================================================
      // 404
      // ===================================================
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(child: Text('404 - ${settings.name}')),
          ),
        );
    }
  }
}
