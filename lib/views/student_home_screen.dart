import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/app_config.dart';
import 'package:thpt_exam_prep_app/app_routes.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';
import 'package:thpt_exam_prep_app/models.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';
import 'package:thpt_exam_prep_app/repository_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/widgets_document_card.dart';
import 'package:thpt_exam_prep_app/widgets_subject_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late final RepositoryService _repositoryService;
  Future<_StudentHomeData>? _homeFuture;
  String? _loadedStudentId;
  bool _favoritesLoaded = false;
  final Map<String, DateTime> _favoritesMap = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthController>(context);

    if (authProvider.isLoading && authProvider.currentUser == null) {
      return;
    }

    final studentId = _resolveStudentId(authProvider);
    if (studentId == null) {
      _loadedStudentId = null;
      _homeFuture = null;
      return;
    }

    if (_loadedStudentId != studentId) {
      _loadedStudentId = studentId;
      _homeFuture = _loadHomeData(studentId);
    }
  }

  String? _resolveStudentId(AuthController authProvider) {
    final currentUserId = authProvider.currentUser?.id.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    if (AppConfig.enableMockData) {
      return 'student_001';
    }

    return null;
  }

  Future<_StudentHomeData> _loadHomeData(String studentId) async {
    final subjectsFuture = _repositoryService.subject.getAllSubjects().timeout(
      const Duration(seconds: 12),
    );
    final documentsFuture = _repositoryService.document
        .getAllDocuments()
        .timeout(const Duration(seconds: 12));
    final examsFuture = _repositoryService.exam.getAllExams().timeout(
      const Duration(seconds: 12),
    );
    final progressStatsFuture = _repositoryService.progress
        .getProgressByStudent(studentId)
        .timeout(const Duration(seconds: 12));
    final averageScoreFuture = _repositoryService.progress
        .getAverageScoreByStudent(studentId)
        .timeout(const Duration(seconds: 12));
    final totalExamsFuture = _repositoryService.progress
        .getTotalExamsByStudent(studentId)
        .timeout(const Duration(seconds: 12));
    final examsPassedFuture = _repositoryService.progress
        .getExamsPassedByStudent(studentId)
        .timeout(const Duration(seconds: 12));

    final favoritesFuture = FirebaseFirestore.instance
        .collection('saved_materials')
        .where('userId', isEqualTo: studentId)
        .where('isFavorite', isEqualTo: true)
        .get()
        .timeout(const Duration(seconds: 10));

    final learnedCountFuture = _repositoryService.progress
        .getTotalLearnedDocuments(studentId)
        .timeout(const Duration(seconds: 10));

    final subjects = await subjectsFuture;
    final documents = (await documentsFuture).take(20).toList();
    final exams = (await examsFuture).take(20).toList();
    final progressStats = await progressStatsFuture;
    final averageScore = await averageScoreFuture;
    final totalExams = await totalExamsFuture;
    final examsPassed = await examsPassedFuture;
    final favoritesSnapshot = await favoritesFuture;

    final favoritesMap = <String, DateTime>{};
    for (final doc in favoritesSnapshot.docs) {
      final data = doc.data();
      final materialId = data['materialId'] as String?;
      final favoriteAtVal = data['favoriteAt'];
      if (materialId != null) {
        DateTime favTime = DateTime.now();
        if (favoriteAtVal is Timestamp) {
          favTime = favoriteAtVal.toDate();
        } else if (favoriteAtVal is String) {
          favTime = DateTime.tryParse(favoriteAtVal) ?? DateTime.now();
        }
        favoritesMap[materialId] = favTime;
      }
    }

    final totalLearnedDocuments = await learnedCountFuture;

    return _StudentHomeData(
      subjects: subjects,
      documents: documents,
      exams: exams,
      progressStats: progressStats,
      averageScore: averageScore,
      totalExams: totalExams,
      examsPassed: examsPassed,
      totalLearnedDocuments: totalLearnedDocuments,
      favoritesMap: favoritesMap,
    );
  }

  void _retryLoad() {
    final studentId = _resolveStudentId(context.read<AuthController>());
    if (studentId == null) {
      setState(() {
        _loadedStudentId = null;
        _homeFuture = null;
        _favoritesLoaded = false;
      });
      return;
    }

    setState(() {
      _loadedStudentId = studentId;
      _homeFuture = _loadHomeData(studentId);
      _favoritesLoaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthController>(context);

    if (authProvider.isLoading && authProvider.currentUser == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final studentId = _resolveStudentId(authProvider);
    if (studentId == null) {
      return SafeArea(child: _buildLoginRequiredState(context));
    }

    final future = _homeFuture ??= _loadHomeData(studentId);
    _loadedStudentId ??= studentId;

    final userName = _displayText(
      authProvider.currentUser?.fullName.isNotEmpty == true
          ? authProvider.currentUser?.fullName
          : authProvider.currentUser?.email,
      fallback: 'Học sinh',
    );

    return SafeArea(
      child: FutureBuilder<_StudentHomeData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error);
          }

          final data = snapshot.data;
          if (data == null) {
            return _buildEmptyState(
              context,
              icon: Icons.inbox_outlined,
              title: 'Chưa có dữ liệu trang chủ',
              message: 'Hãy thử tải lại hoặc kiểm tra kết nối dữ liệu.',
              actionText: 'Thử lại',
              onActionTap: _retryLoad,
            );
          }

          if (!_favoritesLoaded) {
            _favoritesMap.clear();
            _favoritesMap.addAll(data.favoritesMap);
            _favoritesLoaded = true;
          }

          final recentDocuments = data.documents.toList()
            ..sort((left, right) {
              final leftFavTime = _favoritesMap[left.id];
              final rightFavTime = _favoritesMap[right.id];

              if (leftFavTime != null && rightFavTime != null) {
                return rightFavTime.compareTo(leftFavTime);
              } else if (leftFavTime != null) {
                return -1;
              } else if (rightFavTime != null) {
                return 1;
              } else {
                return right.createdAt.compareTo(left.createdAt);
              }
            });
          final featuredSubjects = data.subjects.take(4).toList();
          final highlightedDocuments = recentDocuments.take(3).toList();
          final suggestedExams =
              data.exams.where((exam) => exam.isPublished).toList()..sort(
                (left, right) => right.createdAt.compareTo(left.createdAt),
              );
          final progressSummary = _ProgressSummary.from(
            data.progressStats,
            learnedDocumentsCount: data.totalLearnedDocuments,
          );

          return RefreshIndicator(
            onRefresh: () async {
              _retryLoad();
              await _homeFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  _buildProgressGrid(context, data, progressSummary),
                  if (data.progressStats.isEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCompactMessage(
                      context,
                      icon: Icons.insights_outlined,
                      text:
                          'Chưa có dữ liệu tiến độ. Hãy đọc tài liệu hoặc làm đề thi để bắt đầu.',
                    ),
                  ],
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
                  if (featuredSubjects.isEmpty)
                    _buildSectionEmptyState(
                      context,
                      icon: Icons.subject_outlined,
                      title: 'Chưa có môn học nào',
                      message:
                          'Danh sách môn học sẽ hiển thị tại đây khi có dữ liệu.',
                    )
                  else
                    _buildSubjectGrid(context, featuredSubjects),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: 'Đề thi thử nổi bật',
                    actionText: 'Xem tất cả',
                    onActionTap: () {
                      Navigator.pushNamed(context, AppRoutes.studentExams);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (suggestedExams.isEmpty)
                    _buildSectionEmptyState(
                      context,
                      icon: Icons.quiz_outlined,
                      title: 'Chưa có đề thi gợi ý',
                      message: 'Các đề thi mới sẽ xuất hiện tại đây.',
                    )
                  else
                    _buildSuggestedExams(
                      context,
                      exams: suggestedExams.take(3).toList(),
                      subjects: data.subjects,
                    ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: 'Tài liệu mới',
                    actionText: 'Xem tất cả',
                    onActionTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentDocuments,
                        arguments: 'new_materials',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (highlightedDocuments.isEmpty)
                    _buildSectionEmptyState(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Chưa có tài liệu mới',
                      message: 'Tài liệu học tập mới sẽ hiển thị tại đây.',
                    )
                  else
                    ...highlightedDocuments.map((document) {
                      final subjectName = _findSubjectName(
                        data.subjects,
                        document.subjectId,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 176,
                          child: DocumentCard(
                            title: _displayText(document.title),
                            subject: subjectName,
                            duration:
                                '${_estimateReadingTime(document)} phút đọc',
                            preview: _displayText(document.description),
                            isMarked: _favoritesMap.containsKey(document.id),
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.studentDocumentDetail,
                                arguments: document,
                              );
                              _retryLoad();
                            },
                            onMarkTap: () async {
                              final isMarked = _favoritesMap.containsKey(document.id);
                              final nextIsFavorite = !isMarked;
                              final authProvider = context.read<AuthController>();
                              final userId = authProvider.currentUser?.id ?? 'student_001';

                              final docRef = FirebaseFirestore.instance
                                  .collection('saved_materials')
                                  .doc('${userId}_${document.id}');

                              if (nextIsFavorite) {
                                await docRef.set({
                                  'userId': userId,
                                  'materialId': document.id,
                                  'isFavorite': true,
                                  'favoriteAt': FieldValue.serverTimestamp(),
                                  'savedAt': FieldValue.serverTimestamp(),
                                });
                              } else {
                                await docRef.delete();
                              }

                              setState(() {
                                if (nextIsFavorite) {
                                  _favoritesMap[document.id] = DateTime.now();
                                } else {
                                  _favoritesMap.remove(document.id);
                                }
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      nextIsFavorite
                                          ? 'Đã đánh dấu: ${document.title}'
                                          : 'Bỏ đánh dấu: ${document.title}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressGrid(
    BuildContext context,
    _StudentHomeData data,
    _ProgressSummary progressSummary,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCompactStatCard(
            context,
            title: 'Tài liệu',
            value: '${progressSummary.totalDocumentsRead}',
            icon: Icons.description,
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.studentHistory,
              arguments: 0,
            ),
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            context,
            title: 'Đề thi',
            value: '${data.totalExams}',
            icon: Icons.quiz,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.studentHistory,
              arguments: 1,
            ),
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            context,
            title: 'Đã đạt',
            value: '${data.examsPassed}',
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.studentHistory,
              arguments: 1,
            ),
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            context,
            title: 'Điểm TB',
            value: data.averageScore.toStringAsFixed(1),
            icon: Icons.star,
            color: Colors.amber,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.studentHistory,
              arguments: 1,
            ),
          ),
          const SizedBox(width: 10),
          _buildCompactStatCard(
            context,
            title: 'Chuỗi ngày',
            value: '${progressSummary.maxStreakDays}',
            icon: Icons.local_fire_department,
            color: Colors.red,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.studentHistory,
              arguments: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGrid(BuildContext context, List<Subject> subjects) {
    return GridView.builder(
      itemCount: subjects.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final subjectName = _displayText(subject.name);
        final config = _subjectCardConfig(subjectName);
        return SubjectCard(
          name: subjectName,
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
    );
  }

  Widget _buildSuggestedExams(
    BuildContext context, {
    required List<Exam> exams,
    required List<Subject> subjects,
  }) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exams.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exam = exams[index];
          final subjectName = _findSubjectName(subjects, exam.subjectId);
          return _buildExamCard(context, exam: exam, subject: subjectName);
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        gradient: AppGradients.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Chào $userName, hôm nay bạn muốn ôn môn gì?',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentTeacherRequests,
                      );
                    },
                    icon: const Icon(
                      Icons.assignment_ind_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'Lời mời giáo viên',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.studentNotifications,
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    tooltip: 'Thông báo',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn nhanh tài liệu, đề thi thử hoặc theo dõi tiến độ để giữ nhịp ôn thi mỗi ngày.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _GreetingPill(
                icon: Icons.menu_book_rounded,
                label: 'Ôn tập hôm nay',
              ),
              _GreetingPill(icon: Icons.quiz_rounded, label: 'Thi thử'),
              _GreetingPill(icon: Icons.trending_up_rounded, label: 'Tiến độ'),
            ],
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
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (actionText != null)
          TextButton(onPressed: onActionTap, child: Text(actionText)),
      ],
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required Exam exam,
    required String subject,
  }) {
    return Container(
      width: 220,
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
        border: Border.all(color: Colors.deepPurple.withOpacity(0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.studentExamTaking,
            arguments: exam,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.quiz, color: Colors.deepPurple, size: 30),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _displayText(exam.title, fallback: 'Đề thi thử'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 112),
                            child: Text(
                              subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.deepPurple.withOpacity(0.12),
                          side: BorderSide.none,
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('${exam.durationMinutes} phút'),
                          backgroundColor: Colors.white.withOpacity(0.65),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    debugPrint('Lỗi tải trang chủ: $error');
    return _buildEmptyState(
      context,
      icon: Icons.error_outline,
      title: 'Lỗi tải trang chủ',
      message:
          'Không thể tải dữ liệu trang chủ. Vui lòng kiểm tra mạng và thử lại.',
      actionText: 'Thử lại',
      onActionTap: _retryLoad,
    );
  }

  Widget _buildLoginRequiredState(BuildContext context) {
    return _buildEmptyState(
      context,
      icon: Icons.lock_outline,
      title: 'Bạn cần đăng nhập',
      message: 'Vui lòng đăng nhập để xem tiến độ học tập của bạn.',
      actionText: 'Đăng nhập',
      actionIcon: Icons.login,
      onActionTap: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String? actionText,
    IconData actionIcon = Icons.refresh,
    required VoidCallback? onActionTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (actionText != null && onActionTap != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onActionTap,
                icon: Icon(actionIcon),
                label: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMessage(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.indigo.shade700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _estimateReadingTime(StudyDocument document) {
    final sourceText = document.content.isNotEmpty
        ? document.content
        : document.description;
    final estimatedMinutes = (sourceText.length / 500).ceil();
    return estimatedMinutes.clamp(5, 30);
  }

  String _findSubjectName(List<Subject> subjects, String subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        return _displayText(subject.name);
      }
    }
    return 'Môn học';
  }

  _SubjectCardConfig _subjectCardConfig(String subjectName) {
    final normalized = _normalizeSubjectName(subjectName);

    switch (normalized) {
      case 'toán':
      case 'toan':
        return const _SubjectCardConfig(Icons.calculate, Color(0xFF3B82F6));
      case 'ngữ văn':
      case 'ngu van':
        return const _SubjectCardConfig(Icons.menu_book, Color(0xFFFB7185));
      case 'tiếng anh':
      case 'tieng anh':
        return const _SubjectCardConfig(Icons.language, AppColors.success);
      case 'vật lý':
      case 'vat ly':
        return const _SubjectCardConfig(Icons.science, Color(0xFF8B5CF6));
      case 'hóa học':
      case 'hoa hoc':
        return const _SubjectCardConfig(Icons.science, AppColors.accent);
      case 'sinh học':
      case 'sinh hoc':
        return const _SubjectCardConfig(Icons.biotech, Color(0xFF22C55E));
      case 'lịch sử':
      case 'lich su':
        return const _SubjectCardConfig(Icons.history_edu, Color(0xFFB45309));
      case 'địa lý':
      case 'dia ly':
        return const _SubjectCardConfig(Icons.public, Color(0xFF0891B2));
      case 'gdcd':
      case 'giáo dục công dân':
      case 'giao duc cong dan':
      case 'giáo dục kinh tế và pháp luật':
      case 'giao duc kinh te va phap luat':
        return const _SubjectCardConfig(Icons.gavel, AppColors.primary);
      default:
        return const _SubjectCardConfig(Icons.subject, AppColors.muted);
    }
  }

  String _normalizeSubjectName(String value) {
    return _displayText(
      value,
    ).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _displayText(String? value, {String fallback = ''}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }

    return _repairMojibake(trimmed).trim();
  }

  String _repairMojibake(String value) {
    var current = value;

    for (var i = 0; i < 2; i++) {
      if (!_looksLikeMojibake(current)) {
        break;
      }

      final decoded = _tryDecodeUtf8AsLatin1(current);
      if (decoded == null ||
          _mojibakeScore(decoded) >= _mojibakeScore(current)) {
        break;
      }

      current = decoded;
    }

    return current;
  }

  bool _looksLikeMojibake(String value) => _mojibakeScore(value) > 0;

  int _mojibakeScore(String value) {
    const markers = <int>{
      0x00C2,
      0x00C3,
      0x00C4,
      0x00C6,
      0x00C5,
      0x00E2,
      0x00F0,
      0x00BE,
      0x00BA,
      0x00BB,
      0x00BC,
      0x00BD,
      0x0178,
      0x201A,
      0x201E,
      0x2020,
      0x2021,
      0x2030,
      0x2039,
      0x0152,
      0x017D,
      0x2018,
      0x2019,
      0x201C,
      0x201D,
      0x2022,
      0x2013,
      0x2014,
      0x02DC,
      0x2122,
      0x0161,
      0x203A,
      0x0153,
      0x017E,
    };

    var score = 0;
    for (final rune in value.runes) {
      if (markers.contains(rune) || (rune >= 0x0080 && rune <= 0x009F)) {
        score++;
      }
    }
    return score;
  }

  String? _tryDecodeUtf8AsLatin1(String value) {
    try {
      return utf8.decode(latin1.encode(value));
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}

class _StudentHomeData {
  final List<Subject> subjects;
  final List<StudyDocument> documents;
  final List<Exam> exams;
  final List<ProgressStat> progressStats;
  final double averageScore;
  final int totalExams;
  final int examsPassed;
  final int totalLearnedDocuments;
  final Map<String, DateTime> favoritesMap;

  const _StudentHomeData({
    required this.subjects,
    required this.documents,
    required this.exams,
    required this.progressStats,
    required this.averageScore,
    required this.totalExams,
    required this.examsPassed,
    required this.totalLearnedDocuments,
    required this.favoritesMap,
  });
}

class _ProgressSummary {
  final int totalDocumentsRead;
  final int maxStreakDays;

  const _ProgressSummary({
    required this.totalDocumentsRead,
    required this.maxStreakDays,
  });

  factory _ProgressSummary.from(
    List<ProgressStat> progressStats, {
    int learnedDocumentsCount = 0,
  }) {
    var maxStreakDays = 0;
    for (final stat in progressStats) {
      if (stat.streakDays > maxStreakDays) {
        maxStreakDays = stat.streakDays;
      }
    }
    // Use the authoritative count from Firestore learned_materials instead of
    // ProgressStat.totalDocumentsRead (which is always 0 for docs-only reads).
    return _ProgressSummary(
      totalDocumentsRead: learnedDocumentsCount,
      maxStreakDays: maxStreakDays,
    );
  }
}

class _SubjectCardConfig {
  final IconData icon;
  final Color color;

  const _SubjectCardConfig(this.icon, this.color);
}

class _GreetingPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GreetingPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
