import 'package:flutter/material.dart';
import 'package:thpt_exam_prep_app/app_theme.dart';

class DocumentCard extends StatefulWidget {
  final String title;
  final String subject;
  final String duration;
  final String? preview;
  final bool isMarked;
  final VoidCallback? onTap;
  final VoidCallback? onMarkTap;

  const DocumentCard({
    super.key,
    required this.title,
    required this.subject,
    required this.duration,
    this.preview,
    this.isMarked = false,
    this.onTap,
    this.onMarkTap,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.onTap != null) _controller.forward();
      },
      onPointerUp: (_) {
        if (widget.onTap != null) _controller.reverse();
      },
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppGradients.warm,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _Chip(label: widget.subject, color: AppColors.primary),
                            _Chip(label: widget.duration, color: AppColors.secondary),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (widget.preview != null && widget.preview!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.preview!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          'Đọc thêm',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onMarkTap,
                    tooltip: widget.isMarked ? 'Bỏ đánh dấu' : 'Đánh dấu',
                    icon: Icon(
                      widget.isMarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: widget.isMarked ? AppColors.accent : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
