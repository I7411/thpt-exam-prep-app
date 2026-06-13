/// Exam answer model (CÃ¢u tráº£ lá»i cá»§a há»c sinh)
class ExamAnswer {
  final String id;
  final String examAttemptId;
  final String questionId;
  final String selectedOptionId;
  final DateTime answeredAt;
  final bool isCorrect;
  final double earnedScore;

  const ExamAnswer({
    required this.id,
    required this.examAttemptId,
    required this.questionId,
    required this.selectedOptionId,
    required this.answeredAt,
    required this.isCorrect,
    required this.earnedScore,
  });

  /// Create ExamAnswer from JSON
  factory ExamAnswer.fromJson(Map<String, dynamic> json) {
    return ExamAnswer(
      id: json['id'] as String? ?? '',
      examAttemptId: json['examAttemptId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      selectedOptionId: json['selectedOptionId'] as String? ?? '',
      answeredAt:
          DateTime.tryParse(json['answeredAt'] as String? ?? '') ??
          DateTime.now(),
      isCorrect: json['isCorrect'] as bool? ?? false,
      earnedScore: (json['earnedScore'] as num? ?? 0).toDouble(),
    );
  }

  /// Convert ExamAnswer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examAttemptId': examAttemptId,
      'questionId': questionId,
      'selectedOptionId': selectedOptionId,
      'answeredAt': answeredAt.toIso8601String(),
      'isCorrect': isCorrect,
      'earnedScore': earnedScore,
    };
  }

  /// Create a copy with modified fields
  ExamAnswer copyWith({
    String? id,
    String? examAttemptId,
    String? questionId,
    String? selectedOptionId,
    DateTime? answeredAt,
    bool? isCorrect,
    double? earnedScore,
  }) {
    return ExamAnswer(
      id: id ?? this.id,
      examAttemptId: examAttemptId ?? this.examAttemptId,
      questionId: questionId ?? this.questionId,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      answeredAt: answeredAt ?? this.answeredAt,
      isCorrect: isCorrect ?? this.isCorrect,
      earnedScore: earnedScore ?? this.earnedScore,
    );
  }

  @override
  String toString() => 'ExamAnswer(id: $id, isCorrect: $isCorrect)';
}
