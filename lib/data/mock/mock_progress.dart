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
      title: 'BÃ i kiá»ƒm tra má»›i',
      message: 'Äá» thi thá»­ ToÃ¡n ká»³ 1 Ä‘Ã£ Ä‘Æ°á»£c Ä‘Äƒng. HÃ£y thá»­ lÃ m bÃ i ngay!',
      type: NotificationType.examReminder,
      actionUrl: '/student/exam-detail/exam_001',
      isRead: false,
      createdAt: DateTime.now(),
      readAt: null,
    ),
    NotificationItem(
      id: 'notif_002',
      userId: 'student_001',
      title: 'HoÃ n thÃ nh há»c táº­p',
      message: 'Báº¡n Ä‘Ã£ hoÃ n thÃ nh BÃ i 1: HÃ m sá»‘ báº­c nháº¥t. Tiáº¿p tá»¥c vá»›i BÃ i 2!',
      type: NotificationType.success,
      actionUrl: '/student/document-detail/doc_002',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      readAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    NotificationItem(
      id: 'notif_003',
      userId: 'student_001',
      title: 'ThÃ´ng bÃ¡o cÃ´ng bá»‘ Ä‘Ã¡p Ã¡n',
      message: 'ÄÃ¡p Ã¡n Äá» thi thá»­ ToÃ¡n ká»³ 1 Ä‘Ã£ Ä‘Æ°á»£c cÃ´ng bá»‘. Kiá»ƒm tra bÃ i cá»§a báº¡n!',
      type: NotificationType.announcement,
      actionUrl: '/student/exam-result/attempt_001',
      isRead: true,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      readAt: DateTime.now().subtract(Duration(days: 2, hours: 3)),
    ),
    NotificationItem(
      id: 'notif_004',
      userId: 'student_001',
      title: 'Nháº¯c nhá»Ÿ há»c táº­p',
      message: 'Báº¡n chÆ°a há»c báº¥t cá»© Ä‘iá»u gÃ¬ hÃ´m nay. HÃ£y dÃ nh thá»i gian Ã´n táº­p!',
      type: NotificationType.info,
      actionUrl: '/student/subjects',
      isRead: false,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      readAt: null,
    ),
    NotificationItem(
      id: 'notif_005',
      userId: 'student_001',
      title: 'Cáº£nh bÃ¡o: Tiáº¿n Ä‘á»™ cháº­m',
      message: 'Tiáº¿n Ä‘á»™ há»c Tiáº¿ng Anh cá»§a báº¡n chá»‰ á»Ÿ má»©c 55%. HÃ£y tÄƒng cÆ°á»ng há»c táº­p!',
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
    fullName: 'Nguyá»…n VÄƒn A',
    role: UserRole.student,
    schoolName: 'THPT Phan Bá»™i ChÃ¢u',
    className: '12A1',
    profileImageUrl: null,
    bio: 'Há»c sinh lá»›p 12A1 - Ã”n thi THPT 2025',
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  static final AppUser teacherUser = AppUser(
    id: 'teacher_001',
    email: 'teacher@gmail.com',
    fullName: 'Tháº§y LÃª VÄƒn B',
    role: UserRole.teacher,
    schoolName: 'THPT Phan Bá»™i ChÃ¢u',
    className: null,
    profileImageUrl: null,
    bio: 'GiÃ¡o viÃªn ToÃ¡n - 10 nÄƒm kinh nghiá»‡m',
    createdAt: DateTime(2020, 5, 10),
    updatedAt: DateTime.now(),
    isActive: true,
  );

  static final AppUser adminUser = AppUser(
    id: 'admin_001',
    email: 'admin@gmail.com',
    fullName: 'Quáº£n trá»‹ viÃªn Há»‡ thá»‘ng',
    role: UserRole.admin,
    schoolName: 'THPT Phan Bá»™i ChÃ¢u',
    className: null,
    profileImageUrl: null,
    bio: 'Admin - Quáº£n lÃ½ há»‡ thá»‘ng Ã´n thi THPT',
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
      description: 'Lá»›p ToÃ¡n 12A1',
      studentCount: 35,
      createdAt: DateTime.now().subtract(Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
    TeacherClass(
      id: 'class_002',
      teacherId: 'teacher_001',
      subjectId: 'subj_001',
      className: '12A2',
      description: 'Lá»›p ToÃ¡n 12A2',
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

