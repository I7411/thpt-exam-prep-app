/// Study document model (TÃ i liá»‡u Ã´n táº­p)
class StudyDocument {
  final String id;
  final String topicId;
  final String subjectId;
  final String title;
  final String description;
  final String content;
  final String? thumbnailUrl;
  final String? fileUrl;
  final String author;
  final int views;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StudyDocument({
    required this.id,
    required this.topicId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.content,
    this.thumbnailUrl,
    this.fileUrl,
    required this.author,
    required this.views,
    required this.rating,
    required this.ratingCount,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create StudyDocument from JSON
  factory StudyDocument.fromJson(Map<String, dynamic> json) {
    return StudyDocument(
      id: json['id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      author: json['author'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert StudyDocument to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'fileUrl': fileUrl,
      'author': author,
      'views': views,
      'rating': rating,
      'ratingCount': ratingCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  StudyDocument copyWith({
    String? id,
    String? topicId,
    String? subjectId,
    String? title,
    String? description,
    String? content,
    String? thumbnailUrl,
    String? fileUrl,
    String? author,
    int? views,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyDocument(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      author: author ?? this.author,
      views: views ?? this.views,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'StudyDocument(id: $id, title: $title)';
}
