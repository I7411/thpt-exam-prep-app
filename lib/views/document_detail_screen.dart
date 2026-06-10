import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thpt_exam_prep_app/providers_auth.dart';

import '../app_theme.dart';
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
  bool _checkingFavorite = true;

  @override
  void initState() {
    super.initState();
    _repositoryService = RepositoryService.instance;
    _subjectFuture = _repositoryService.subject.getSubjectById(
      widget.document.subjectId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIsMarked();
  }

  Future<void> _checkIsMarked() async {
    final authProvider = context.read<AuthController>();
    final userId = authProvider.currentUser?.id ?? 'student_001';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('saved_materials')
          .doc('${userId}_${widget.document.id}')
          .get();
      
      final learnedDoc = await FirebaseFirestore.instance
          .collection('learned_materials')
          .doc('${userId}_${widget.document.id}')
          .get();

      setState(() {
        _isMarked = doc.exists && doc.data()?['isFavorite'] == true;
        _isLearned = learnedDoc.exists;
        _checkingFavorite = false;
      });
    } catch (e) {
      debugPrint('Lỗi kiểm tra trạng thái đánh dấu: $e');
      setState(() {
        _checkingFavorite = false;
      });
    }
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
            onPressed: _checkingFavorite ? null : () async {
              final nextIsFavorite = !_isMarked;
              final authProvider = context.read<AuthController>();
              final userId = authProvider.currentUser?.id ?? 'student_001';

              final docRef = FirebaseFirestore.instance
                  .collection('saved_materials')
                  .doc('${userId}_${widget.document.id}');

              if (nextIsFavorite) {
                await docRef.set({
                  'userId': userId,
                  'materialId': widget.document.id,
                  'isFavorite': true,
                  'favoriteAt': FieldValue.serverTimestamp(),
                  'savedAt': FieldValue.serverTimestamp(),
                });
              } else {
                await docRef.delete();
              }

              setState(() {
                _isMarked = nextIsFavorite;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      nextIsFavorite
                          ? 'Đã thêm vào bộ sưu tập'
                          : 'Đã bỏ khỏi bộ sưu tập',
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              _isMarked ? Icons.bookmark_rounded : Icons.bookmark_outline,
              color: _isMarked ? AppColors.accent : null,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Subject?>(
        future: _subjectFuture,
        builder: (context, snapshot) {
          final subjectName = snapshot.data?.name ?? 'Môn học';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.panel),
                    gradient: AppGradients.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          subjectName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.document.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _HeaderPill(
                            icon: Icons.schedule_rounded,
                            label:
                                '${_estimateReadingTime(widget.document)} phút đọc',
                          ),
                          _HeaderPill(
                            icon: Icons.visibility_outlined,
                            label: '${widget.document.views} lượt xem',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        label: 'Tác giả',
                        value: widget.document.author,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        label: 'Trạng thái',
                        value: _isLearned ? 'Đã học' : 'Đang học',
                        color: _isLearned ? AppColors.success : AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(title: 'Tóm tắt nội dung'),
                const SizedBox(height: 12),
                _ReadingPanel(
                  text: widget.document.description.isNotEmpty
                      ? widget.document.description
                      : _extractSummary(widget.document.content),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle(title: 'Nội dung xem nhanh'),
                const SizedBox(height: 12),
                _ReadingPanel(
                  text: _extractSummary(widget.document.content),
                  softColor: AppColors.cyanSoft,
                ),
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () async {
              final authProvider = context.read<AuthController>();
              final userId = authProvider.currentUser?.id ?? 'student_001';
              
              try {
                await FirebaseFirestore.instance
                    .collection('learned_materials')
                    .doc('${userId}_${widget.document.id}')
                    .set({
                      'userId': userId,
                      'materialId': widget.document.id,
                      'learnedAt': FieldValue.serverTimestamp(),
                    });
                
                setState(() {
                  _isLearned = true;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu tài liệu là đã học'),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Lỗi khi đánh dấu tài liệu đã học: $e');
              }
            },
            icon: Icon(_isLearned ? Icons.check_circle : Icons.done_rounded),
            label: Text(_isLearned ? 'Đã học' : 'Đánh dấu đã học'),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
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
    final sourceText =
        document.content.isNotEmpty ? document.content : document.description;
    final estimatedMinutes = (sourceText.length / 500).ceil();
    return estimatedMinutes.clamp(5, 30);
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({
    required this.icon,
    required this.label,
  });

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
          Icon(icon, color: Colors.white, size: 16),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _ReadingPanel extends StatelessWidget {
  final String text;
  final Color softColor;

  const _ReadingPanel({
    required this.text,
    this.softColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.65,
              color: AppColors.ink,
            ),
      ),
    );
  }
}
