# 🚀 MOCK DATA & REPOSITORIES - QUICK START GUIDE

## 📦 What Was Delivered

✅ **5 Mock Data Files** with realistic test data  
✅ **8 Repository Implementations** with full CRUD  
✅ **Service Locator** for dependency injection  
✅ **100% Offline Functionality** - no internet needed  
✅ **Easy API Migration** when ready  

---

## 🔑 Test Accounts

```
STUDENT:
  Email: student@example.com
  Password: 123456

TEACHER:
  Email: teacher@example.com
  Password: 123456

ADMIN:
  Email: admin@example.com
  Password: 123456
```

---

## 💡 USAGE IN YOUR APP

### Get Repositories

```dart
import 'package:thpt_exam_prep_app/repository_service.dart';

final repos = RepositoryService.getInstance();
```

### Authentication

```dart
// Login
final user = await repos.auth.login('student@example.com', '123456');
if (user != null) {
  print('Logged in as: ${user.fullName}');
}

// Register
final newUser = await repos.auth.register(
  'newstudent@example.com',
  'password123',
  'Nguyễn Văn B',
  UserRole.student,
);

// Check if logged in
final isLoggedIn = await repos.auth.isLoggedIn();

// Logout
await repos.auth.logout();
```

### Subjects

```dart
// Get all subjects (9 total)
final subjects = await repos.subject.getAllSubjects();

// Get specific subject
final math = await repos.subject.getSubjectById('subj_001');

// Subject operations
await repos.subject.createSubject(newSubject);
await repos.subject.updateSubject(updatedSubject);
await repos.subject.deleteSubject('subj_001');
```

### Documents

```dart
// Get all documents (8 total)
final documents = await repos.document.getAllDocuments();

// Get by subject
final mathDocs = await repos.document.getDocumentsBySubject('subj_001');

// Get by topic
final topicDocs = await repos.document.getDocumentsByTopic('topic_001');

// Document operations
await repos.document.createDocument(newDoc);
await repos.document.updateDocument(updatedDoc);
await repos.document.deleteDocument('doc_001');
```

### Exams & Questions

```dart
// Get all exams (5 total)
final exams = await repos.exam.getAllExams();

// Get exams by subject
final mathExams = await repos.exam.getExamsBySubject('subj_001');

// Get questions for exam (25 total, 5 per exam)
final questions = await repos.exam.getQuestionsByExam('exam_001');

// Exam operations
await repos.exam.createExam(newExam);
await repos.exam.updateExam(updatedExam);
await repos.exam.deleteExam('exam_001');
```

### Progress Tracking

```dart
// Get student progress
final progress = await repos.progress.getProgressByStudent('student_001');

// Get progress for specific subject
final mathProgress = await repos.progress.getProgressByStudentSubject(
  'student_001',
  'subj_001',
);

// Get analytics
final avgScore = await repos.progress.getAverageScoreByStudent('student_001');
final totalExams = await repos.progress.getTotalExamsByStudent('student_001');
final passed = await repos.progress.getExamsPassedByStudent('student_001');

// Update progress
await repos.progress.updateProgress(updatedProgress);
```

### Notifications

```dart
// Get notifications
final notifs = await repos.notification.getNotificationsByUser('student_001');

// Get unread only
final unread = await repos.notification.getUnreadNotifications('student_001');

// Count unread
final count = await repos.notification.getUnreadCount('student_001');

// Mark as read
await repos.notification.markAsRead('notif_001');

// Mark all as read
await repos.notification.markAllAsRead('student_001');

// Send notification
await repos.notification.createNotification(newNotification);

// Delete notification
await repos.notification.deleteNotification('notif_001');
```

### Teacher Operations

```dart
// Get teacher's classes
final classes = await repos.teacher.getClassesByTeacher('teacher_001');

// Class operations
await repos.teacher.createClass(newClass);
await repos.teacher.updateClass(updatedClass);
await repos.teacher.deleteClass('class_001');

// Exam attempts
final attempts = await repos.teacher.getStudentAttemptsByTeacher('teacher_001');
await repos.teacher.createExamAttempt(newAttempt);
await repos.teacher.updateExamAttempt(updatedAttempt);
```

### Admin Operations

```dart
// Get system report
final report = await repos.admin.getSystemReport();
print('Total users: ${report.totalUsers}');
print('Total students: ${report.totalStudents}');
print('Pass rate: ${report.examPassRate}%');

// User management
final allUsers = await repos.admin.getAllUsers();
final students = await repos.admin.getUsersByRole(UserRole.student);
final teachers = await repos.admin.getUsersByRole(UserRole.teacher);

// User operations
await repos.admin.createUser(newUser);
await repos.admin.updateUser(updatedUser);
await repos.admin.deleteUser('user_001');

// Content management
final allExams = await repos.admin.getAllExams();
final allDocs = await repos.admin.getAllDocuments();
```

---

## 📂 FILES STRUCTURE

