import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thpt_exam_prep_app/data/local/app_database.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';

class ExamProvider extends ChangeNotifier {
  final RepositoryService _repositoryService = RepositoryService.getInstance();
  final AppLocalRepository _localRepository = AppLocalRepository.instance;

  String? _studentId;
  Exam? _currentExam;
  List<Question> _questions = <Question>[];
  final Map<String, String> _selectedOptionIds = <String, String>{};
  int _currentQuestionIndex = 0;
  bool _isSubmitted = false;
  bool _isLoading = false;
  Duration _remainingTime = Duration.zero;
  DateTime? _startedAt;
  DateTime? _submittedAt;
  Timer? _timer;
  ExamAttempt? _currentAttempt;
  ExamResultData? _currentResult;
  List<ExamResultData> _history = <ExamResultData>[];

  String? get studentId => _studentId;
  Exam? get currentExam => _currentExam;
  List<Question> get questions => List.unmodifiable(_questions);
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isSubmitted => _isSubmitted;
  bool get isLoading => _isLoading;
  Duration get remainingTime => _remainingTime;
  DateTime? get startedAt => _startedAt;
  DateTime? get submittedAt => _submittedAt;
  ExamAttempt? get currentAttempt => _currentAttempt;
  ExamResultData? get currentResult => _currentResult;
  List<ExamResultData> get history => List.unmodifiable(_history);

  Question? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex < 0 || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  bool get hasCurrentExam => _currentExam != null && _questions.isNotEmpty;

  int get answeredCount => _selectedOptionIds.length;

  double get answeredPercentage {
    if (_questions.isEmpty) return 0;
    return (_selectedOptionIds.length / _questions.length) * 100;
  }

  String get remainingTimeLabel {
    final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> initialize(String studentId) async {
    if (_studentId == studentId && _history.isNotEmpty) {
      return;
    }

    _studentId = studentId;
    _history = await _loadHistory(studentId);
    notifyListeners();
  }

  Future<void> startExam({
    required Exam exam,
    required List<Question> questions,
    required String studentId,
  }) async {
    await initialize(studentId);
    _stopTimer();

    _currentExam = exam;
    _questions = List<Question>.from(questions)
      ..sort((left, right) => left.orderNumber.compareTo(right.orderNumber));
    _selectedOptionIds.clear();
    _currentQuestionIndex = 0;
    _isSubmitted = false;
    _isLoading = false;
    _startedAt = DateTime.now();
    _submittedAt = null;
    _currentAttempt = ExamAttempt(
      id: _buildAttemptId(exam.id),
      examId: exam.id,
      studentId: studentId,
      startedAt: _startedAt!,
      score: 0,
      isPassed: false,
      answeredQuestionCount: 0,
      totalQuestionCount: _questions.length,
      isSubmitted: false,
    );
    _currentResult = null;
    _remainingTime = Duration(minutes: exam.durationMinutes);

    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    await _saveDraft();
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_isSubmitted) {
      _stopTimer();
      return;
    }

    if (_remainingTime.inSeconds <= 1) {
      _remainingTime = Duration.zero;
      notifyListeners();
      _submitExam(autoSubmitted: true);
      return;
    }

    _remainingTime = _remainingTime - const Duration(seconds: 1);
    notifyListeners();
  }

