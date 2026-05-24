import 'package:flutter/material.dart';

import 'app_config.dart';
import 'app_navigation.dart';
import 'app_routes.dart';
import 'app_theme.dart';

import 'models.dart';
import 'placeholder_screen.dart';

// ================= ADMIN =================
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_document_management_screen.dart';
import 'screens/admin/admin_exam_question_management_screen.dart';
import 'screens/admin/admin_reports_screen.dart';
import 'screens/admin/admin_user_management_screen.dart';

// ================= EXAM =================
import 'screens/exam/exam_list_screen.dart';
import 'screens/exam/exam_result_screen.dart';
import 'screens/exam/exam_taking_screen.dart';

// ================= NOTIFICATION =================
import 'screens/notification/notification_screen.dart';

// ================= PROGRESS =================
import 'screens/progress/progress_screen.dart';

// ================= PROFILE =================
import 'screens/profile/student_profile_screen.dart';

// ================= TEACHER =================
import 'screens/teacher/teacher_class_detail_screen.dart';
import 'screens/teacher/teacher_class_list_screen.dart';
import 'screens/teacher/teacher_dashboard_screen.dart';
import 'screens/teacher/teacher_profile_screen.dart';
import 'screens/teacher/teacher_question_bank_screen.dart';
import 'screens/teacher/teacher_schedule_screen.dart';

// ================= NEW SCREENS =================
import 'screens_new_document_detail.dart';
import 'screens_new_document_list.dart';

import 'screens_new_forgot_password.dart';
import 'screens_new_login.dart';
import 'screens_new_register.dart';
import 'screens_new_reset_password.dart';

import 'screens_new_splash.dart';
import 'screens_new_student_home.dart';
import 'screens_new_student_main.dart';
import 'screens_new_subject_list.dart';

class ThptSmartLearnApp extends StatefulWidget {
  const ThptSmartLearnApp({super.key});

  @override
  State<ThptSmartLearnApp> createState() =>
      _ThptSmartLearnAppState();
}

class _ThptSmartLearnAppState
    extends State<ThptSmartLearnApp> {
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

  Route<dynamic>? _generateRoute(
      RouteSettings settings) {
    final args = settings.arguments;

    // =========================================================
    // FIX WEB RESET PASSWORD URL
    // =========================================================
    final uri = Uri.parse(
      settings.name ?? '',
    );

    // Ví dụ:
    // /reset-password?token=abc123
    if (uri.path == '/reset-password') {
      final token =
          uri.queryParameters['token'] ?? '';

      return MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          token: token,
        ),
        settings: settings,
      );
    }

    switch (settings.name) {
      // ===================================================
      // SPLASH
      // ===================================================
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
          builder: (_) =>
              const RegisterScreen(),
          settings: settings,
        );

      // ===================================================
      // FORGOT PASSWORD
      // ===================================================
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) =>
              const ForgotPasswordScreen(),
          settings: settings,
        );

      // ===================================================
      // STUDENT
      // ===================================================
      case AppRoutes.studentHome:
        return MaterialPageRoute(
          builder: (_) =>
              const StudentMainScreen(),
          settings: settings,
        );

      case AppRoutes.studentSubjects:
        return MaterialPageRoute(
          builder: (_) =>
              const SubjectListScreen(),
          settings: settings,
        );

      case AppRoutes.studentDocuments:
        return MaterialPageRoute(
          builder: (_) => DocumentListScreen(
            initialSubjectId:
                args is String ? args : null,
          ),
          settings: settings,
        );

      case AppRoutes.studentDocumentDetail:
        if (args is! StudyDocument) {
          return MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(
              routeName: 'Document Detail',
              description:
                  'Dữ liệu tài liệu không hợp lệ.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) =>
              DocumentDetailScreen(
            document: args,
          ),
          settings: settings,
        );

      // ===================================================
      // EXAM
      // ===================================================
      case AppRoutes.studentExams:
        return MaterialPageRoute(
          builder: (_) => ExamListScreen(
            initialSubjectId:
                args is String ? args : null,
          ),
          settings: settings,
        );

      case AppRoutes.studentExamTaking:
        if (args is! Exam) {
          return MaterialPageRoute(
            builder: (_) => const PlaceholderScreen(
              routeName: 'Taking Exam',
              description:
                  'Thiếu dữ liệu đề thi.',
            ),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) =>
              ExamTakingScreen(exam: args),
          settings: settings,
        );

      case AppRoutes.studentExamResult:
        return MaterialPageRoute(
          builder: (_) =>
              const ExamResultScreen(),
          settings: settings,
        );

      // ===================================================
      // PROGRESS
      // ===================================================
      case AppRoutes.studentProgress:
        return MaterialPageRoute(
          builder: (_) =>
              const ProgressScreen(),
          settings: settings,
        );

      // ===================================================
      // NOTIFICATION
      // ===================================================
      case AppRoutes.studentNotifications:
        return MaterialPageRoute(
          builder: (_) =>
              const NotificationScreen(),
          settings: settings,
        );

      // ===================================================
      // PROFILE
      // ===================================================
      case AppRoutes.studentProfile:
        return MaterialPageRoute(
          builder: (_) =>
              const StudentProfileScreen(),
          settings: settings,
        );

      // ===================================================
      // TEACHER
      // ===================================================
      case AppRoutes.teacherDashboard:
        return MaterialPageRoute(
          builder: (_) =>
              const TeacherDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.teacherClasses:
        return MaterialPageRoute(
          builder: (_) =>
              const TeacherClassListScreen(),
          settings: settings,
        );

      case AppRoutes.teacherClassDetail:
        return MaterialPageRoute(
          builder: (_) =>
              TeacherClassDetailScreen(
            classId:
                args is String ? args : null,
          ),
          settings: settings,
        );

      case AppRoutes.teacherQuestions:
        return MaterialPageRoute(
          builder: (_) =>
              const TeacherQuestionBankScreen(),
          settings: settings,
        );

      case AppRoutes.teacherSchedule:
        return MaterialPageRoute(
          builder: (_) =>
              const TeacherScheduleScreen(),
          settings: settings,
        );

      case AppRoutes.teacherProfile:
        return MaterialPageRoute(
          builder: (_) =>
              const TeacherProfileScreen(),
          settings: settings,
        );

      // ===================================================
      // ADMIN
      // ===================================================
      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminDashboardScreen(),
          settings: settings,
        );

      case AppRoutes.adminUsers:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminUserManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminDocuments:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminDocumentManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminExams:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminExamQuestionManagementScreen(),
          settings: settings,
        );

      case AppRoutes.adminReports:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminReportsScreen(),
          settings: settings,
        );

      // ===================================================
      // 404
      // ===================================================
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title:
                  const Text('Page Not Found'),
            ),
            body: Center(
              child: Text(
                '404 - ${settings.name}',
              ),
            ),
          ),
        );
    }
  }
}