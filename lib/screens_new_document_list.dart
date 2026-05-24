import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'models.dart';
import 'repository_service.dart';
import 'widgets_document_card.dart';

class DocumentListScreen extends StatefulWidget {
  final String? initialSubjectId;

  const DocumentListScreen({
    Key? key,
    this.initialSubjectId,
  }) : super(key: key);

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
    final documents = await _repositoryService.document.getAllDocuments();
    final subjects = await _repositoryService.subject.getAllSubjects();
    return _DocumentListData(documents: documents, subjects: subjects);
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
            return Center(child: Text('Lỗi tải tài liệu: ${snapshot.error}'));
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
              : documents.where((document) => document.subjectId == _selectedSubjectId).toList();

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: data.subjects.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = filteredDocuments[index];
                          final subjectName = subjectsById[document.subjectId]?.name ?? 'Môn học';
                          final isMarked = _markedDocumentIds.contains(document.id);

                          return SizedBox(
                            height: 170,
                            child: DocumentCard(
                              title: document.title,
                              subject: subjectName,
                              duration: '${_estimateReadingTime(document)} phút đọc',
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
    final sourceText = document.content.isNotEmpty ? document.content : document.description;
    final estimatedMinutes = (sourceText.length / 500).ceil();
    return estimatedMinutes.clamp(5, 30);
  }
}

class _DocumentListData {
  final List<StudyDocument> documents;
  final List<Subject> subjects;

  const _DocumentListData({
    required this.documents,
    required this.subjects,
  });
}