  void goToQuestion(int index) {
    if (_questions.isEmpty) return;
    if (index < 0 || index >= _questions.length) return;
    _currentQuestionIndex = index;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void selectOption(String questionId, String optionId) {
    if (_isSubmitted) return;
    _selectedOptionIds[questionId] = optionId;
    _saveDraft();
    notifyListeners();
  }

  String? selectedOptionFor(String questionId) {
    return _selectedOptionIds[questionId];
  }

  bool isQuestionAnswered(String questionId) {
    return _selectedOptionIds.containsKey(questionId);
  }

  Future<ExamResultData?> submitExam({bool confirmed = true}) async {
    if (!confirmed) return null;
    return _submitExam(autoSubmitted: false);
  }

  Future<ExamResultData?> _submitExam({required bool autoSubmitted}) async {
    if (_currentExam == null || _studentId == null || _isSubmitted) {
      return _currentResult;
    }

    _stopTimer();
    _submittedAt = DateTime.now();
    _isSubmitted = true;

    final result = _buildResult(autoSubmitted: autoSubmitted);
    _currentResult = result;
    _currentAttempt = result.attempt;

    final updatedProgress = await _updateProgress(result);
    await _persistResult(result, updatedProgress);
    await _clearDraft();

    notifyListeners();
    return result;
  }

  ExamResultData _buildResult({required bool autoSubmitted}) {
    final exam = _currentExam!;
    final questions = List<Question>.from(_questions);
    var correctCount = 0;
    var wrongCount = 0;
    var totalEarnedScore = 0.0;
    final answers = <ExamAnswer>[];

    for (final question in questions) {
      final selectedOptionId = _selectedOptionIds[question.id] ?? '';
      final selectedOption = question.options.cast<AnswerOption?>().firstWhere(
            (option) => option?.id == selectedOptionId,
            orElse: () => null,
          );
      final correctOption = question.options.firstWhere(
        (option) => option.isCorrect,
        orElse: () => question.options.first,
      );
      final isCorrect = selectedOption != null && selectedOption.isCorrect;
      if (isCorrect) {
        correctCount++;
        totalEarnedScore += question.score;
      } else {
        wrongCount++;
      }

      answers.add(
        ExamAnswer(
          id: '${question.id}_${_submittedAt!.millisecondsSinceEpoch}',
          examAttemptId: _buildAttemptId(exam.id),
          questionId: question.id,
          selectedOptionId: selectedOptionId,
          answeredAt: _submittedAt!,
          isCorrect: isCorrect,
          earnedScore: isCorrect ? question.score : 0,
        ),
      );

      _selectedOptionIds[question.id] = selectedOption?.id ?? '';
      final _ = correctOption;
    }

    final totalQuestions = questions.length;
    final completionPercentage = totalQuestions == 0 ? 0.0 : (correctCount / totalQuestions) * 100;
    final durationSpent = _submittedAt!.difference(_startedAt ?? _submittedAt!);
    final score = exam.totalScore <= 0 ? totalEarnedScore : (totalEarnedScore / exam.totalScore) * 10;

    final attempt = _currentAttempt!.copyWith(
      completedAt: _submittedAt,
      score: score,
      isPassed: score >= exam.passingScore,
      answeredQuestionCount: _selectedOptionIds.values.where((value) => value.isNotEmpty).length,
      totalQuestionCount: totalQuestions,
      isSubmitted: true,
    );

    return ExamResultData(
      exam: exam,
      questions: questions,
      selectedOptionIds: Map<String, String>.from(_selectedOptionIds),
      answers: answers,
      attempt: attempt,
      studentId: _studentId!,
      correctCount: correctCount,
      wrongCount: wrongCount,
      score: score,
      completionPercentage: completionPercentage,
      timeSpent: durationSpent,
      autoSubmitted: autoSubmitted,
    );
  }

  Future<ProgressStat> _updateProgress(ExamResultData result) async {
    final subjectId = result.exam.subjectId;
    final existing = await _repositoryService.progress.getProgressByStudentSubject(result.studentId, subjectId);

    if (existing == null) {
      final createdProgress = ProgressStat(
        id: 'prog_${result.exam.id}_${result.studentId}',
        studentId: result.studentId,
        subjectId: subjectId,
        totalDocumentsRead: 0,
        totalExamsTaken: 1,
        examsPassed: result.isPassed ? 1 : 0,
        averageScore: result.score,
        streakDays: 1,
        lastStudyDate: DateTime.now(),
        completionPercentage: result.completionPercentage,
        updatedAt: DateTime.now(),
      );
      await _repositoryService.progress.createProgress(createdProgress);
      return createdProgress;
    }

    final newTotalExams = existing.totalExamsTaken + 1;
    final newAverageScore = ((existing.averageScore * existing.totalExamsTaken) + result.score) / newTotalExams;
    final updatedProgress = existing.copyWith(
      totalExamsTaken: newTotalExams,
      examsPassed: existing.examsPassed + (result.isPassed ? 1 : 0),
      averageScore: newAverageScore,
      completionPercentage: result.completionPercentage.clamp(existing.completionPercentage, 100),
      lastStudyDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repositoryService.progress.updateProgress(updatedProgress);
    return updatedProgress;
  }

  Future<void> _persistResult(ExamResultData result, ProgressStat progressStat) async {
    await _localRepository.saveExamResult(result: result, progressStat: progressStat);
    final currentItems = await _loadHistory(result.studentId);
    _history = <ExamResultData>[result, ...currentItems.where((item) => item.attempt.id != result.attempt.id)];
  }

  Future<List<ExamResultData>> _loadHistory(String studentId) async {
    final localItems = await _localRepository.getExamHistory(studentId);
    if (localItems.isNotEmpty) {
      return localItems;
    }

    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_historyKey(studentId)) ?? <String>[];
    return items.map((item) => ExamResultData.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentExam == null || _studentId == null) return;
    final payload = <String, dynamic>{
      'examId': _currentExam!.id,
      'studentId': _studentId,
      'selectedOptionIds': _selectedOptionIds,
      'currentQuestionIndex': _currentQuestionIndex,
      'remainingSeconds': _remainingTime.inSeconds,
      'startedAt': _startedAt?.toIso8601String(),
    };
    await prefs.setString(_draftKey(_studentId!, _currentExam!.id), jsonEncode(payload));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentExam == null || _studentId == null) return;
    await prefs.remove(_draftKey(_studentId!, _currentExam!.id));
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _historyKey(String studentId) => 'exam_history_$studentId';
  String _draftKey(String studentId, String examId) => 'exam_draft_${studentId}_$examId';
  String _buildAttemptId(String examId) => 'attempt_${examId}_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

class ExamResultData {
  final Exam exam;
  final List<Question> questions;
  final Map<String, String> selectedOptionIds;
  final List<ExamAnswer> answers;
  final ExamAttempt attempt;
  final String studentId;
  final int correctCount;
  final int wrongCount;
  final double score;
  final double completionPercentage;
  final Duration timeSpent;
  final bool autoSubmitted;

  const ExamResultData({
    required this.exam,
    required this.questions,
    required this.selectedOptionIds,
    required this.answers,
    required this.attempt,
    required this.studentId,
    required this.correctCount,
    required this.wrongCount,
    required this.score,
    required this.completionPercentage,
    required this.timeSpent,
    required this.autoSubmitted,
  });

  Map<String, dynamic> toJson() {
    return {
      'exam': exam.toJson(),
      'questions': questions.map((question) => question.toJson()).toList(),
      'selectedOptionIds': selectedOptionIds,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'attempt': attempt.toJson(),
      'studentId': studentId,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'score': score,
      'completionPercentage': completionPercentage,
      'timeSpentSeconds': timeSpent.inSeconds,
      'autoSubmitted': autoSubmitted,
    };
  }

  factory ExamResultData.fromJson(Map<String, dynamic> json) {
    return ExamResultData(
      exam: Exam.fromJson(json['exam'] as Map<String, dynamic>),
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((item) => Question.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedOptionIds: Map<String, String>.from(json['selectedOptionIds'] as Map? ?? {}),
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((item) => ExamAnswer.fromJson(item as Map<String, dynamic>))
          .toList(),
      attempt: ExamAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
      studentId: json['studentId'] as String? ?? '',
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      score: (json['score'] as num? ?? 0).toDouble(),
      completionPercentage: (json['completionPercentage'] as num? ?? 0).toDouble(),
      timeSpent: Duration(seconds: json['timeSpentSeconds'] as int? ?? 0),
      autoSubmitted: json['autoSubmitted'] as bool? ?? false,
    );
  }

  String? selectedOptionFor(String questionId) => selectedOptionIds[questionId];

  Question? questionById(String questionId) {
    for (final question in questions) {
      if (question.id == questionId) {
        return question;
      }
    }
    return null;
  }
}