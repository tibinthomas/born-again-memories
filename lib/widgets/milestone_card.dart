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
  final VoidCallback? onFavorite;

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
    this.onFavorite,
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
                  onFavorite: onFavorite,
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
  final VoidCallback? onFavorite;

  const _CardBody({required this.milestone, required this.theme, this.onEdit, this.onDelete, this.onShare, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.accent.withAlpha(18), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withAlpha(18),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent rail
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: theme.headerGradient,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Glass icon circle
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.accent.withAlpha(35),
                                  theme.accent.withAlpha(20),
                                ],
                              ),
                              border: Border.all(
                                  color: theme.accent.withAlpha(50), width: 1),
                            ),
                            child: Icon(Icons.auto_awesome,
                                size: 16, color: theme.accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  milestone.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 11, color: theme.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDate(milestone.date),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.accent,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (onFavorite != null)
                            IconButton(
                              onPressed: onFavorite,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                milestone.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 22,
                                color: milestone.isFavorite
                                    ? const Color(0xFFFBBF24)
                                    : theme.accent.withAlpha(90),
                              ),
                            ),
                          if (onEdit != null ||
                              onDelete != null ||
                              onShare != null)
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  size: 18, color: Colors.grey.shade400),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                              itemBuilder: (_) => [
                                if (onShare != null)
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Row(children: [
                                      Icon(Icons.share_outlined,
                                          size: 18,
                                          color: Color(0xFF5B9BD5)),
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
                                      Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red)),
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
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13.5,
                              height: 1.55),
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
                                    padding: const EdgeInsets.only(
                                        top: 4, left: 2),
                                    child: Text(
                                      a.label!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
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
                          runSpacing: 5,
                          children: milestone.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.accent.withAlpha(15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: theme.accent.withAlpha(50),
                                          width: 0.8),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme.accent,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
