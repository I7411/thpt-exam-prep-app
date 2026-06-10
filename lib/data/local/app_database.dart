import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String _databaseName = 'thpt_exam_prep_app.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databasePath = join(documentsDirectory.path, _databaseName);
    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exam_attempts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        exam_id TEXT NOT NULL,
        score REAL NOT NULL,
        correct_count INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        submitted_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_answers (
        id TEXT PRIMARY KEY,
        attempt_id TEXT NOT NULL,
        question_id TEXT NOT NULL,
        selected_option_id TEXT NOT NULL,
        answered_at TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        earned_score REAL NOT NULL,
        FOREIGN KEY(attempt_id) REFERENCES exam_attempts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_stats (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        total_documents_read INTEGER NOT NULL,
        total_exams_taken INTEGER NOT NULL,
        exams_passed INTEGER NOT NULL,
        average_score REAL NOT NULL,
        streak_days INTEGER NOT NULL,
        last_study_date TEXT NOT NULL,
        completion_percentage REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_exam_attempts_user_id ON exam_attempts(user_id)');
    await db.execute('CREATE INDEX idx_exam_attempts_exam_id ON exam_attempts(exam_id)');
    await db.execute('CREATE INDEX idx_exam_answers_attempt_id ON exam_answers(attempt_id)');
    await db.execute('CREATE INDEX idx_progress_stats_student_id ON progress_stats(student_id)');
    await db.execute('CREATE INDEX idx_progress_stats_subject_id ON progress_stats(subject_id)');
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}

class AppLocalRepository {
  AppLocalRepository._internal();

  static final AppLocalRepository instance = AppLocalRepository._internal();

  final AppDatabase _database = AppDatabase.instance;
  final RepositoryService _repositoryService = RepositoryService.instance;

  Future<void> saveExamResult({
    required ExamResultData result,
    required ProgressStat progressStat,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(
        'exam_attempts',
        {
          'id': result.attempt.id,
          'user_id': result.studentId,
          'exam_id': result.exam.id,
          'score': result.score,
          'correct_count': result.correctCount,
          'wrong_count': result.wrongCount,
          'started_at': result.attempt.startedAt.toIso8601String(),
          'submitted_at': result.attempt.completedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('exam_answers', where: 'attempt_id = ?', whereArgs: [result.attempt.id]);
      for (final answer in result.answers) {
        await txn.insert(
          'exam_answers',
          {
            'id': answer.id,
            'attempt_id': answer.examAttemptId,
            'question_id': answer.questionId,
            'selected_option_id': answer.selectedOptionId,
            'answered_at': answer.answeredAt.toIso8601String(),
            'is_correct': answer.isCorrect ? 1 : 0,
            'earned_score': answer.earnedScore,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(
        'progress_stats',
        _progressToMap(progressStat),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<ExamResultData>> getExamHistory(String studentId) async {
    final db = await _database.database;
    final attempts = await db.query(
      'exam_attempts',
      where: 'user_id = ?',
      whereArgs: [studentId],
      orderBy: 'submitted_at DESC',
    );

    final results = <ExamResultData>[];
    for (final attemptRow in attempts) {
      final examId = attemptRow['exam_id'] as String;
      final exam = await _repositoryService.exam.getExamById(examId);
      if (exam == null) continue;

      final questions = await _repositoryService.exam.getQuestionsByExam(examId);
      final answersRows = await db.query(
        'exam_answers',
        where: 'attempt_id = ?',
        whereArgs: [attemptRow['id']],
        orderBy: 'answered_at ASC',
      );

      final answers = answersRows.map(_answerFromMap).toList();
      final selectedOptionIds = <String, String>{
        for (final answer in answers) answer.questionId: answer.selectedOptionId,
      };

      final startedAt = DateTime.parse(attemptRow['started_at'] as String);
      final submittedAt = DateTime.parse(attemptRow['submitted_at'] as String);
      final correctCount = (attemptRow['correct_count'] as int?) ?? answers.where((answer) => answer.isCorrect).length;
      final wrongCount = (attemptRow['wrong_count'] as int?) ?? (answers.length - correctCount);
      final score = (attemptRow['score'] as num).toDouble();
      final attempt = ExamAttempt(
        id: attemptRow['id'] as String,
        examId: exam.id,
        studentId: studentId,
        startedAt: startedAt,
        completedAt: submittedAt,
        score: score,
        isPassed: score >= exam.passingScore,
        answeredQuestionCount: answers.length,
        totalQuestionCount: questions.length,
        isSubmitted: true,
      );

      results.add(
        ExamResultData(
          exam: exam,
          questions: questions,
          selectedOptionIds: selectedOptionIds,
          answers: answers,
          attempt: attempt,
          studentId: studentId,
          correctCount: correctCount,
          wrongCount: wrongCount,
          score: score,
          completionPercentage: questions.isEmpty ? 0 : (correctCount / questions.length) * 100,
          timeSpent: submittedAt.difference(startedAt),
          autoSubmitted: false,
        ),
      );
    }

    return results;
  }

  Future<List<ProgressStat>> getProgressStats(String studentId) async {
    final db = await _database.database;
    final rows = await db.query(
      'progress_stats',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_progressFromMap).toList();
  }

  Future<ProgressStat?> getProgressStatBySubject(String studentId, String subjectId) async {
    final db = await _database.database;
    final rows = await db.query(
      'progress_stats',
      where: 'student_id = ? AND subject_id = ?',
      whereArgs: [studentId, subjectId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _progressFromMap(rows.first);
  }

  Future<void> upsertProgressStat(ProgressStat progressStat) async {
    final db = await _database.database;
    await db.insert(
      'progress_stats',
      _progressToMap(progressStat),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _progressToMap(ProgressStat progressStat) {
    return {
      'id': progressStat.id,
      'student_id': progressStat.studentId,
      'subject_id': progressStat.subjectId,
      'total_documents_read': progressStat.totalDocumentsRead,
      'total_exams_taken': progressStat.totalExamsTaken,
      'exams_passed': progressStat.examsPassed,
      'average_score': progressStat.averageScore,
      'streak_days': progressStat.streakDays,
      'last_study_date': progressStat.lastStudyDate.toIso8601String(),
      'completion_percentage': progressStat.completionPercentage,
      'updated_at': progressStat.updatedAt.toIso8601String(),
    };
  }

  ProgressStat _progressFromMap(Map<String, Object?> map) {
    return ProgressStat(
      id: map['id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      subjectId: map['subject_id'] as String? ?? '',
      totalDocumentsRead: map['total_documents_read'] as int? ?? 0,
      totalExamsTaken: map['total_exams_taken'] as int? ?? 0,
      examsPassed: map['exams_passed'] as int? ?? 0,
      averageScore: (map['average_score'] as num? ?? 0).toDouble(),
      streakDays: map['streak_days'] as int? ?? 0,
      lastStudyDate: DateTime.tryParse(map['last_study_date'] as String? ?? '') ?? DateTime.now(),
      completionPercentage: (map['completion_percentage'] as num? ?? 0).toDouble(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  ExamAnswer _answerFromMap(Map<String, Object?> map) {
    return ExamAnswer(
      id: map['id'] as String? ?? '',
      examAttemptId: map['attempt_id'] as String? ?? '',
      questionId: map['question_id'] as String? ?? '',
      selectedOptionId: map['selected_option_id'] as String? ?? '',
      answeredAt: DateTime.tryParse(map['answered_at'] as String? ?? '') ?? DateTime.now(),
      isCorrect: (map['is_correct'] as int? ?? 0) == 1,
      earnedScore: (map['earned_score'] as num? ?? 0).toDouble(),
    );
  }
}
