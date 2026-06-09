
// App Constants
class AppConstants {
  // App Info
  static const String appName = 'THPT Exam Prep';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Pagination
  static const int pageSize = 20;
  
  // Subject Names (Tiáº¿ng Viá»‡t)
  static const List<String> subjects = [
    'Toán học',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Lịch sử',
    'Địa lý',
    'Ngoại ngữ',
    'Ngữ văn',
  ];
}

// Exam Status
class ExamStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String archived = 'archived';
}

// User Role
class UserRole {
  static const String student = 'student';
  static const String teacher = 'teacher';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';
}

// Question Type
class QuestionType {
  static const String multipleChoice = 'multiple_choice';
  static const String shortAnswer = 'short_answer';
  static const String essay = 'essay';
}

// Progress Status
class ProgressStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String paused = 'paused';
}

// Document Type
class DocumentType {
  static const String lessonNote = 'lesson_note';
  static const String practiceExercise = 'practice_exercise';
  static const String summary = 'summary';
  static const String reference = 'reference';
}

