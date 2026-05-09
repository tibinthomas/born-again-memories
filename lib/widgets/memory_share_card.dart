import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';

/// Branded card rendered to an image for social sharing.
class MemoryShareCard extends StatelessWidget {
  final Milestone milestone;
  final String babyName;
  final Gender gender;

  const MemoryShareCard({
    super.key,
    required this.milestone,
    required this.babyName,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ProfileTheme.forGender(gender);

    final photo = milestone.attachments
        .where((a) =>
            a.type == AttachmentType.image &&
            !kIsWeb &&
            File(a.localPath).existsSync())
        .firstOrNull;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(gradient: theme.headerGradient),
            child: Row(
              children: [
                Text(theme.decalEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Born Again Memories',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                ...List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(70 + i * 60),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Photo ──────────────────────────────────────────────────────
          if (photo != null)
            SizedBox(
              height: 190,
              child: Image.file(
                File(photo.localPath),
                fit: BoxFit.cover,
              ),
            ),

          // ── Body ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.child_care, size: 13, color: theme.accent),
                    const SizedBox(width: 5),
                    Text(
                      '$babyName · ${formatDate(milestone.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (milestone.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    milestone.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.55,
                    ),
                  ),
                ],
                if (milestone.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: milestone.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.soft,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            color: theme.soft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_rounded, size: 11, color: theme.accent),
                const SizedBox(width: 5),
                Text(
                  '#BornAgainMemories',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
