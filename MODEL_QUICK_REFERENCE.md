# 📚 MODEL QUICK REFERENCE GUIDE

## All 14 Models at a Glance

### 1️⃣ UserRole (Enum)
```dart
enum UserRole {
  student,   // Học sinh
  teacher,   // Giáo viên
  admin      // Quản trị viên
}
```
**Usage**: User authentication, authorization, routing

---

### 2️⃣ AppUser
```dart
AppUser(
  id: String,              // Unique ID
  email: String,           // Email address
  fullName: String,        // Full name
  role: UserRole,          // Role (student/teacher/admin)
  schoolName: String?,     // Optional school
  className: String?,      // Optional class
  phoneNumber: String?,    // Optional phone
  profileImageUrl: String?, // Optional avatar
  bio: String?,            // Optional bio
  createdAt: DateTime,     // Account creation
  updatedAt: DateTime,     // Last update
  isActive: bool,          // Account status
)
```

---

### 3️⃣ Subject (Môn học)
```dart
Subject(
  id: String,
  name: String,            // "Toán", "Ngữ Văn", etc.
  description: String,
  totalTopics: int,
  totalDocuments: int,
  totalExams: int,
  iconUrl: String?,
  color: String?,          // Hex color #RRGGBB
  createdAt: DateTime,
)

// Available subjects: Toán, Ngữ Văn, Tiếng Anh, Vật Lý, Hóa Học, Sinh Học, Lịch Sử, Địa Lý, Công Dân, KTPL
```

---

### 4️⃣ Topic (Chủ đề)
```dart
Topic(
  id: String,
  subjectId: String,       // Reference to Subject
  name: String,            // "Phương trình bậc 2", etc.
  description: String,
  orderNumber: int,        // Display order
  documentCount: int,      // Number of documents
  createdAt: DateTime,
)
```

---

