/// Exam attempt model (Láº§n lÃ m bÃ i thi)
class ExamAttempt {
  final String id;
  final String examId;
  final String studentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double score;
  final bool isPassed;
  final int answeredQuestionCount;
  final int totalQuestionCount;
  final bool isSubmitted;

  const ExamAttempt({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.startedAt,
    this.completedAt,
    required this.score,
    required this.isPassed,
    required this.answeredQuestionCount,
    required this.totalQuestionCount,
    required this.isSubmitted,
  });

  /// Calculate duration in minutes
  int? getDurationMinutes() {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt).inMinutes;
  }

  /// Calculate accuracy percentage
  double getAccuracyPercentage() {
    if (totalQuestionCount == 0) return 0;
    return (answeredQuestionCount / totalQuestionCount) * 100;
  }

  /// Create ExamAttempt from JSON
  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      score: (json['score'] as num? ?? 0).toDouble(),
      isPassed: json['isPassed'] as bool? ?? false,
      answeredQuestionCount: json['answeredQuestionCount'] as int? ?? 0,
      totalQuestionCount: json['totalQuestionCount'] as int? ?? 0,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
    );
  }

  /// Convert ExamAttempt to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'score': score,
      'isPassed': isPassed,
      'answeredQuestionCount': answeredQuestionCount,
      'totalQuestionCount': totalQuestionCount,
      'isSubmitted': isSubmitted,
    };
  }

  /// Create a copy with modified fields
  ExamAttempt copyWith({
    String? id,
    String? examId,
    String? studentId,
    DateTime? startedAt,
    DateTime? completedAt,
    double? score,
    bool? isPassed,
    int? answeredQuestionCount,
    int? totalQuestionCount,
    bool? isSubmitted,
  }) {
    return ExamAttempt(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      isPassed: isPassed ?? this.isPassed,
      answeredQuestionCount:
          answeredQuestionCount ?? this.answeredQuestionCount,
      totalQuestionCount: totalQuestionCount ?? this.totalQuestionCount,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  @override
  String toString() => 'ExamAttempt(id: $id, examId: $examId)';
}
