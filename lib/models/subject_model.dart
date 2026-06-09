/// Subject model (MÃ´n há»c)
class Subject {
  final String id;
  final String name;
  final String description;
  final int totalTopics;
  final int totalDocuments;
  final int totalExams;
  final String? iconUrl;
  final String? color;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.totalTopics,
    required this.totalDocuments,
    required this.totalExams,
    this.iconUrl,
    this.color,
    required this.createdAt,
  });

  /// Create Subject from JSON
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalTopics: json['totalTopics'] as int? ?? 0,
      totalDocuments: json['totalDocuments'] as int? ?? 0,
      totalExams: json['totalExams'] as int? ?? 0,
      iconUrl: json['iconUrl'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Convert Subject to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'totalTopics': totalTopics,
      'totalDocuments': totalDocuments,
      'totalExams': totalExams,
      'iconUrl': iconUrl,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Subject copyWith({
    String? id,
    String? name,
    String? description,
    int? totalTopics,
    int? totalDocuments,
    int? totalExams,
    String? iconUrl,
    String? color,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalTopics: totalTopics ?? this.totalTopics,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      totalExams: totalExams ?? this.totalExams,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Subject(id: $id, name: $name)';
}

