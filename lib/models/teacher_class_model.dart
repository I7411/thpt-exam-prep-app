/// Teacher class model (Lá»›p há»c cá»§a giÃ¡o viÃªn)
class TeacherClass {
  final String id;
  final String teacherId;
  final String className;
  final String subjectId;
  final String description;
  final int studentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherClass({
    required this.id,
    required this.teacherId,
    required this.className,
    required this.subjectId,
    required this.description,
    required this.studentCount,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create TeacherClass from JSON
  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      id: json['id'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      studentCount: json['studentCount'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  /// Convert TeacherClass to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'className': className,
      'subjectId': subjectId,
      'description': description,
      'studentCount': studentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  TeacherClass copyWith({
    String? id,
    String? teacherId,
    String? className,
    String? subjectId,
    String? description,
    int? studentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherClass(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      description: description ?? this.description,
      studentCount: studentCount ?? this.studentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'TeacherClass(id: $id, className: $className)';
}

