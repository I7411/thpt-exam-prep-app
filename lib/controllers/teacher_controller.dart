import 'package:flutter/material.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_progress.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class TeacherStudentSummary {
  final String name;
  final String email;
  final double averageScore;
  final double completionPercentage;
  final int totalExamsTaken;
  final int examsPassed;
  final int streakDays;

  const TeacherStudentSummary({
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

  bool get isLoading => _isLoading;
  AppUser? get teacher => _teacher;
  List<TeacherClass> get classes => List.unmodifiable(_classes);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Exam> get assignedExams => List.unmodifiable(_assignedExams);
  List<TeacherQuestionSummary> get questionBank => List.unmodifiable(_questionBank);
  List<TeacherScheduleItem> get schedule => List.unmodifiable(_schedule);
  Map<String, List<TeacherStudentSummary>> get studentsByClass => _studentsByClass;

  int get totalStudents => _classes.fold<int>(0, (sum, teacherClass) => sum + teacherClass.studentCount);

  double get averageProgress {
    final subjectIds = _classes.map((teacherClass) => teacherClass.subjectId).toSet();
    final progressStats = MockProgressData.progressStats.where((stat) => subjectIds.contains(stat.subjectId)).toList();
    if (progressStats.isEmpty) return 0;
    final total = progressStats.fold<double>(0, (sum, stat) => sum + stat.completionPercentage);
    return total / progressStats.length;
  }

  Future<void> ensureLoaded(AppUser? teacher) async {
    if (teacher == null || teacher.role != UserRole.teacher) return;
    if (_teacherId == teacher.id && _classes.isNotEmpty) return;
    await loadTeacher(teacher);
  }

  Future<void> loadTeacher(AppUser teacher) async {
    _isLoading = true;
    notifyListeners();

    _teacher = teacher;
    _teacherId = teacher.id;

    final service = RepositoryService.instance;
    final loadedClasses = await service.teacher.getClassesByTeacher(teacher.id);
    final loadedSubjects = await service.subject.getAllSubjects();
    final allExams = await service.exam.getAllExams();

    final subjectIds = loadedClasses.map((teacherClass) => teacherClass.subjectId).toSet();
    final progressStats = MockProgressData.progressStats.where((stat) => subjectIds.contains(stat.subjectId)).toList();

    _classes = loadedClasses;
    _subjects = loadedSubjects;
    _assignedExams = allExams.where((exam) => subjectIds.contains(exam.subjectId)).toList();
    _questionBank = await _loadQuestionBank(service, _assignedExams, loadedSubjects);
    _studentsByClass = _buildStudentsByClass(loadedClasses, loadedSubjects, progressStats);
    _schedule = _buildSchedule(loadedClasses, loadedSubjects, _assignedExams);

    _isLoading = false;
    notifyListeners();
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
        final correctOption = question.options.where((option) => option.isCorrect).isNotEmpty
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

    entries.sort((left, right) => left.question.orderNumber.compareTo(right.question.orderNumber));
    return entries;
  }

  Map<String, List<TeacherStudentSummary>> _buildStudentsByClass(
    List<TeacherClass> classes,
    List<Subject> subjects,
    List<ProgressStat> progressStats,
  ) {
    final map = <String, List<TeacherStudentSummary>>{};
    for (var index = 0; index < classes.length; index++) {
      final teacherClass = classes[index];
      final subject = _findSubject(subjects, teacherClass.subjectId);
      final subjectStats = progressStats.where((stat) => stat.subjectId == teacherClass.subjectId).toList();
      map[teacherClass.id] = _buildDemoStudents(
        teacherClass: teacherClass,
        subjectName: subject?.name ?? 'Môn học',
        progressStats: subjectStats,
      );
    }
    return map;
  }

  List<TeacherStudentSummary> _buildDemoStudents({
    required TeacherClass teacherClass,
    required String subjectName,
    required List<ProgressStat> progressStats,
  }) {
    final primaryStat = progressStats.isNotEmpty ? progressStats.first : null;
    final baseStudents = <TeacherStudentSummary>[
      TeacherStudentSummary(
        name: MockUsersData.studentUser.fullName,
        email: MockUsersData.studentUser.email,
        averageScore: primaryStat?.averageScore ?? 7.2,
        completionPercentage: primaryStat?.completionPercentage ?? 65,
        totalExamsTaken: primaryStat?.totalExamsTaken ?? 3,
        examsPassed: primaryStat?.examsPassed ?? 2,
        streakDays: primaryStat?.streakDays ?? 5,
      ),
      const TeacherStudentSummary(
        name: 'Trần Minh Khang',
        email: 'khang12@example.com',
        averageScore: 8.2,
        completionPercentage: 82,
        totalExamsTaken: 4,
        examsPassed: 4,
        streakDays: 8,
      ),
      const TeacherStudentSummary(
        name: 'Lê Thu Hà',
        email: 'ha12@example.com',
        averageScore: 7.4,
        completionPercentage: 74,
        totalExamsTaken: 3,
        examsPassed: 2,
        streakDays: 6,
      ),
      const TeacherStudentSummary(
        name: 'Phạm Hoàng Nam',
        email: 'nam12@example.com',
        averageScore: 6.5,
        completionPercentage: 60,
        totalExamsTaken: 2,
        examsPassed: 1,
        streakDays: 3,
      ),
      const TeacherStudentSummary(
        name: 'Nguyễn Khánh Vy',
        email: 'vy12@example.com',
        averageScore: 5.9,
        completionPercentage: 48,
        totalExamsTaken: 2,
        examsPassed: 1,
        streakDays: 2,
      ),
    ];

    return baseStudents.take(teacherClass.studentCount > 0 ? 5 : 0).toList();
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
          subtitle: '${subject?.name ?? 'MÃ´n há»c'} • ${teacherClass.studentCount} học sinh',
          startTime: DateTime(now.year, now.month, now.day + index + 1, 7 + index, 30),
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
          subtitle: '${subject?.name ?? 'MÃ´n há»c'} • ${exam.questionCount} câu',
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
    final subject = _subjects.where((item) => item.id == subjectId).cast<Subject?>().firstWhere(
          (item) => item != null,
          orElse: () => null,
        );
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

