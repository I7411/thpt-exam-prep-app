class ClassLeaderboardItem {
  final int rank;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final int totalExamsCompleted;
  final double averageScore;
  final int documentsRead;
  final double overallProgressPercentage;

  const ClassLeaderboardItem({
    required this.rank,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.totalExamsCompleted,
    required this.averageScore,
    required this.documentsRead,
    required this.overallProgressPercentage,
  });

  ClassLeaderboardItem copyWith({
    int? rank,
    String? studentId,
    String? studentName,
    String? studentEmail,
    int? totalExamsCompleted,
    double? averageScore,
    int? documentsRead,
    double? overallProgressPercentage,
  }) {
    return ClassLeaderboardItem(
      rank: rank ?? this.rank,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      totalExamsCompleted: totalExamsCompleted ?? this.totalExamsCompleted,
      averageScore: averageScore ?? this.averageScore,
      documentsRead: documentsRead ?? this.documentsRead,
      overallProgressPercentage:
          overallProgressPercentage ?? this.overallProgressPercentage,
    );
  }
}
