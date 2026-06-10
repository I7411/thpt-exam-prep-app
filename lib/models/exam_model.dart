/// Exam model (Äá» thi)
class Exam {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int questionCount;
  final int durationMinutes;
  final double totalScore;
  final double passingScore;
  final String status; // 'draft' or 'published'
  final String creatorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Exam({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.durationMinutes,
    required this.totalScore,
    required this.passingScore,
    required this.status,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPublished => status == 'published';

  /// Create Exam from JSON
  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      questionCount: json['questionCount'] as int? ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      totalScore: (json['totalScore'] as num? ?? 10).toDouble(),
      passingScore: (json['passingScore'] as num? ?? 5).toDouble(),
      status: json['status'] as String? ?? (json['isPublished'] == true ? 'published' : 'draft'),
      creatorId: json['creatorId'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  /// Convert Exam to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'questionCount': questionCount,
      'durationMinutes': durationMinutes,
      'totalScore': totalScore,
      'passingScore': passingScore,
      'status': status,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Exam copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    int? questionCount,
    int? durationMinutes,
    double? totalScore,
    double? passingScore,
    String? status,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      questionCount: questionCount ?? this.questionCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalScore: totalScore ?? this.totalScore,
      passingScore: passingScore ?? this.passingScore,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Exam(id: $id, title: $title)';
}

