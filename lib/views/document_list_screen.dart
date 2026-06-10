import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

import '../app_theme.dart';
import '../core/routes/app_routes.dart';
import '../models.dart';
import '../repository_service.dart';
import '../widgets_document_card.dart';

class DocumentListScreen extends StatefulWidget {
  final String? initialSubjectId;

  const DocumentListScreen({super.key, this.initialSubjectId});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  late final RepositoryService _repositoryService;
  late Future<_DocumentListData> _dataFuture;
  String? _selectedSubjectId;
  bool _favoritesLoaded = false;
  final Map<String, DateTime> _favoritesMap = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _selectedSubjectId = widget.initialSubjectId;
    _dataFuture = _loadData();
  }

  Future<_DocumentListData> _loadData() async {
    final authProvider = context.read<AuthController>();
    final userId = authProvider.currentUser?.id ?? 'student_001';

    final documentsFuture = _repositoryService.document
        .getAllDocuments()
        .timeout(const Duration(seconds: 12));
    final subjectsFuture = _repositoryService.subject.getAllSubjects().timeout(
      const Duration(seconds: 12),
    );
    final favoritesFuture = FirebaseFirestore.instance
        .collection('saved_materials')
        .where('userId', isEqualTo: userId)
        .where('isFavorite', isEqualTo: true)
        .get()
        .timeout(const Duration(seconds: 10));

    final documents = (await documentsFuture).take(20).toList();
    final subjects = await subjectsFuture;
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

    return _DocumentListData(
      documents: documents,
      subjects: subjects,
      favoritesMap: favoritesMap,
    );
  }

  void _retryLoad() {
    setState(() {
      _favoritesLoaded = false;
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu học tập'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<_DocumentListData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Lỗi tải tài liệu: ${snapshot.error}');
            return _ErrorState(onRetry: _retryLoad);
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_favoritesLoaded) {
            _favoritesMap.clear();
            _favoritesMap.addAll(data.favoritesMap);
            _favoritesLoaded = true;
          }

          final subjectsById = <String, Subject>{
            for (final subject in data.subjects) subject.id: subject,
          };

          final documents = data.documents.toList();
          
          List<StudyDocument> filteredDocuments;
          if (_selectedSubjectId == 'new_materials') {
            filteredDocuments = documents.toList()
              ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
          } else if (_selectedSubjectId == null) {
            filteredDocuments = documents.toList();
            filteredDocuments.sort((left, right) {
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
          } else {
            filteredDocuments = documents
                .where((document) => document.subjectId == _selectedSubjectId)
                .toList();
            filteredDocuments.sort((left, right) {
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
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.cyanSoft,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${filteredDocuments.length} tài liệu sẵn sàng cho buổi ôn tập hôm nay',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: data.subjects.length + 2,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedSubjectId == null;
                      return FilterChip(
                        label: const Text('Tất cả'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedSubjectId = null;
                          });
                        },
                      );
                    }
                    if (index == 1) {
                      final isSelected = _selectedSubjectId == 'new_materials';
                      return FilterChip(
                        label: const Text('Mới nhất'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedSubjectId = 'new_materials';
                          });
                        },
                      );
                    }

                    final subject = data.subjects[index - 2];
                    final isSelected = _selectedSubjectId == subject.id;
                    return FilterChip(
                      label: Text(subject.name),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedSubjectId = subject.id;
                        });
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: filteredDocuments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có tài liệu nào',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocuments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = filteredDocuments[index];
                          final subjectName =
                              subjectsById[document.subjectId]?.name ??
                              'Môn học';
                          final isMarked = _favoritesMap.containsKey(document.id);

                          return SizedBox(
                            height: 176,
                            child: DocumentCard(
                              title: document.title,
                              subject: subjectName,
                              duration:
                                  '${_estimateReadingTime(document)} phút đọc',
                              preview: document.description,
                              isMarked: isMarked,
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.studentDocumentDetail,
                                  arguments: document,
                                );
                                _retryLoad();
                              },
                              onMarkTap: () async {
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
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Lỗi tải tài liệu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Không thể tải danh sách tài liệu. Vui lòng kiểm tra mạng và thử lại.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentListData {
  final List<StudyDocument> documents;
  final List<Subject> subjects;
  final Map<String, DateTime> favoritesMap;

  const _DocumentListData({
    required this.documents,
    required this.subjects,
    required this.favoritesMap,
  });
}
