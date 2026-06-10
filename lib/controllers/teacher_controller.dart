import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class TeacherStudentSummary {
  final String id; // Added to identify the student
  final String name;
  final String email;
  final double averageScore;
  final double completionPercentage;
  final int totalExamsTaken;
  final int examsPassed;
  final int streakDays;

  const TeacherStudentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.averageScore,
    required this.completionPercentage,
    required this.totalExamsTaken,
    required this.examsPassed,
    required this.streakDays,
  });
}

class TeacherQuestionSummary {
  final Exam exam;
  final Subject subject;
  final Question question;
  final String correctAnswer;
  final String difficulty;
  final String status;

  const TeacherQuestionSummary({
    required this.exam,
    required this.subject,
    required this.question,
    required this.correctAnswer,
    required this.difficulty,
    required this.status,
  });
}

class TeacherScheduleItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime startTime;
  final int durationMinutes;
  final IconData icon;
  final Color color;

  const TeacherScheduleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.durationMinutes,
    required this.icon,
    required this.color,
  });
}

class TeacherController extends ChangeNotifier {
  bool _isLoading = false;
  String? _teacherId;
  AppUser? _teacher;
  List<TeacherClass> _classes = [];
  List<Subject> _subjects = [];
  List<Exam> _assignedExams = [];
  List<TeacherQuestionSummary> _questionBank = [];
  List<TeacherScheduleItem> _schedule = [];
  Map<String, List<TeacherStudentSummary>> _studentsByClass = {};
  int _totalStudents = 0;

  // Leaderboard fields
  List<ClassLeaderboardItem> _classLeaderboard = [];
  bool _isLeaderboardLoading = false;

  bool get isLoading => _isLoading;
  AppUser? get teacher => _teacher;
  List<TeacherClass> get classes => List.unmodifiable(_classes);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Exam> get assignedExams => List.unmodifiable(_assignedExams);
  List<TeacherQuestionSummary> get questionBank => List.unmodifiable(_questionBank);
  List<TeacherScheduleItem> get schedule => List.unmodifiable(_schedule);
  Map<String, List<TeacherStudentSummary>> get studentsByClass => _studentsByClass;
  int get totalStudents => _totalStudents;

  List<ClassLeaderboardItem> get classLeaderboard => _classLeaderboard;
  bool get isLeaderboardLoading => _isLeaderboardLoading;

  double get averageProgress {
    final allStudents = _studentsByClass.values.expand((list) => list).toList();
    if (allStudents.isEmpty) return 0.0;
    final total = allStudents.fold<double>(
      0.0,
      (acc, student) => acc + student.completionPercentage,
    );
    return total / allStudents.length;
  }

  Future<void> ensureLoaded(AppUser? teacher, {bool force = false}) async {
    if (teacher == null || teacher.role != UserRole.teacher) return;
    if (!force && _teacherId == teacher.id && _classes.isNotEmpty) return;
    await loadTeacher(teacher);
  }

