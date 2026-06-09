/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'THPT Smart Learn';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String userRoleKey = 'user_role';
  static const String isLoggedInKey = 'is_logged_in';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleAdmin = 'admin';

  // API Endpoints (relative paths, base URL from config)
  static const String authLoginEndpoint = '/auth/login';
  static const String authRegisterEndpoint = '/auth/register';
  static const String authForgotPasswordEndpoint = '/auth/forgot-password';
  static const String authRefreshTokenEndpoint = '/auth/refresh-token';

  // Subject Names
  static const List<String> subjectNames = [
    'ToÃ¡n',
    'Ngá»¯ VÄƒn',
    'Tiáº¿ng Anh',
    'Váº­t LÃ½',
    'HÃ³a Há»c',
    'Sinh Há»c',
    'Lá»‹ch Sá»­',
    'Äá»‹a LÃ½',
    'CÃ´ng DÃ¢n',
    'Kinh Táº¿ & PhÃ¡p Luáº­t',
  ];

  // Mock Accounts
  static const Map<String, String> mockStudentAccount = {
    'email': 'student@example.com',
    'password': 'student123',
    'name': 'Nguyá»…n VÄƒn A',
    'role': roleStudent,
  };

  static const Map<String, String> mockTeacherAccount = {
    'email': 'teacher@gmail.com',
    'password': '123456',
    'name': 'Tráº§n Thá»‹ B',
    'role': roleTeacher,
  };

  static const Map<String, String> mockAdminAccount = {
    'email': 'admin@gmail.com',
    'password': '123456',
    'name': 'Admin User',
    'role': roleAdmin,
  };

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration socketTimeout = Duration(seconds: 10);

  // Database
  static const String dbName = 'thpt_smart_learn.db';
  static const int dbVersion = 1;

  // Notification
  static const int notificationChannelId = 1;
  static const String notificationChannelName = 'THPT Smart Learn';
  static const String notificationChannelDescription =
      'ThÃ´ng bÃ¡o tá»« á»©ng dá»¥ng THPT Smart Learn';
}

