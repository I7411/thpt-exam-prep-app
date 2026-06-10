import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_model.dart';

class StudentProgress {
  final String studentId;
  final int totalExamsCompleted;
  final double averageScore;
  final int documentsRead;
  final int activeSubjects;
  final double overallProgressPercentage;
  final List<ProgressStat> subjectProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentProgress({
    required this.studentId,
    required this.totalExamsCompleted,
    required this.averageScore,
    required this.documentsRead,
    required this.activeSubjects,
    required this.overallProgressPercentage,
    required this.subjectProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns a zero-progress instance for a student
  factory StudentProgress.zero(String studentId) {
    return StudentProgress(
      studentId: studentId,
      totalExamsCompleted: 0,
      averageScore: 0.0,
      documentsRead: 0,
      activeSubjects: 0,
      overallProgressPercentage: 0.0,
      subjectProgress: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    final subjectProgressList = (json['subjectProgress'] as List<dynamic>?)
            ?.map((e) => ProgressStat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return StudentProgress(
      studentId: json['studentId'] as String? ?? '',
      totalExamsCompleted: json['totalExamsCompleted'] as int? ?? json['totalExamsTaken'] as int? ?? 0,
      averageScore: (json['averageScore'] as num? ?? 0.0).toDouble(),
      documentsRead: json['documentsRead'] as int? ?? json['totalDocumentsRead'] as int? ?? 0,
      activeSubjects: json['activeSubjects'] as int? ?? subjectProgressList.length,
      overallProgressPercentage: (json['overallProgressPercentage'] as num? ?? json['completionPercentage'] as num? ?? 0.0).toDouble(),
      subjectProgress: subjectProgressList,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  factory StudentProgress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final subjectProgressList = (data['subjectProgress'] as List<dynamic>?)
            ?.map((e) => ProgressStat.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return StudentProgress(
      studentId: data['studentId'] as String? ?? doc.id,
      totalExamsCompleted: data['totalExamsCompleted'] as int? ?? data['totalExamsTaken'] as int? ?? 0,
      averageScore: (data['averageScore'] as num? ?? 0.0).toDouble(),
      documentsRead: data['documentsRead'] as int? ?? data['totalDocumentsRead'] as int? ?? 0,
      activeSubjects: data['activeSubjects'] as int? ?? subjectProgressList.length,
      overallProgressPercentage: (data['overallProgressPercentage'] as num? ?? data['completionPercentage'] as num? ?? 0.0).toDouble(),
      subjectProgress: subjectProgressList,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'totalExamsCompleted': totalExamsCompleted,
      'averageScore': averageScore,
      'documentsRead': documentsRead,
      'activeSubjects': activeSubjects,
      'overallProgressPercentage': overallProgressPercentage,
      'subjectProgress': subjectProgress.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'totalExamsCompleted': totalExamsCompleted,
      'totalExamsTaken': totalExamsCompleted, // Legacy compatibility
      'averageScore': averageScore,
      'documentsRead': documentsRead,
      'totalDocumentsRead': documentsRead, // Legacy compatibility
      'examsPassed': subjectProgress.fold<int>(0, (total, e) => total + e.examsPassed), // Legacy compatibility
      'streakDays': subjectProgress.fold<int>(0, (max, e) => e.streakDays > max ? e.streakDays : max), // Legacy compatibility
      'completionPercentage': overallProgressPercentage, // Legacy compatibility
      'activeSubjects': activeSubjects,
      'overallProgressPercentage': overallProgressPercentage,
      'subjectProgress': subjectProgress.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudentProgress copyWith({
    String? studentId,
    int? totalExamsCompleted,
    double? averageScore,
    int? documentsRead,
    int? activeSubjects,
    double? overallProgressPercentage,
    List<ProgressStat>? subjectProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProgress(
      studentId: studentId ?? this.studentId,
      totalExamsCompleted: totalExamsCompleted ?? this.totalExamsCompleted,
      averageScore: averageScore ?? this.averageScore,
      documentsRead: documentsRead ?? this.documentsRead,
      activeSubjects: activeSubjects ?? this.activeSubjects,
      overallProgressPercentage: overallProgressPercentage ?? this.overallProgressPercentage,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
