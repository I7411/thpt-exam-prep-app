import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/controllers/auth_controller.dart';
import 'package:thpt_exam_prep_app/controllers/learning_controller.dart';
import 'package:thpt_exam_prep_app/repositories/repository_service.dart';
import 'package:thpt_exam_prep_app/core/routes/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';

import 'package:thpt_exam_prep_app/controllers/exam_controller.dart';

import 'package:thpt_exam_prep_app/widgets/document_card.dart';
import 'package:intl/intl.dart';

class StudentHistoryScreen extends StatefulWidget {
  final int initialTab;

  const StudentHistoryScreen({
    super.key,
    required this.initialTab,
  });

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final RepositoryService _repositoryService;


  bool _isLoading = true;
  String? _errorMessage;

  List<StudyDocument> _allDocuments = [];
  List<Map<String, dynamic>> _learnedHistory = [];
  List<ExamResultData> _examHistory = [];
  List<ProgressStat> _progressStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _mapInitialTab(widget.initialTab),
    );
    _repositoryService = RepositoryService.instance;
    _loadAllHistoryData();
  }

  int _mapInitialTab(int original) {
    if (original == 0) return 0;
    return 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthController>();
      final userId = authProvider.currentUser?.id ?? 'student_001';

      // 1. Fetch all documents from LearningController
      final docs = await context.read<LearningController>().getAllDocuments();
      _allDocuments = docs;

      // 2. Fetch learned documents from LearningController
      _learnedHistory = await context.read<LearningController>().getLearnedHistory(userId);

      // 3. Fetch exam history from SQLite via ExamController
      await context.read<ExamController>().loadStudentExamHistory(userId);

      // 4. Fetch progress stats for streak count
      final stats = await _repositoryService.progress.getProgressByStudent(userId);
      _progressStats = stats;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu lịch sử: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải lịch sử học tập. Vui lòng kiểm tra lại mạng.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examController = context.watch<ExamController>();
    final examHistoryList = examController.history;
    
    // Sync for backwards compatibility with tabs that read _examHistory
    _examHistory = examHistoryList.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử học tập'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tài liệu đã học'),
            Tab(text: 'Chuỗi học tập'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAllHistoryData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLearnedMaterialsTab(),
                    _buildStreakTab(),
                  ],
                ),
    );
  }

  Widget _buildLearnedMaterialsTab() {
    if (_learnedHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'Chưa có tài liệu đã học',
        message: 'Bạn sẽ thấy danh sách tài liệu đã học tại đây sau khi nhấn "Đánh dấu đã học" trong chi tiết tài liệu.',
      );
    }

    final docsMap = {for (final doc in _allDocuments) doc.id: doc};

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _learnedHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _learnedHistory[index];
        final materialId = item['materialId'] as String;
        final learnedAt = item['learnedAt'] as DateTime;
        final doc = docsMap[materialId];

        if (doc == null) {
          return const SizedBox.shrink();
        }

        final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(learnedAt);

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Hoàn thành lúc $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 176,
                child: DocumentCard(
                  title: doc.title,
                  subject: doc.subjectId, // fallback or map if names available
                  duration: 'Đã hoàn thành',
                  preview: doc.description,
                  isMarked: false,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.studentDocumentDetail,
                      arguments: doc,
                    );
                    _loadAllHistoryData();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildStreakTab() {
    int maxStreak = 0;
    for (final stat in _progressStats) {
      if (stat.streakDays > maxStreak) {
        maxStreak = stat.streakDays;
      }
    }

    // Determine study activity logs
    final activityLogs = <Map<String, dynamic>>[];
    for (final exam in _examHistory) {
      activityLogs.add({
        'type': 'Làm đề thi thử',
        'title': exam.exam.title,
        'date': exam.attempt.startedAt,
        'detail': 'Điểm số: ${exam.score.toStringAsFixed(1)}',
        'icon': Icons.quiz,
        'color': Colors.orange,
      });
    }

    final docsMap = {for (final doc in _allDocuments) doc.id: doc};
    for (final learned in _learnedHistory) {
      final docId = learned['materialId'] as String;
      final doc = docsMap[docId];
      if (doc != null) {
        activityLogs.add({
          'type': 'Đọc tài liệu',
          'title': doc.title,
          'date': learned['learnedAt'] as DateTime,
          'detail': 'Đã hoàn thành học',
          'icon': Icons.description,
          'color': Colors.blue,
        });
      }
    }

    activityLogs.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade700, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chuỗi ngày học tập',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$maxStreak Ngày liên tục',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duy trì ôn thi đều đặn mỗi ngày để ghi điểm cao trong kỳ thi chính thức!',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Nhật ký học tập',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (activityLogs.isEmpty)
            _buildEmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'Chưa ghi nhận hoạt động',
              message: 'Hãy bắt đầu làm đề hoặc đọc tài liệu để ghi nhật ký hoạt động học tập đầu tiên của bạn.',
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activityLogs.length,
              itemBuilder: (context, index) {
                final log = activityLogs[index];
                final date = log['date'] as DateTime;
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
                final color = log['color'] as Color;

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(log['icon'] as IconData, color: color, size: 20),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: index == activityLogs.length - 1 ? Colors.transparent : Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['type'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${log['detail']} • $dateStr',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
