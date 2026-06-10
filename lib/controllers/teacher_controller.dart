import 'package:cloud_firestore/cloud_firestore.dart';
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



class TeacherController extends ChangeNotifier {
  bool _isLoading = false;
  String? _teacherId;
  AppUser? _teacher;
  List<TeacherClass> _classes = [];
  List<Subject> _subjects = [];
  List<Exam> _assignedExams = [];
  List<TeacherQuestionSummary> _questionBank = [];
  Map<String, List<TeacherStudentSummary>> _studentsByClass = {};
  int _totalStudents = 0;
  List<Exam> _createdExams = [];

  // Leaderboard fields
  List<ClassLeaderboardItem> _classLeaderboard = [];
  bool _isLeaderboardLoading = false;

  bool get isLoading => _isLoading;
  AppUser? get teacher => _teacher;
  List<TeacherClass> get classes => List.unmodifiable(_classes);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Exam> get assignedExams => List.unmodifiable(_assignedExams);
  List<TeacherQuestionSummary> get questionBank => List.unmodifiable(_questionBank);
  Map<String, List<TeacherStudentSummary>> get studentsByClass => _studentsByClass;
  int get totalStudents => _totalStudents;
  List<Exam> get createdExams => List.unmodifiable(_createdExams);

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


      
      // Load teacher's created exams from Firestore
      final allExamsList = await service.exam.getAllExams();
      _createdExams = allExamsList.where((exam) => exam.creatorId == teacher.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<void> refreshCreatedExams() async {
    if (_teacherId == null) return;
    try {
      final allExamsList = await RepositoryService.instance.exam.getAllExams();
      _createdExams = allExamsList.where((exam) => exam.creatorId == _teacherId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tải lại danh sách đề thi: $e');
    }
  }

  Future<Exam?> createTeacherExam({
    required String title,
    required String subjectId,
    required int durationMinutes,
    required String description,
    required double passingScore,
  }) async {
    if (_teacherId == null) return null;
    _isLoading = true;
    notifyListeners();
    
    try {
      final examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
      final newExam = Exam(
        id: examId,
        subjectId: subjectId,
        title: title,
        description: description,
        questionCount: 0,
        durationMinutes: durationMinutes,
        totalScore: 0.0,
        passingScore: passingScore,
        status: 'draft',
        creatorId: _teacherId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await RepositoryService.instance.exam.createExam(newExam);
      await refreshCreatedExams();
      return created;
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
      return null;
    } catch (e) {
      debugPrint('Lỗi tạo đề thi: $e');
      throw Exception('Không thể tạo đề thi. Vui lòng thử lại.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publishExam(String examId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final exam = await RepositoryService.instance.exam.getExamById(examId);
      if (exam != null) {
        final updatedExam = exam.copyWith(status: 'published', updatedAt: DateTime.now());
        await RepositoryService.instance.exam.updateExam(updatedExam);
        await refreshCreatedExams();
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể phát hành đề thi. Vui lòng thử lại.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unpublishExam(String examId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final exam = await RepositoryService.instance.exam.getExamById(examId);
      if (exam != null) {
        final updatedExam = exam.copyWith(status: 'draft', updatedAt: DateTime.now());
        await RepositoryService.instance.exam.updateExam(updatedExam);
        await refreshCreatedExams();
      }
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể hủy phát hành đề thi. Vui lòng thử lại.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTeacherExam(String examId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await RepositoryService.instance.exam.deleteExam(examId);
      await refreshCreatedExams();
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      throw Exception('Không thể xóa đề thi. Vui lòng thử lại.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestionToExam({
    required String examId,
    required String content,
    required String correctAnswer,
    required String wrong1,
    required String wrong2,
    required String wrong3,
    required String difficulty,
    required String explanation,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final exam = await RepositoryService.instance.exam.getExamById(examId);
      if (exam == null) {
        throw Exception('Không tìm thấy đề thi.');
      }

      final nextOrderNumber = exam.questionCount + 1;
      final options = [
        AnswerOption(id: 'opt_${examId}_${nextOrderNumber}_0', label: 'A', content: wrong1, isCorrect: false),
        AnswerOption(id: 'opt_${examId}_${nextOrderNumber}_1', label: 'B', content: wrong2, isCorrect: false),
        AnswerOption(id: 'opt_${examId}_${nextOrderNumber}_2', label: 'C', content: correctAnswer, isCorrect: true),
        AnswerOption(id: 'opt_${examId}_${nextOrderNumber}_3', label: 'D', content: wrong3, isCorrect: false),
      ]..shuffle();

      final labeledOptions = <AnswerOption>[];
      for (int i = 0; i < options.length; i++) {
        labeledOptions.add(
          options[i].copyWith(
            label: i == 0 ? 'A' : i == 1 ? 'B' : i == 2 ? 'C' : 'D',
          ),
        );
      }

      final newQuestion = Question(
        id: 'q_${examId}_${DateTime.now().millisecondsSinceEpoch}',
        examId: examId,
        content: content,
        explanation: explanation,
        orderNumber: nextOrderNumber,
        score: 1.0,
        options: labeledOptions,
        createdAt: DateTime.now(),
      );

      await RepositoryService.instance.exam.createQuestion(newQuestion);
      await refreshCreatedExams();
    } on FirebaseException catch (e) {
      _handleFirebaseException(e);
    } catch (e) {
      debugPrint('Lỗi thêm câu hỏi: $e');
      throw Exception('Không thể thêm câu hỏi. Vui lòng thử lại.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleFirebaseException(FirebaseException e) {
    if (e.code == 'permission-denied') {
      throw Exception('Bạn không có quyền thực hiện thao tác này.');
    } else if (e.code == 'network-request-failed') {
      throw Exception('Không có kết nối mạng. Vui lòng thử lại.');
    } else {
      throw Exception('Không thể thực hiện thao tác. Vui lòng thử lại.');
    }
  }
}
