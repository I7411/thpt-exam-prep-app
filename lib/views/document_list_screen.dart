import 'package:flutter/material.dart';

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
  final Set<String> _markedDocumentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _selectedSubjectId = widget.initialSubjectId;
    _dataFuture = _loadData();
  }

  Future<_DocumentListData> _loadData() async {
    final documentsFuture = _repositoryService.document
        .getAllDocuments()
        .timeout(const Duration(seconds: 12));
    final subjectsFuture = _repositoryService.subject.getAllSubjects().timeout(
      const Duration(seconds: 12),
    );
    final documents = (await documentsFuture).take(20).toList();
    final subjects = await subjectsFuture;
    return _DocumentListData(documents: documents, subjects: subjects);
  }

  void _retryLoad() {
    setState(() {
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

          final subjectsById = <String, Subject>{
            for (final subject in data.subjects) subject.id: subject,
          };

          final documents = data.documents.toList()
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
          final filteredDocuments = _selectedSubjectId == null
              ? documents
              : documents
                    .where(
                      (document) => document.subjectId == _selectedSubjectId,
                    )
                    .toList();

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
                  itemCount: data.subjects.length + 1,
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

                    final subject = data.subjects[index - 1];
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
                          final isMarked = _markedDocumentIds.contains(
                            document.id,
                          );

                          return SizedBox(
                            height: 176,
                            child: DocumentCard(
                              title: document.title,
                              subject: subjectName,
                              duration:
                                  '${_estimateReadingTime(document)} phút đọc',
                              preview: document.description,
                              isMarked: isMarked,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.studentDocumentDetail,
                                  arguments: document,
                                );
                              },
                              onMarkTap: () {
                                setState(() {
                                  if (isMarked) {
                                    _markedDocumentIds.remove(document.id);
                                  } else {
                                    _markedDocumentIds.add(document.id);
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isMarked
                                          ? 'Bỏ đánh dấu: ${document.title}'
                                          : 'Đã đánh dấu: ${document.title}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
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

  const _DocumentListData({required this.documents, required this.subjects});
}
