/// Admin report statistic model (Thá»‘ng kÃª bÃ¡o cÃ¡o)
class AdminReportStat {
  final String id;
  final int totalUsers;
  final int totalStudents;
  final int totalTeachers;
  final int totalExams;
  final int totalDocuments;
  final int totalExamAttempts;
  final double averageExamScore;
  final int examPassRate;
  final int activeUsersThisWeek;
  final DateTime generatedAt;

  const AdminReportStat({
    required this.id,
    required this.totalUsers,
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalExams,
    required this.totalDocuments,
    required this.totalExamAttempts,
    required this.averageExamScore,
    required this.examPassRate,
    required this.activeUsersThisWeek,
    required this.generatedAt,
  });

  /// Calculate teacher to student ratio
  double getTeacherToStudentRatio() {
    if (totalStudents == 0) return 0;
    return totalTeachers / totalStudents;
  }

  /// Get exam per document ratio
  double getExamPerDocumentRatio() {
    if (totalDocuments == 0) return 0;
    return totalExams / totalDocuments;
  }

  /// Create AdminReportStat from JSON
  factory AdminReportStat.fromJson(Map<String, dynamic> json) {
    return AdminReportStat(
      id: json['id'] as String? ?? '',
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalTeachers: json['totalTeachers'] as int? ?? 0,
      totalExams: json['totalExams'] as int? ?? 0,
      totalDocuments: json['totalDocuments'] as int? ?? 0,
      totalExamAttempts: json['totalExamAttempts'] as int? ?? 0,
      averageExamScore: (json['averageExamScore'] as num? ?? 0).toDouble(),
      examPassRate: json['examPassRate'] as int? ?? 0,
      activeUsersThisWeek: json['activeUsersThisWeek'] as int? ?? 0,
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convert AdminReportStat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalUsers': totalUsers,
      'totalStudents': totalStudents,
      'totalTeachers': totalTeachers,
      'totalExams': totalExams,
      'totalDocuments': totalDocuments,
      'totalExamAttempts': totalExamAttempts,
      'averageExamScore': averageExamScore,
      'examPassRate': examPassRate,
      'activeUsersThisWeek': activeUsersThisWeek,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  AdminReportStat copyWith({
    String? id,
    int? totalUsers,
    int? totalStudents,
    int? totalTeachers,
    int? totalExams,
    int? totalDocuments,
    int? totalExamAttempts,
    double? averageExamScore,
    int? examPassRate,
    int? activeUsersThisWeek,
    DateTime? generatedAt,
  }) {
    return AdminReportStat(
      id: id ?? this.id,
      totalUsers: totalUsers ?? this.totalUsers,
      totalStudents: totalStudents ?? this.totalStudents,
      totalTeachers: totalTeachers ?? this.totalTeachers,
      totalExams: totalExams ?? this.totalExams,
      totalDocuments: totalDocuments ?? this.totalDocuments,
      totalExamAttempts: totalExamAttempts ?? this.totalExamAttempts,
      averageExamScore: averageExamScore ?? this.averageExamScore,
      examPassRate: examPassRate ?? this.examPassRate,
      activeUsersThisWeek: activeUsersThisWeek ?? this.activeUsersThisWeek,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  String toString() => 'AdminReportStat(id: $id, generatedAt: $generatedAt)';
}
