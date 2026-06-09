/// Mock data for progress, notifications, and users
library;
import 'package:thpt_exam_prep_app/models.dart';

class MockProgressData {
  static final List<ProgressStat> progressStats = [
    ProgressStat(
      id: 'prog_001',
      studentId: 'student_001',
      subjectId: 'subj_001',
      totalDocumentsRead: 8,
      totalExamsTaken: 3,
      examsPassed: 2,
      averageScore: 7.2,
      streakDays: 5,
      lastStudyDate: DateTime.now(),
      completionPercentage: 65.0,
      updatedAt: DateTime.now(),
    ),
    ProgressStat(
      id: 'prog_002',
      studentId: 'student_001',
      subjectId: 'subj_002',
      totalDocumentsRead: 6,
      totalExamsTaken: 2,
      examsPassed: 2,
      averageScore: 8.1,
      streakDays: 3,
      lastStudyDate: DateTime.now().subtract(Duration(days: 1)),
      completionPercentage: 75.0,
      updatedAt: DateTime.now(),
    ),
    ProgressStat(
      id: 'prog_003',
      studentId: 'student_001',
      subjectId: 'subj_003',
      totalDocumentsRead: 5,
      totalExamsTaken: 2,
      examsPassed: 1,
      averageScore: 6.8,
      streakDays: 2,
      lastStudyDate: DateTime.now().subtract(Duration(days: 2)),
      completionPercentage: 55.0,
      updatedAt: DateTime.now(),
    ),
    ProgressStat(
      id: 'prog_004',
      studentId: 'student_001',
      subjectId: 'subj_004',
      totalDocumentsRead: 4,
      totalExamsTaken: 1,
      examsPassed: 0,
      averageScore: 4.5,
      streakDays: 1,
      lastStudyDate: DateTime.now().subtract(Duration(days: 3)),
      completionPercentage: 40.0,
      updatedAt: DateTime.now(),
    ),
  ];
}

class MockNotificationsData {
  static final List<NotificationItem> notifications = [
    NotificationItem(
      id: 'notif_001',
      userId: 'student_001',
      title: 'Bài kiểm tra mới',
      message: 'Đề thi thử Toán kỳ 1 đã được đăng. Hãy thử làm bài ngay!',
      type: NotificationType.examReminder,
      actionUrl: '/student/exam-detail/exam_001',
      isRead: false,
      createdAt: DateTime.now(),
      readAt: null,
    ),
    NotificationItem(
      id: 'notif_002',
      userId: 'student_001',
      title: 'Hoàn thành học tập',
      message: 'Bạn đã hoàn thành Bài 1: Hàm số bậc nhất. Tiếp tục với Bài 2!',
      type: NotificationType.success,
      actionUrl: '/student/document-detail/doc_002',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      readAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    NotificationItem(
      id: 'notif_003',
      userId: 'student_001',
      title: 'Thông báo công bố đáp án',
      message: 'Đáp án Đề thi thử Toán kỳ 1 đã được công bố. Kiểm tra bài của bạn!',
      type: NotificationType.announcement,
      actionUrl: '/student/exam-result/attempt_001',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      readAt: DateTime.now().subtract(Duration(days: 2, hours: 3)),
    ),
    NotificationItem(
      id: 'notif_004',
      userId: 'student_001',
      title: 'Nhắc nhở học tập',
      message: 'Bạn chưa học bất cứ điều gì hôm nay. Hãy dành thời gian ôn tập!',
      type: NotificationType.info,
      actionUrl: '/student/subjects',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      readAt: null,
    ),
    NotificationItem(
      id: 'notif_005',
      userId: 'student_001',
      title: 'Cảnh báo: Tiến độ chậm',
      message: 'Tiến độ học Tiếng Anh của bạn chỉ ở mức 55%. Hãy tăng cường học tập!',
      type: NotificationType.warning,
      actionUrl: '/student/progress',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      readAt: DateTime.now().subtract(Duration(days: 2, hours: 8)),
    ),
  ];
}

class MockUsersData {
  static final AppUser studentUser = AppUser(
    id: 'student_001',
    email: 'student@example.com',
    fullName: 'Nguyễn Văn A',
    role: UserRole.student,
    schoolName: 'THPT Phan Bội Châu',
    className: '12A1',
    profileImageUrl: null,
    bio: 'Học sinh lớp 12A1 - Ôn thi THPT 2025',
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  static final AppUser teacherUser = AppUser(
    id: 'teacher_001',
    email: 'teacher@gmail.com',
    fullName: 'Thầy Lê Văn B',
    role: UserRole.teacher,
    schoolName: 'THPT Phan Bội Châu',
    className: null,
    profileImageUrl: null,
    bio: 'Giáo viên Toán - 10 năm kinh nghiệm',
    createdAt: DateTime(2020, 5, 10),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  static final AppUser adminUser = AppUser(
    id: 'admin_001',
    email: 'admin@gmail.com',
    fullName: 'Quản trị viên Hệ thống',
    role: UserRole.admin,
    schoolName: 'THPT Phan Bội Châu',
    className: null,
    profileImageUrl: null,
    bio: 'Admin - Quản lý hệ thống ôn thi THPT',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  static final List<TeacherClass> teacherClasses = [
    TeacherClass(
      id: 'class_001',
      teacherId: 'teacher_001',
      subjectId: 'subj_001',
      className: '12A1',
      description: 'Lớp Toán 12A1',
      studentCount: 35,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
    TeacherClass(
      id: 'class_002',
      teacherId: 'teacher_001',
      subjectId: 'subj_001',
      className: '12A2',
      description: 'Lớp Toán 12A2',
      studentCount: 32,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final AdminReportStat adminReport = AdminReportStat(
    id: 'report_001',
    totalUsers: 127,
    totalStudents: 95,
    totalTeachers: 28,
    totalExams: 45,
    totalDocuments: 156,
    totalExamAttempts: 312,
    averageExamScore: 6.8,
    examPassRate: 68,
    activeUsersThisWeek: 82,
    generatedAt: DateTime.now(),
  );
}

