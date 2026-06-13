/// Answer option model (Lá»±a chá»n cÃ¢u tráº£ lá»i)
class AnswerOption {
  final String id;
  final String label;
  final String content;
  final bool isCorrect;

  const AnswerOption({
    required this.id,
    required this.label,
    required this.content,
    required this.isCorrect,
  });

  /// Create AnswerOption from JSON
  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  /// Convert AnswerOption to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'content': content,
      'isCorrect': isCorrect,
    };
  }

  /// Create a copy with modified fields
  AnswerOption copyWith({
    String? id,
    String? label,
    String? content,
    bool? isCorrect,
  }) {
    return AnswerOption(
      id: id ?? this.id,
      label: label ?? this.label,
      content: content ?? this.content,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  String toString() => 'AnswerOption(id: $id, label: $label)';
}
