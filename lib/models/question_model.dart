import 'answer_model.dart';

/// Question model (CÃ¢u há»i)
class Question {
  final String id;
  final String examId;
  final String content;
  final String explanation;
  final int orderNumber;
  final double score;
  final List<AnswerOption> options;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.examId,
    required this.content,
    required this.explanation,
    required this.orderNumber,
    required this.score,
    required this.options,
    required this.createdAt,
  });

  /// Create Question from JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    List<AnswerOption> optionsList = [];

    if (rawOptions.isNotEmpty && rawOptions.first is String) {
      final int correctIdx = json['correctAnswerIndex'] as int? ?? 0;
      for (int i = 0; i < rawOptions.length; i++) {
        optionsList.add(
          AnswerOption(
            id: 'opt_${json['id']}_$i',
            label: i == 0
                ? 'A'
                : i == 1
                ? 'B'
                : i == 2
                ? 'C'
                : 'D',
            content: rawOptions[i] as String,
            isCorrect: i == correctIdx,
          ),
        );
      }
    } else {
      optionsList = rawOptions
          .map(
            (option) => AnswerOption.fromJson(option as Map<String, dynamic>),
          )
          .toList();
    }

    return Question(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      orderNumber: json['orderNumber'] as int? ?? 0,
      score: (json['score'] as num? ?? 1).toDouble(),
      options: optionsList,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convert Question to JSON
  Map<String, dynamic> toJson() {
    int correctIdx = options.indexWhere((o) => o.isCorrect);
    if (correctIdx == -1) correctIdx = 0;

    return {
      'id': id,
      'examId': examId,
      'content': content,
      'explanation': explanation,
      'orderNumber': orderNumber,
      'score': score,
      'options': options.map((o) => o.content).toList(),
      'correctAnswerIndex': correctIdx,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Question copyWith({
    String? id,
    String? examId,
    String? content,
    String? explanation,
    int? orderNumber,
    double? score,
    List<AnswerOption>? options,
    DateTime? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      content: content ?? this.content,
      explanation: explanation ?? this.explanation,
      orderNumber: orderNumber ?? this.orderNumber,
      score: score ?? this.score,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Question(id: $id, orderNumber: $orderNumber)';
}