  Future<void> loadTeacher(AppUser teacher) async {
    _isLoading = true;
    notifyListeners();

    try {
      _teacher = teacher;
      _teacherId = teacher.id;

      final service = RepositoryService.instance;

      // Load accepted student count from repository
      final loadedStudentCount = await service.teacher
          .getAcceptedStudentCount(teacher.id)
          .timeout(const Duration(seconds: 12));
      _totalStudents = loadedStudentCount;

      // Print debug logs in debug mode (development)
      if (kDebugMode) {
        debugPrint('--- Teacher Dashboard Query ---');
        debugPrint('Current FirebaseAuth UID: ${FirebaseAuth.instance.currentUser?.uid}');
        debugPrint('Teacher model id: ${teacher.id}');
        debugPrint('Firestore collection queried: teacher_student_requests');
        debugPrint('Accepted student query result length: $_totalStudents');
        debugPrint('--------------------------------');
      }

      final loadedClasses = await service.teacher
          .getClassesByTeacher(teacher.id)
          .timeout(const Duration(seconds: 12));
      final loadedSubjects = await service.subject.getAllSubjects().timeout(
        const Duration(seconds: 12),
      );
      final allExams = (await service.exam.getAllExams().timeout(
        const Duration(seconds: 12),
      )).take(20).toList();

      final subjectIds = loadedClasses.map((c) => c.subjectId).toSet();

      _classes = loadedClasses;
      _subjects = loadedSubjects;
      _assignedExams = allExams.where((exam) => subjectIds.contains(exam.subjectId)).toList();
      
      _questionBank = await _loadQuestionBank(
        service,
        _assignedExams,
        loadedSubjects,
      );

      // Load real students in classes
      _studentsByClass = {};
      for (final teacherClass in loadedClasses) {
        if (teacherClass.studentIds.isEmpty) {
          _studentsByClass[teacherClass.id] = [];
          continue;
        }

        // Fetch students' AppUsers
        final List<AppUser> students = [];
        for (var i = 0; i < teacherClass.studentIds.length; i += 10) {
          final batch = teacherClass.studentIds.sublist(
            i, 
            i + 10 > teacherClass.studentIds.length ? teacherClass.studentIds.length : i + 10
          );
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('uid', whereIn: batch)
              .get();
          students.addAll(snapshot.docs.map((doc) => AppUser.fromFirestore(doc)));
        }

        // Fetch students' progress stats
        final List<StudentProgress> progressList = [];
        for (var i = 0; i < teacherClass.studentIds.length; i += 10) {
          final batch = teacherClass.studentIds.sublist(
            i, 
            i + 10 > teacherClass.studentIds.length ? teacherClass.studentIds.length : i + 10
          );
          final snapshot = await FirebaseFirestore.instance
              .collection('progress_stats')
              .where('studentId', whereIn: batch)
              .get();
          progressList.addAll(snapshot.docs.map((doc) => StudentProgress.fromFirestore(doc)));
        }

        // Build summaries
        final summaries = <TeacherStudentSummary>[];
        for (final student in students) {
          final progress = progressList.cast<StudentProgress?>().firstWhere(
            (p) => p?.studentId == student.id,
            orElse: () => null,
          );

          if (progress == null) {
            summaries.add(
              TeacherStudentSummary(
                id: student.id,
                name: student.fullName,
                email: student.email,
                averageScore: 0.0,
                completionPercentage: 0.0,
                totalExamsTaken: 0,
                examsPassed: 0,
                streakDays: 0,
              ),
            );
          } else {
            final subjectStat = progress.subjectProgress.cast<ProgressStat?>().firstWhere(
              (p) => p?.subjectId == teacherClass.subjectId,
              orElse: () => null,
            );

            if (subjectStat == null) {
              summaries.add(
                TeacherStudentSummary(
                  id: student.id,
                  name: student.fullName,
                  email: student.email,
                  averageScore: 0.0,
                  completionPercentage: 0.0,
                  totalExamsTaken: 0,
                  examsPassed: 0,
                  streakDays: 0,
                ),
              );
            } else {
              summaries.add(
                TeacherStudentSummary(
                  id: student.id,
                  name: student.fullName,
                  email: student.email,
                  averageScore: subjectStat.averageScore,
                  completionPercentage: subjectStat.completionPercentage,
                  totalExamsTaken: subjectStat.totalExamsTaken,
                  examsPassed: subjectStat.examsPassed,
                  streakDays: subjectStat.streakDays,
                ),
              );
            }
          }
        }

        _studentsByClass[teacherClass.id] = summaries;
      }

      _schedule = _buildSchedule(loadedClasses, loadedSubjects, _assignedExams);
    } catch (e) {
      debugPrint('Không tải được dữ liệu giáo viên: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Class Management Actions
  Future<bool> createNewClass({
    required String className,
    required String subjectId,
    required String description,
  }) async {
    if (_teacherId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final classId = 'class_${DateTime.now().millisecondsSinceEpoch}';
      final newClass = TeacherClass(
        id: classId,
        teacherId: _teacherId!,
        teacherIds: [_teacherId!],
        studentIds: [],
        className: className,
        subjectId: subjectId,
        description: description,
        studentCount: 0,
        createdAt: DateTime.now(),
      );

      final service = RepositoryService.instance;
      await service.teacher.createClass(newClass);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_teacherId)
          .update({
            'managedClassIds': FieldValue.arrayUnion([classId]),
          });

      await loadTeacher(_teacher!);
      return true;
    } catch (e) {
      debugPrint('Lỗi tạo lớp học: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editClassName({
    required String classId,
    required String newClassName,
  }) async {
    final targetClass = classById(classId);
    if (targetClass == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedClass = targetClass.copyWith(
        className: newClassName,
        updatedAt: DateTime.now(),
      );

      final service = RepositoryService.instance;
      await service.teacher.updateClass(updatedClass);

      await loadTeacher(_teacher!);
      return true;
    } catch (e) {
      debugPrint('Lỗi sửa tên lớp học: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteClass(String classId) async {
    if (_teacherId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final service = RepositoryService.instance;
      await service.teacher.deleteClass(classId);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_teacherId)
          .update({
            'managedClassIds': FieldValue.arrayRemove([classId]),
          });

      await loadTeacher(_teacher!);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa lớp học: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStudentToClass({
    required String classId,
    required String studentId,
  }) async {
    final targetClass = classById(classId);
    if (targetClass == null) return false;

    if (targetClass.studentIds.contains(studentId)) {
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
            'studentIds': FieldValue.arrayUnion([studentId]),
            'studentCount': FieldValue.increment(1),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .update({
            'classIds': FieldValue.arrayUnion([classId]),
            'primaryClassId': classId,
          });

      await loadTeacher(_teacher!);
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm học sinh vào lớp: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    final targetClass = classById(classId);
    if (targetClass == null) return false;

    if (!targetClass.studentIds.contains(studentId)) {
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
            'studentIds': FieldValue.arrayRemove([studentId]),
            'studentCount': FieldValue.increment(-1),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .update({
            'classIds': FieldValue.arrayRemove([classId]),
          });

      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        final currentPrimary = data['primaryClassId'] as String?;
        if (currentPrimary == classId) {
          final currentClassIds = (data['classIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
          final newPrimary = currentClassIds.isNotEmpty ? currentClassIds.first : null;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .update({
                'primaryClassId': newPrimary,
              });
        }
      }

      await loadTeacher(_teacher!);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa học sinh khỏi lớp: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Leaderboard Calculation (Phase 3)
  Future<void> loadClassLeaderboard(String classId) async {
    _isLeaderboardLoading = true;
    notifyListeners();

    try {
      final targetClass = classById(classId);
      if (targetClass == null || targetClass.studentIds.isEmpty) {
        _classLeaderboard = [];
        return;
      }

      // Fetch students' AppUsers
      final List<AppUser> students = [];
      for (var i = 0; i < targetClass.studentIds.length; i += 10) {
        final batch = targetClass.studentIds.sublist(
          i, 
          i + 10 > targetClass.studentIds.length ? targetClass.studentIds.length : i + 10
        );
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', whereIn: batch)
            .get();
        students.addAll(snapshot.docs.map((doc) => AppUser.fromFirestore(doc)));
      }

      // Fetch students' overall progress stats
      final List<StudentProgress> progressList = [];
      for (var i = 0; i < targetClass.studentIds.length; i += 10) {
        final batch = targetClass.studentIds.sublist(
          i, 
          i + 10 > targetClass.studentIds.length ? targetClass.studentIds.length : i + 10
        );
        final snapshot = await FirebaseFirestore.instance
            .collection('progress_stats')
            .where('studentId', whereIn: batch)
            .get();
        progressList.addAll(snapshot.docs.map((doc) => StudentProgress.fromFirestore(doc)));
      }

      final items = <ClassLeaderboardItem>[];
      for (final student in students) {
        final progress = progressList.cast<StudentProgress?>().firstWhere(
          (p) => p?.studentId == student.id,
          orElse: () => null,
        );

        if (progress == null) {
          items.add(
            ClassLeaderboardItem(
              rank: 0,
              studentId: student.id,
              studentName: student.fullName,
              studentEmail: student.email,
              totalExamsCompleted: 0,
              averageScore: 0.0,
              documentsRead: 0,
              overallProgressPercentage: 0.0,
            ),
          );
        } else {
          items.add(
            ClassLeaderboardItem(
              rank: 0,
              studentId: student.id,
              studentName: student.fullName,
              studentEmail: student.email,
              totalExamsCompleted: progress.totalExamsCompleted,
              averageScore: progress.averageScore,
              documentsRead: progress.documentsRead,
              overallProgressPercentage: progress.overallProgressPercentage,
            ),
          );
        }
      }

      // Sorting rule:
      // 1. Higher average score ranks higher.
      // 2. If tied, higher total exams completed.
      // 3. If still tied, higher documents read.
      items.sort((left, right) {
        if (left.averageScore != right.averageScore) {
          return right.averageScore.compareTo(left.averageScore);
        }
        if (left.totalExamsCompleted != right.totalExamsCompleted) {
          return right.totalExamsCompleted.compareTo(left.totalExamsCompleted);
        }
        return right.documentsRead.compareTo(left.documentsRead);
      });

      _classLeaderboard = List.generate(items.length, (index) {
        final item = items[index];
        return ClassLeaderboardItem(
          rank: index + 1,
          studentId: item.studentId,
          studentName: item.studentName,
          studentEmail: item.studentEmail,
          totalExamsCompleted: item.totalExamsCompleted,
          averageScore: item.averageScore,
          documentsRead: item.documentsRead,
          overallProgressPercentage: item.overallProgressPercentage,
        );
      });
    } catch (e) {
      debugPrint('Lỗi tải bảng xếp hạng lớp: $e');
      _classLeaderboard = [];
    } finally {
      _isLeaderboardLoading = false;
      notifyListeners();
    }
  }

  Future<List<TeacherQuestionSummary>> _loadQuestionBank(
    RepositoryService service,
    List<Exam> exams,
    List<Subject> subjects,
  ) async {
    final entries = <TeacherQuestionSummary>[];
    for (final exam in exams) {
      final questions = await service.exam.getQuestionsByExam(exam.id);
      final subject = _findSubject(subjects, exam.subjectId);
      if (subject == null) continue;

      for (final question in questions) {
        final correctOption =
            question.options.where((option) => option.isCorrect).isNotEmpty
            ? question.options.firstWhere((option) => option.isCorrect)
            : null;
        entries.add(
          TeacherQuestionSummary(
            exam: exam,
            subject: subject,
            question: question,
            correctAnswer: correctOption?.content ?? 'Chưa xác định',
            difficulty: _buildDifficulty(question),
            status: exam.isPublished ? 'Đã phát hành' : 'Nháp',
          ),
        );
      }
    }

    entries.sort(
      (left, right) =>
          left.question.orderNumber.compareTo(right.question.orderNumber),
    );
    return entries;
  }

  List<TeacherScheduleItem> _buildSchedule(
    List<TeacherClass> classes,
    List<Subject> subjects,
    List<Exam> exams,
  ) {
    final now = DateTime.now();
    final schedule = <TeacherScheduleItem>[];

    for (var index = 0; index < classes.length; index++) {
      final teacherClass = classes[index];
      final subject = _findSubject(subjects, teacherClass.subjectId);
      schedule.add(
        TeacherScheduleItem(
          id: 'lesson_${teacherClass.id}',
          title: 'Dạy ${teacherClass.className}',
          subtitle:
              '${subject?.name ?? 'Môn học'} • ${teacherClass.studentCount} học sinh',
          startTime: DateTime(
            now.year,
            now.month,
            now.day + index + 1,
            7 + index,
            30,
          ),
          durationMinutes: 90,
          icon: Icons.class_,
          color: Colors.blue,
        ),
      );
    }

    for (var index = 0; index < exams.length; index++) {
      final exam = exams[index];
      final subject = _findSubject(subjects, exam.subjectId);
      schedule.add(
        TeacherScheduleItem(
          id: 'exam_${exam.id}',
          title: 'Giao ${exam.title}',
          subtitle:
              '${subject?.name ?? 'Môn học'} • ${exam.questionCount} câu',
          startTime: DateTime(now.year, now.month, now.day + index + 2, 19, 0),
          durationMinutes: exam.durationMinutes,
          icon: Icons.assignment_turned_in,
          color: Colors.orange,
        ),
      );
    }

    schedule.sort((left, right) => left.startTime.compareTo(right.startTime));
    return schedule;
  }

  Subject? _findSubject(List<Subject> subjects, String subjectId) {
    try {
      return subjects.firstWhere((subject) => subject.id == subjectId);
    } catch (e) {
      return null;
    }
  }

  String getSubjectName(String subjectId) {
    final subject = _subjects
        .where((item) => item.id == subjectId)
        .cast<Subject?>()
        .firstWhere((item) => item != null, orElse: () => null);
    return subject?.name ?? subjectId;
  }

  List<TeacherStudentSummary> studentsForClass(String classId) {
    return _studentsByClass[classId] ?? const [];
  }

  TeacherClass? classById(String classId) {
    try {
      return _classes.firstWhere((teacherClass) => teacherClass.id == classId);
    } catch (e) {
      return null;
    }
  }

  String _buildDifficulty(Question question) {
    if (question.orderNumber <= 2) return 'Dễ';
    if (question.orderNumber <= 4) return 'Trung bình';
    return 'Khó';
  }
}
