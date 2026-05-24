/// Exam repository for managing exams and questions
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/mock_exams.dart';

abstract class ExamRepository {
  Future<List<Exam>> getAllExams();
  Future<List<Exam>> getExamsBySubject(String subjectId);
  Future<Exam?> getExamById(String id);
  Future<List<Question>> getQuestionsByExam(String examId);
  Future<Question?> getQuestionById(String id);
  Future<void> createExam(Exam exam);
  Future<void> updateExam(Exam exam);
  Future<void> deleteExam(String id);
}

/// Mock implementation
class MockExamRepository implements ExamRepository {
  final List<Exam> _exams = List.from(MockExamsData.exams);
  final List<Question> _questions = List.from(MockExamsData.questions);

  @override
  Future<List<Exam>> getAllExams() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _exams;
  }

  @override
  Future<List<Exam>> getExamsBySubject(String subjectId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _exams.where((e) => e.subjectId == subjectId).toList();
  }

  @override
  Future<Exam?> getExamById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _exams.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Question>> getQuestionsByExam(String examId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return _questions.where((q) => q.examId == examId).toList();
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createExam(Exam exam) async {
    await Future.delayed(Duration(milliseconds: 300));
    _exams.add(exam);
  }

  @override
  Future<void> updateExam(Exam exam) async {
    await Future.delayed(Duration(milliseconds: 300));
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index >= 0) {
      _exams[index] = exam;
    }
  }

  @override
  Future<void> deleteExam(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _exams.removeWhere((e) => e.id == id);
    _questions.removeWhere((q) => q.examId == id);
  }
}
