import 'package:flutter/material.dart';
import '../models/milestone.dart';
import '../models/kid_profile.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';
import 'attachment_preview.dart';

class MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final Gender gender;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.gender = Gender.neutral,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ProfileTheme.forGender(gender);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineColumn(theme: theme, isFirst: isFirst, isLast: isLast),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: onTap,
                child: _CardBody(
                  milestone: milestone,
                  theme: theme,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onShare: onShare,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineColumn extends StatelessWidget {
  final ProfileTheme theme;
  final bool isFirst;
  final bool isLast;

  const _TimelineColumn({required this.theme, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Column(
        children: [
          if (!isFirst)
            Expanded(
              child: Center(
                child: Container(width: 2, color: theme.accent.withAlpha(80)),
              ),
            )
          else
            const SizedBox(height: 20),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.timelineDot,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: theme.accent.withAlpha(100), blurRadius: 6, spreadRadius: 1)],
            ),
          ),
          if (!isLast)
            Expanded(
              child: Center(
                child: Container(width: 2, color: theme.accent.withAlpha(80)),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final Milestone milestone;
  final ProfileTheme theme;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const _CardBody({required this.milestone, required this.theme, this.onEdit, this.onDelete, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(gradient: theme.headerGradient),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star icon with accent color
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.soft,
                        ),
                        child: Icon(Icons.auto_awesome, size: 18, color: theme.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              milestone.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12, color: theme.accent),
                                const SizedBox(width: 4),
                                Text(
                                  formatDate(milestone.date),
                                  style: TextStyle(fontSize: 12, color: theme.accent, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onEdit != null || onDelete != null || onShare != null)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (_) => [
                            if (onShare != null)
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(children: [
                                  Icon(Icons.share_outlined, size: 18, color: Color(0xFF5B9BD5)),
                                  SizedBox(width: 10),
                                  Text('Share'),
                                ]),
                              ),
                            if (onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ]),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                          ],
                          onSelected: (v) {
                            if (v == 'share') onShare?.call();
                            if (v == 'edit') onEdit?.call();
                            if (v == 'delete') onDelete?.call();
                          },
                        ),
                    ],
                  ),
                  if (milestone.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      milestone.description,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
                    ),
                  ],
                  if (milestone.attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: milestone.attachments.map((a) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AttachmentPreview(attachment: a),
                            if (a.label != null && a.label!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 2),
                                child: Text(
                                  a.label!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                  if (milestone.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: milestone.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.soft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.accent.withAlpha(60)),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontSize: 11, color: theme.accent, fontWeight: FontWeight.w600),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
