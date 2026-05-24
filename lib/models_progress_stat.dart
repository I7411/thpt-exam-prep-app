/// Progress statistic model (Tiến độ học tập)
class ProgressStat {
  final String id;
  final String studentId;
  final String subjectId;
  final int totalDocumentsRead;
  final int totalExamsTaken;
  final int examsPassed;
  final double averageScore;
  final int streakDays;
  final DateTime lastStudyDate;
  final double completionPercentage;
  final DateTime updatedAt;

  const ProgressStat({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.totalDocumentsRead,
    required this.totalExamsTaken,
    required this.examsPassed,
    required this.averageScore,
    required this.streakDays,
    required this.lastStudyDate,
    required this.completionPercentage,
    required this.updatedAt,
  });

  /// Calculate success rate
  double getSuccessRate() {
    if (totalExamsTaken == 0) return 0;
    return (examsPassed / totalExamsTaken) * 100;
  }

  /// Create ProgressStat from JSON
  factory ProgressStat.fromJson(Map<String, dynamic> json) {
    return ProgressStat(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      totalDocumentsRead: json['totalDocumentsRead'] as int? ?? 0,
      totalExamsTaken: json['totalExamsTaken'] as int? ?? 0,
      examsPassed: json['examsPassed'] as int? ?? 0,
      averageScore: (json['averageScore'] as num? ?? 0).toDouble(),
      streakDays: json['streakDays'] as int? ?? 0,
      lastStudyDate: DateTime.tryParse(json['lastStudyDate'] as String? ?? '') ?? DateTime.now(),
      completionPercentage: (json['completionPercentage'] as num? ?? 0).toDouble(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Convert ProgressStat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'subjectId': subjectId,
      'totalDocumentsRead': totalDocumentsRead,
      'totalExamsTaken': totalExamsTaken,
      'examsPassed': examsPassed,
      'averageScore': averageScore,
      'streakDays': streakDays,
      'lastStudyDate': lastStudyDate.toIso8601String(),
      'completionPercentage': completionPercentage,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  ProgressStat copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    int? totalDocumentsRead,
    int? totalExamsTaken,
    int? examsPassed,
    double? averageScore,
    int? streakDays,
    DateTime? lastStudyDate,
    double? completionPercentage,
    DateTime? updatedAt,
  }) {
    return ProgressStat(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      totalDocumentsRead: totalDocumentsRead ?? this.totalDocumentsRead,
      totalExamsTaken: totalExamsTaken ?? this.totalExamsTaken,
      examsPassed: examsPassed ?? this.examsPassed,
      averageScore: averageScore ?? this.averageScore,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'ProgressStat(id: $id, studentId: $studentId)';
}
