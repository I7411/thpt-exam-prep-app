import 'package:flutter/material.dart';

import '../models.dart';
import '../repository_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  final StudyDocument document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late final RepositoryService _repositoryService;
  late final Future<Subject?> _subjectFuture;
  bool _isMarked = false;
  bool _isLearned = false;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _subjectFuture = _repositoryService.subject.getSubjectById(widget.document.subjectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isMarked = !_isMarked;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isMarked ? 'Đã thêm vào bộ sưu tập' : 'Đã bỏ khỏi bộ sưu tập',
                  ),
                ),
              );
            },
            icon: Icon(
              _isMarked ? Icons.bookmark : Icons.bookmark_outline,
              color: _isMarked ? Colors.orange : null,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Subject?>(
        future: _subjectFuture,
        builder: (context, snapshot) {
          final subjectName = snapshot.data?.name ?? 'Môn học';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.indigo.withOpacity(0.12),
                          Colors.blue.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subjectName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.document.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Text(
                              '${_estimateReadingTime(widget.document)} phút đọc',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          label: 'Tác giả',
                          value: widget.document.author,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          label: 'Lượt xem',
                          value: '${widget.document.views}',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tóm tắt nội dung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.document.description.isNotEmpty
                          ? widget.document.description
                          : _extractSummary(widget.document.content),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nội dung xem nhanh',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _extractSummary(widget.document.content),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.6,
                            color: Colors.grey[700],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isLearned = true;
                _isMarked = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đánh dấu tài liệu là đã học'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isLearned ? 'Đã học' : 'Đánh dấu đã học',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _extractSummary(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return 'Không có nội dung chi tiết.';
    }

    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return 'Không có nội dung chi tiết.';
    }

    final summaryLines = lines.take(8).toList();
    return summaryLines.join('\n');
  }

  int _estimateReadingTime(StudyDocument document) {
    final sourceText = document.content.isNotEmpty ? document.content : document.description;
    final estimatedMinutes = (sourceText.length / 500).ceil();
    return estimatedMinutes.clamp(5, 30);
  }
}