```
lib/
├── mock_subjects.dart              ← Subject mock data
├── mock_documents.dart             ← Document mock data
├── mock_exams.dart                 ← Exam & question mock data
├── mock_progress.dart              ← Progress & notification mock data
├── repo_auth.dart                  ← Auth repository
├── repo_subject.dart               ← Subject repository
├── repo_document.dart              ← Document repository
├── repo_exam.dart                  ← Exam repository
├── repo_progress.dart              ← Progress repository
├── repo_notification.dart          ← Notification repository
├── repo_teacher.dart               ← Teacher repository
├── repo_admin.dart                 ← Admin repository
└── repository_service.dart         ← Service locator
```

---

## 🔄 SWITCHING TO REAL API

### Current (Mock - Works Offline)
```dart
_authRepo = MockAuthRepository();
```

### When API is ready (Just 1 line!)
```dart
_authRepo = ApiAuthRepository(ApiClient());
```

**Same interface, different implementation!**

---

## ✨ DATA SUMMARY

| Category | Count | Details |
|----------|-------|---------|
| **Subjects** | 9 | All THPT subjects |
| **Documents** | 8 | Study materials |
| **Exams** | 5 | Full mock tests |
| **Questions** | 25 | 5 per exam |
| **Progress** | 4 | Multi-subject tracking |
| **Notifications** | 5 | Various types |
| **Users** | 3 | Student, teacher, admin |
| **Classes** | 2 | Teacher's classes |

---

## 🎯 EXAMPLE: Full Quiz Flow

```dart
// 1. Get exam
final exam = await repos.exam.getExamById('exam_001');
// → Returns: Exam with 5 questions

// 2. Get questions
final questions = await repos.exam.getQuestionsByExam('exam_001');
// → Returns: List of 5 Question objects

// 3. Show each question with 4 options
for (final question in questions) {
  print('Question: ${question.content}');
  for (final option in question.options) {
    print('  ${option.label}: ${option.content}');
  }
}

// 4. Student selects answer
final selectedOption = 'opt_b1'; // Student chooses B

// 5. Record answer
final examAnswer = ExamAnswer(
  id: 'answer_001',
  examAttemptId: 'attempt_001',
  questionId: 'q_001_001',
  selectedOptionId: selectedOption,
  answeredAt: DateTime.now(),
  isCorrect: selectedOption == 'opt_b1',
  earnedScore: 2.0,
);

// 6. Update progress after completing exam
final attempt = ExamAttempt(
  id: 'attempt_001',
  examId: 'exam_001',
  studentId: 'student_001',
  startedAt: startTime,
  completedAt: DateTime.now(),
  score: 8.5,
  isPassed: true,
  answeredQuestionCount: 5,
  totalQuestionCount: 5,
  isSubmitted: true,
);

await repos.exam.createExam(updatedExam);

// 7. Send notification
final notification = NotificationItem(
  id: 'notif_new',
  userId: 'student_001',
  title: 'Hoàn thành bài thi',
  message: 'Bạn đã hoàn thành bài thi với điểm 8.5/10',
  type: NotificationType.success,
  actionUrl: '/student/exam-result/attempt_001',
  isRead: false,
  createdAt: DateTime.now(),
);

await repos.notification.createNotification(notification);
```

---

## 📊 MOCK DATA HIGHLIGHTS

### Login Test Accounts
```
✅ Student account ready
✅ Teacher account ready
✅ Admin account ready
```

### Study Materials
```
✅ Hàm số bậc nhất (Math)
✅ Trích Chinh Phụ Ngâm (Lit)
✅ English Grammar Tenses
✅ Vật lý - Chuyển động
✅ Hóa học - Cân bằng phương trình
✅ Sinh học - DNA
✅ Lịch sử - Cách mạng Tháng Tám
```

### Practice Exams
```
✅ Toán kỳ 1 (5 questions)
✅ Ngữ Văn kỳ 1 (5 questions)
✅ Tiếng Anh kỳ 1 (5 questions)
✅ Vật Lý kỳ 1 (5 questions)
✅ Hóa Học kỳ 1 (5 questions)
```

Each question has:
- Question text
- 4 complete answers (A/B/C/D)
- Correct answer marked
- Detailed explanation

---

## 🛠️ IMPLEMENTATION CHECKLIST

- ✅ All 8 repositories implemented
- ✅ All CRUD operations working
- ✅ Mock data realistic
- ✅ Offline-first design
- ✅ Service locator pattern
- ✅ Type-safe code
- ✅ Easy API migration
- ✅ Test accounts ready
- ✅ Simulated delays (UX realistic)
- ✅ No network calls

---

## 🚀 READY FOR

✅ Screen implementation  
✅ Provider integration  
✅ UI development  
✅ User testing  
✅ MVP launch  
✅ API integration (later)  

---

**Status**: ✅ Production-Ready MVP Foundation
**Offline**: ✅ Yes - Works Without Internet
**API Ready**: ✅ Easy Migration Path

Start using repositories in your screens now!
