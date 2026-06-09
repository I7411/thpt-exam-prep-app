/// Topic model (Chủ đề học)
class Topic {
  final String id;
  final String subjectId;
  final String name;
  final String description;
  final int orderNumber;
  final int documentCount;
  final DateTime createdAt;

  const Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.orderNumber,
    required this.documentCount,
    required this.createdAt,
  });

  /// Create Topic from JSON
  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      orderNumber: json['orderNumber'] as int? ?? 0,
      documentCount: json['documentCount'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Convert Topic to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'description': description,
      'orderNumber': orderNumber,
      'documentCount': documentCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Topic copyWith({
    String? id,
    String? subjectId,
    String? name,
    String? description,
    int? orderNumber,
    int? documentCount,
    DateTime? createdAt,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderNumber: orderNumber ?? this.orderNumber,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Topic(id: $id, name: $name)';
}
