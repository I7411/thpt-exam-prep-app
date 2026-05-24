import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';
import 'models.dart';
import 'providers_auth.dart';
import 'repository_service.dart';
import 'widgets_document_card.dart';
import 'widgets_stat_card.dart';
import 'widgets_subject_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late final RepositoryService _repositoryService;
  Future<_StudentHomeData>? _homeFuture;
  String? _loadedStudentId;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final studentId = authProvider.currentUser?.id ?? 'student_001';
    if (_loadedStudentId != studentId) {
      _loadedStudentId = studentId;
      _homeFuture = _loadHomeData(studentId);
    }
  }

  Future<_StudentHomeData> _loadHomeData(String studentId) async {
    final subjects = await _repositoryService.subject.getAllSubjects();
    final documents = await _repositoryService.document.getAllDocuments();
    final progressStats = await _repositoryService.progress.getProgressByStudent(studentId);
    final averageScore = await _repositoryService.progress.getAverageScoreByStudent(studentId);
    final totalExams = await _repositoryService.progress.getTotalExamsByStudent(studentId);
    final examsPassed = await _repositoryService.progress.getExamsPassedByStudent(studentId);

    return _StudentHomeData(
      subjects: subjects,
      documents: documents,
      progressStats: progressStats,
      averageScore: averageScore,
      totalExams: totalExams,
      examsPassed: examsPassed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.fullName ??
        authProvider.currentUser?.email ??
        'Học sinh';

    return SafeArea(
      child: FutureBuilder<_StudentHomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải trang chủ: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentDocuments = data.documents.toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
          final featuredSubjects = data.subjects.take(4).toList();
          final highlightedDocuments = recentDocuments.take(3).toList();
          final progressSummary = _ProgressSummary.from(data.progressStats);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(context, userName),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: 'Tiến độ hôm nay',
                  actionText: null,
                  onActionTap: null,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        StatCard(
                          title: 'Tài liệu đã đọc',
                          value: '${progressSummary.totalDocumentsRead}',
                          icon: Icons.description,
                          color: Colors.blue,
                        ),
                        StatCard(
                          title: 'Đề thi đã làm',
                          value: '${progressSummary.totalExamsTaken}',
                          icon: Icons.quiz,
                          color: Colors.orange,
                        ),
                        StatCard(
                          title: 'Điểm TB',
                          value: data.averageScore.toStringAsFixed(1),
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                        StatCard(
                          title: 'Chuỗi ngày',
                          value: '${progressSummary.maxStreakDays}',
                          icon: Icons.local_fire_department,
                          color: Colors.red,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: 'Môn học chính',
                  actionText: 'Xem tất cả',
                  onActionTap: () {
                    Navigator.pushNamed(context, AppRoutes.studentSubjects);
                  },
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  itemCount: featuredSubjects.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final subject = featuredSubjects[index];
                    final config = _subjectCardConfig(subject.name);
                    return SubjectCard(
                      name: subject.name,
                      icon: config.icon,
                      color: config.color,
                      progress: '${subject.totalDocuments} tài liệu',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.studentDocuments,
                          arguments: subject.id,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: 'Đề thi gợi ý',
                  actionText: 'Xem tất cả',
                  onActionTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Màn hình đề thi sẽ có ở giai đoạn sau.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.subjects.take(3).length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final subject = data.subjects[index];
                      return _buildExamCard(
                        context,
                        title: 'Đề thi thử ${subject.name}\nlần ${index + 1}',
                        subject: subject.name,
                        duration: '${45 + index * 5} phút',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  title: 'Tài liệu mới',
                  actionText: 'Xem tất cả',
                  onActionTap: () {
                    Navigator.pushNamed(context, AppRoutes.studentDocuments);
                  },
                ),
                const SizedBox(height: 12),
                ...highlightedDocuments.map((document) {
                  final subjectName = _findSubjectName(data.subjects, document.subjectId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 160,
                      child: DocumentCard(
                        title: document.title,
                        subject: subjectName,
                        duration: '${_estimateReadingTime(document)} phút đọc',
                        preview: document.description,
                        isMarked: false,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.studentDocumentDetail,
                            arguments: document,
                          );
                        },
                        onMarkTap: () {},
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade600,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Xin chào, $userName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.studentNotifications);
                },
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                tooltip: 'Thông báo',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hôm nay là ngày tốt để học thêm một chút và giữ nhịp tiến độ.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String? actionText,
    required VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionText),
          ),
      ],
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required String title,
    required String subject,
    required String duration,
  }) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.withOpacity(0.18),
            Colors.blue.withOpacity(0.12),
          ],
        ),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.22),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đề thi gợi ý: ${subject.trim()}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.quiz, color: Colors.deepPurple, size: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(subject),
                        labelStyle: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.deepPurple.withOpacity(0.12),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        duration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimateReadingTime(StudyDocument document) {
    final sourceText = document.content.isNotEmpty ? document.content : document.description;
    final estimatedMinutes = (sourceText.length / 500).ceil();
    return estimatedMinutes.clamp(5, 30);
  }

  String _findSubjectName(List<Subject> subjects, String subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        return subject.name;
      }
    }
    return 'Môn học';
  }

  _SubjectCardConfig _subjectCardConfig(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'toán':
        return _SubjectCardConfig(Icons.calculate, Colors.blue);
      case 'ngữ văn':
        return _SubjectCardConfig(Icons.menu_book, Colors.red);
      case 'tiếng anh':
        return _SubjectCardConfig(Icons.language, Colors.green);
      case 'vật lý':
        return _SubjectCardConfig(Icons.science, Colors.purple);
      case 'hóa học':
        return _SubjectCardConfig(Icons.science, Colors.orange);
      case 'sinh học':
        return _SubjectCardConfig(Icons.biotech, Colors.pink);
      case 'lịch sử':
        return _SubjectCardConfig(Icons.history_edu, Colors.brown);
      case 'địa lý':
        return _SubjectCardConfig(Icons.public, Colors.teal);
      default:
        return _SubjectCardConfig(Icons.subject, Colors.grey);
    }
  }
}

class _StudentHomeData {
  final List<Subject> subjects;
  final List<StudyDocument> documents;
  final List<ProgressStat> progressStats;
  final double averageScore;
  final int totalExams;
  final int examsPassed;

  const _StudentHomeData({
    required this.subjects,
    required this.documents,
    required this.progressStats,
    required this.averageScore,
    required this.totalExams,
    required this.examsPassed,
  });
}

class _ProgressSummary {
  final int totalDocumentsRead;
  final int totalExamsTaken;
  final int maxStreakDays;

  const _ProgressSummary({
    required this.totalDocumentsRead,
    required this.totalExamsTaken,
    required this.maxStreakDays,
  });

  factory _ProgressSummary.from(List<ProgressStat> progressStats) {
    var totalDocumentsRead = 0;
    var totalExamsTaken = 0;
    var maxStreakDays = 0;

    for (final stat in progressStats) {
      totalDocumentsRead += stat.totalDocumentsRead;
      totalExamsTaken += stat.totalExamsTaken;
      if (stat.streakDays > maxStreakDays) {
        maxStreakDays = stat.streakDays;
      }
    }

    return _ProgressSummary(
      totalDocumentsRead: totalDocumentsRead,
      totalExamsTaken: totalExamsTaken,
      maxStreakDays: maxStreakDays,
    );
  }
}

class _SubjectCardConfig {
  final IconData icon;
  final Color color;

  const _SubjectCardConfig(this.icon, this.color);
}
