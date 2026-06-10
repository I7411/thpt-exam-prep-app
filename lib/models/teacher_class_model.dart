import 'package:cloud_firestore/cloud_firestore.dart';

/// Teacher class model (Lớp học của giáo viên)
class TeacherClass {
  final String id;
  final String teacherId;
  final List<String> teacherIds;
  final List<String> studentIds;
  final String className;
  final String subjectId;
  final String description;
  final int studentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherClass({
    required this.id,
    required this.teacherId,
    this.teacherIds = const [],
    this.studentIds = const [],
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
      teacherIds: (json['teacherIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      studentIds: (json['studentIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      className: json['className'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      studentCount: json['studentCount'] as int? ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? _parseDateTime(json['updatedAt']) : null,
    );
  }

  /// Convert TeacherClass to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherIds': teacherIds,
      'studentIds': studentIds,
      'className': className,
      'subjectId': subjectId,
      'description': description,
      'studentCount': studentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create TeacherClass from Firestore DocumentSnapshot
  factory TeacherClass.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TeacherClass(
      id: doc.id,
      teacherId: data['teacherId'] as String? ?? '',
      teacherIds: (data['teacherIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      studentIds: (data['studentIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      className: data['className'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      studentCount: data['studentCount'] as int? ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
    );
  }

  /// Convert TeacherClass to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'teacherId': teacherId,
      'teacherIds': teacherIds.isEmpty ? [teacherId] : teacherIds,
      'studentIds': studentIds,
      'className': className,
      'subjectId': subjectId,
      'description': description,
      'studentCount': studentIds.length,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with modified fields
  TeacherClass copyWith({
    String? id,
    String? teacherId,
    List<String>? teacherIds,
    List<String>? studentIds,
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
      teacherIds: teacherIds ?? this.teacherIds,
      studentIds: studentIds ?? this.studentIds,
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

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
