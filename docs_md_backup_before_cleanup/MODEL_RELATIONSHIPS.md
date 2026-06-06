# 📊 DATA MODEL RELATIONSHIPS & ARCHITECTURE

## Complete Data Model Overview

### Entity Relationship Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION ARCHITECTURE                         │
└──────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │   AppUser   │
                              │  (3 roles)  │
                              └──────┬──────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                    │                    │
         ┌──────▼──────┐    ┌────────▼────────┐   ┌──────▼──────┐
         │  Student    │    │    Teacher      │   │    Admin    │
         │  (Role)     │    │    (Role)       │   │    (Role)   │
         └──────┬──────┘    └────────┬────────┘   └──────┬──────┘
                │                    │                    │
                │            ┌───────▼──────┐              │
                │            │ TeacherClass │              │
                │            │  (Lớp học)   │              │
                │            └────┬─────────┘              │
                │                 │                        │
                │                 │         ┌──────────────▼──┐
                │          ┌──────▼────┐    │AdminReportStat  │
                │          │  Subject  │    │ (Thống kê)      │
                │          │ (Môn học) │    └─────────────────┘
                │          └──────┬────┘
                │                 │
                └────────┬────────┘
                         │
                    ┌────▼─────┐
                    │   Topic  │
                    │(Chủ đề) │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼──────┐  ┌────▼──────┐  ┌────▼──────┐
    │Study Doc  │  │  Exam     │  │Notif Item │
    │(Tài liệu) │  │ (Đề thi)  │  │(Thông báo)│
    │           │  └────┬──────┘  └────┬──────┘
    │  - views  │       │              │
    │  - rating │       │          ┌───┴────────┐
    └───────────┘   ┌───▼──────┐   │NotificType │
                    │Question  │   │ (7 types)  │
                    │(Câu hỏi) │   └────────────┘
                    └───┬──────┘
                        │
                    ┌───▼──────────────┐
                    │ AnswerOption     │
                    │ (Lựa chọn)       │
                    │ - A, B, C, D...  │
                    └──────────────────┘

Student Flow:
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Student    │───▶│ ProgressStat │    │ ExamAttempt  │───▶│ ExamAnswer   │
│(User)        │    │ (Tiến độ học)│───▶│ (Lần làm)    │    │ (Câu trả lời)│
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                          △                     │
                          │                     │
                          └─────────────────────┘
                          (Linked by subjectId)
```

---

## 🔀 DATA FLOW EXAMPLES

### Student Taking an Exam

```
1. Student (AppUser)
   └─ Enrolls in Course (Subject)
      └─ Views Topics
         └─ Reads StudyDocuments
            └─ Views Exams
               └─ Starts ExamAttempt
                  └─ Answers Questions
                     └─ Records ExamAnswers
                        └─ Calculates ProgressStat
                           └─ Updates ProgressStat (streakDays, averageScore)
                              └─ Receives NotificationItem (results)
```

### Teacher Creating Content

```
1. Teacher (AppUser)
   └─ Creates Subject/Course
      └─ Creates Topics
         └─ Adds StudyDocuments
            └─ Creates Exams
               └─ Adds Questions
                  └─ Defines AnswerOptions
                     └─ Publishes (isPublished = true)
                        └─ Manages TeacherClass
```

### Admin Monitoring System

```
1. Admin (AppUser)
   └─ Generates AdminReportStat
      └─ Tracks:
         - Total Users (students + teachers)
         - Content Statistics (documents, exams)
         - Performance Metrics (averageScore, passRate)
         - Weekly Active Users
```

---

## 📈 FIELD TYPES SUMMARY

| Category | Type | Examples |
|----------|------|----------|
| **IDs** | String | user123, exam_001 |
| **Names** | String | "Toán", "Nguyễn Văn A" |
| **Scores** | double | 8.5, 9.0, 7.25 |
| **Counts** | int | 50, 120, 0 |
| **Booleans** | bool | isActive, isPassed, isCorrect |
| **Dates** | DateTime | createdAt, updatedAt |
| **Enums** | UserRole, NotificationType | student, info, success |
| **Lists** | List<AnswerOption>, etc. | [A, B, C, D] |

---

## 🔑 KEY RELATIONSHIPS

### One-to-Many
```
Subject (1) ─────▶ (Many) Topic
Subject (1) ─────▶ (Many) StudyDocument
Subject (1) ─────▶ (Many) Exam
Topic (1) ─────▶ (Many) StudyDocument
Exam (1) ─────▶ (Many) Question
Teacher (1) ─────▶ (Many) TeacherClass
Student (1) ─────▶ (Many) ExamAttempt
Student (1) ─────▶ (Many) ProgressStat
ExamAttempt (1) ─────▶ (Many) ExamAnswer
```

### Many-to-One
```
StudyDocument ─────▶ Topic
StudyDocument ─────▶ Subject
Exam ─────▶ Subject
Question ─────▶ Exam
ExamAttempt ─────▶ Exam
ExamAttempt ─────▶ AppUser (student)
ExamAnswer ─────▶ ExamAttempt
ExamAnswer ─────▶ Question
ProgressStat ─────▶ AppUser (student)
ProgressStat ─────▶ Subject
TeacherClass ─────▶ AppUser (teacher)
TeacherClass ─────▶ Subject
```

---

## 🎓 EXAMPLE DATA FLOW

### Scenario: Student completes an exam

```
1. Student views Exam (math exam, 50 questions, 120 minutes, 10 points)

