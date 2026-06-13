import 'package:thpt_exam_prep_app/models.dart';

class StudentHomeData {
  final List<Subject> subjects;
  final List<StudyDocument> documents;
  final List<Exam> exams;
  final List<ProgressStat> progressStats;
  final double averageScore;
  final int totalExams;
  final int examsPassed;
  final int totalLearnedDocuments;
  final Map<String, DateTime> favoritesMap;

  const StudentHomeData({
    required this.subjects,
    required this.documents,
    required this.exams,
    required this.progressStats,
    required this.averageScore,
    required this.totalExams,
    required this.examsPassed,
    required this.totalLearnedDocuments,
    required this.favoritesMap,
  });

  bool get isEmpty {
    return subjects.isEmpty &&
        documents.isEmpty &&
        exams.isEmpty &&
        progressStats.isEmpty;
  }
}