### 5️⃣ StudyDocument (Tài liệu ôn tập)
```dart
StudyDocument(
  id: String,
  topicId: String,         // Reference to Topic
  subjectId: String,       // Reference to Subject
  title: String,
  description: String,
  content: String,         // Full document text/HTML
  thumbnailUrl: String?,   // Document preview image
  author: String,          // Document creator
  views: int,              // View count
  rating: double,          // Average rating (0-5)
  ratingCount: int,        // Number of ratings
  fileUrl: String?,        // Optional PDF/DOC link
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

---

### 6️⃣ Exam (Đề thi)
```dart
Exam(
  id: String,
  subjectId: String,       // Reference to Subject
  title: String,           // "Đề thi thử kỳ 1"
  description: String,
  questionCount: int,      // Total questions
  durationMinutes: int,    // Time limit (e.g., 120)
  totalScore: double,      // Max score (e.g., 10.0)
  passingScore: double,    // Pass threshold (e.g., 5.0)
  isPublished: bool,       // Available for students
  creatorId: String,       // Teacher who created it
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

---

### 7️⃣ AnswerOption (Lựa chọn câu trả lời)
```dart
AnswerOption(
  id: String,
  label: String,           // "A", "B", "C", "D"
  content: String,         // Answer text
  isCorrect: bool,         // Correct answer flag
)
```

---

### 8️⃣ Question (Câu hỏi)
```dart
Question(
  id: String,
  examId: String,          // Reference to Exam
  content: String,         // Question text
  explanation: String,     // Answer explanation
  orderNumber: int,        // Question order (1, 2, 3...)
  score: double,           // Points per correct answer
  options: List<AnswerOption>, // [A, B, C, D]
  createdAt: DateTime,
)
```

---

### 9️⃣ ExamAttempt (Lần làm bài thi)
```dart
ExamAttempt(
  id: String,
  examId: String,          // Reference to Exam
  studentId: String,       // Reference to AppUser (student)
  startedAt: DateTime,     // When started
  completedAt: DateTime?,  // When finished (optional)
  score: double,           // Final score (0-10)
  isPassed: bool,          // Score >= passingScore?
  answeredQuestionCount: int,
  totalQuestionCount: int,
  isSubmitted: bool,       // Finalized?
)

// Methods:
// getDurationMinutes() → int
// getAccuracyPercentage() → double (0-100)
```

---

### 🔟 ExamAnswer (Câu trả lời học sinh)
```dart
ExamAnswer(
  id: String,
  examAttemptId: String,   // Reference to ExamAttempt
  questionId: String,      // Reference to Question
  selectedOptionId: String, // Student's choice (A/B/C/D)
  answeredAt: DateTime,    // When answered
  isCorrect: bool,         // Correct?
  earnedScore: double,     // Points earned
)
```

---

### 1️⃣1️⃣ ProgressStat (Tiến độ học tập)
```dart
ProgressStat(
  id: String,
  studentId: String,       // Reference to AppUser (student)
  subjectId: String,       // Reference to Subject
  totalDocumentsRead: int,
  totalExamsTaken: int,
  examsPassed: int,
  averageScore: double,    // Average of all exams
  streakDays: int,         // Consecutive study days
  lastStudyDate: DateTime,
  completionPercentage: double, // 0-100
  updatedAt: DateTime,
)

// Methods:
// getSuccessRate() → double (examsPassed / totalExamsTaken * 100)
```

---

### 1️⃣2️⃣ NotificationItem (Thông báo)
```dart
enum NotificationType {
  info,           // 📘 General info
  warning,        // ⚠️ Warning
  success,        // ✅ Success
  error,          // ❌ Error
  announcement,   // 📣 Announcement
  examReminder,   // ⏰ Exam reminder
  assignmentDue   // 📝 Assignment due
}

NotificationItem(
  id: String,
  userId: String,          // Reference to AppUser
  title: String,           // "Kết quả thi"
  message: String,         // Notification message
  type: NotificationType,
  actionUrl: String?,      // Link to action
  isRead: bool,
  createdAt: DateTime,
  readAt: DateTime?,       // When read (optional)
)
```

---

### 1️⃣3️⃣ TeacherClass (Lớp học)
```dart
TeacherClass(
  id: String,
  teacherId: String,       // Reference to AppUser (teacher)
  subjectId: String,       // Reference to Subject
  className: String,       // "10A", "11B", etc.
  description: String,
  studentCount: int,       // Number of students
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

---

### 1️⃣4️⃣ AdminReportStat (Thống kê)
```dart
AdminReportStat(
  id: String,
  totalUsers: int,         // All users
  totalStudents: int,      // Only students
  totalTeachers: int,      // Only teachers
  totalExams: int,
  totalDocuments: int,
  totalExamAttempts: int,
  averageExamScore: double,
  examPassRate: int,       // Percentage 0-100
  activeUsersThisWeek: int,
  generatedAt: DateTime,
)

// Methods:
// getTeacherToStudentRatio() → double
// getExamPerDocumentRatio() → double
```

---

## 🎯 COMMON OPERATIONS

### Import All Models
```dart
import 'models.dart';
```

### Create Objects
```dart
// User
AppUser user = AppUser(
  id: 'user_001',
  email: 'student@example.com',
  fullName: 'Nguyễn Văn A',
  role: UserRole.student,
  createdAt: DateTime.now(),
);

// Subject
Subject math = Subject(
  id: 'subj_math',
  name: 'Toán',
  description: 'Ôn thi THPT Toán',
  totalTopics: 15,
  totalDocuments: 100,
  totalExams: 10,
  createdAt: DateTime.now(),
);

// Question with Options
Question q = Question(
  id: 'q_001',
  examId: 'exam_001',
  content: 'Giải phương trình 2x + 3 = 0',
  explanation: 'x = -3/2',
  orderNumber: 1,
  score: 0.2,
  options: [
    AnswerOption(id: 'a', label: 'A', content: 'x = -3/2', isCorrect: true),
    AnswerOption(id: 'b', label: 'B', content: 'x = 3/2', isCorrect: false),
    AnswerOption(id: 'c', label: 'C', content: 'x = 2/3', isCorrect: false),
    AnswerOption(id: 'd', label: 'D', content: 'x = -2/3', isCorrect: false),
  ],
  createdAt: DateTime.now(),
);
```

### JSON Conversion
```dart
// Serialize
Map<String, dynamic> userJson = user.toJson();
String jsonString = jsonEncode(userJson);

// Deserialize
AppUser userFromJson = AppUser.fromJson(jsonDecode(jsonString));
```

### Update with copyWith
```dart
// Update user name
AppUser updatedUser = user.copyWith(fullName: 'Nguyễn Văn B');

// Update progress score
ProgressStat updatedProgress = progress.copyWith(averageScore: 9.0);
```

### Calculate Values
```dart
// Exam attempt duration
int duration = examAttempt.getDurationMinutes();

// Student accuracy
double accuracy = examAttempt.getAccuracyPercentage();

// Progress success rate
double passRate = progressStat.getSuccessRate();

// Report ratios
double teacherRatio = report.getTeacherToStudentRatio();
double examRatio = report.getExamPerDocumentRatio();
```

---

## 🔍 TYPE SAFETY CHECKLIST

- ✅ No `dynamic` type used
- ✅ All IDs are `String`
- ✅ All scores are `double`
- ✅ All counts are `int`
- ✅ All dates are `DateTime`
- ✅ Enums for roles, notification types
- ✅ Lists are strongly typed
- ✅ Null safety with `?` operator
- ✅ Safe DateTime parsing with fallback
- ✅ Safe type casting in fromJson

---

## 📋 JSON EXAMPLE

```json
{
  "appUser": {
    "id": "user_001",
    "email": "student@example.com",
    "fullName": "Nguyễn Văn A",
    "role": "student",
    "schoolName": "THPT Phan Bội Châu",
    "className": "12A1",
    "createdAt": "2026-01-15T10:30:00Z",
    "updatedAt": "2026-05-24T14:45:00Z",
    "isActive": true
  },
  "exam": {
    "id": "exam_001",
    "subjectId": "subj_math",
    "title": "Đề thi thử toán kỳ 1",
    "questionCount": 50,
    "durationMinutes": 120,
    "totalScore": 10.0,
    "passingScore": 5.0,
    "isPublished": true,
    "creatorId": "teacher_001",
    "createdAt": "2026-03-01T09:00:00Z"
  },
  "question": {
    "id": "q_001",
    "examId": "exam_001",
    "content": "Giải phương trình bậc 2",
    "explanation": "Dùng công thức nghiệm",
    "orderNumber": 1,
    "score": 0.2,
    "options": [
      {
        "id": "opt_a",
        "label": "A",
        "content": "x = 1 hoặc x = 2",
        "isCorrect": true
      },
      {
        "id": "opt_b",
        "label": "B",
        "content": "x = 2 hoặc x = 3",
        "isCorrect": false
      }
    ],
    "createdAt": "2026-03-01T09:00:00Z"
  }
}
```

---

## 🚀 NEXT STEPS

1. Move models to `lib/data/models/` directory
2. Create repositories for data access
3. Implement local database (sqflite)
4. Create API service layer
5. Implement state management (providers)
6. Build screen implementations

---

**All 14 Models**: ✅ Ready
**Type Safety**: ✅ Enforced  
**Production Ready**: ✅ Yes