2. Creates ExamAttempt:
   {
     id: "attempt_001",
     examId: "exam_math_001",
     studentId: "student_123",
     startedAt: 2026-05-24 09:00,
     score: 0.0 (initial),
     isPassed: false (initial),
     answeredQuestionCount: 0,
     totalQuestionCount: 50,
     isSubmitted: false
   }

3. For each Question (50 total):
   - Student reads Question with 4 AnswerOptions (A, B, C, D)
   - Student selects option and creates ExamAnswer:
   {
     id: "answer_001",
     examAttemptId: "attempt_001",
     questionId: "question_001",
     selectedOptionId: "option_B",
     answeredAt: 2026-05-24 09:05,
     isCorrect: true,
     earnedScore: 0.2 (10 / 50 questions)
   }

4. When exam completed (120 minutes or all answered):
   - Updates ExamAttempt:
   {
     completedAt: 2026-05-24 11:00,
     score: 8.5 (sum of earnedScores),
     isPassed: true (score > passingScore of 5),
     answeredQuestionCount: 50,
     isSubmitted: true
   }

5. Creates/Updates ProgressStat:
   {
     studentId: "student_123",
     subjectId: "subject_math",
     totalExamsTaken: 5,
     examsPassed: 4,
     averageScore: 8.2,
     streakDays: 7,
     lastStudyDate: 2026-05-24,
     completionPercentage: 80.0
   }

6. Sends NotificationItem:
   {
     id: "notif_001",
     userId: "student_123",
     title: "Kết quả thi",
     message: "Bạn đã hoàn thành bài thi với điểm 8.5/10",
     type: NotificationType.success,
     actionUrl: "/student/exam-result/attempt_001"
   }
```

---

## 💾 STORAGE CONSIDERATIONS

### Local Database (SQLite)
```sql
-- Tables to create
CREATE TABLE users (...)
CREATE TABLE subjects (...)
CREATE TABLE topics (...)
CREATE TABLE study_documents (...)
CREATE TABLE exams (...)
CREATE TABLE questions (...)
CREATE TABLE answer_options (...)
CREATE TABLE exam_attempts (...)
CREATE TABLE exam_answers (...)
CREATE TABLE progress_stats (...)
CREATE TABLE notifications (...)
CREATE TABLE teacher_classes (...)
CREATE TABLE admin_report_stats (...)
```

### API Endpoints
```
GET /subjects                    → List<Subject>
GET /subjects/:id                → Subject
GET /exams/:id/questions         → List<Question>
POST /exam-attempts              → ExamAttempt (new)
POST /exam-attempts/:id/answers  → ExamAnswer (submit answer)
GET /progress/subject/:id        → ProgressStat
GET /notifications               → List<NotificationItem>
```

---

## 🔐 Data Validation Rules

### AppUser
- email: must contain @
- role: must be student, teacher, or admin
- fullName: minimum 2 characters

### Exam
- questionCount > 0
- durationMinutes > 0
- totalScore > 0
- passingScore < totalScore

### ExamAttempt
- answeredQuestionCount <= totalQuestionCount
- score <= totalScore
- completedAt >= startedAt (if provided)

### ProgressStat
- examsPassed <= totalExamsTaken
- averageScore between 0 and 10
- completionPercentage between 0 and 100

---

## 🎯 Query Examples

### Get student progress for a subject
```dart
// Query ProgressStat where studentId and subjectId match
progressStats.where((p) => 
  p.studentId == 'student_123' && 
  p.subjectId == 'subject_math'
)
```

### Get exam results
```dart
// Query ExamAttempt for a student
examAttempts.where((a) => 
  a.studentId == 'student_123'
).orderBy((a) => a.completedAt).toList()
```

### Get teacher's classes
```dart
// Query TeacherClass for a teacher
teacherClasses.where((c) => 
  c.teacherId == 'teacher_456'
)
```

---

## 📝 Notes

- All IDs are String (use UUID or similar)
- All timestamps use DateTime (UTC recommended)
- Scores are double for precision (8.5, 9.25, etc.)
- Null safety applied throughout
- All models have fromJson, toJson, copyWith
- No hardcoded values in models
- Relationships managed through IDs
- Extensible for future features

---

**Status**: ✅ Complete
**Ready for**: Database schema creation & repositories
