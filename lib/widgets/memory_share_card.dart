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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withAlpha(60),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null
          ? _PhotoCard(
              milestone: milestone,
              babyName: babyName,
              photo: photo,
              theme: theme,
            )
          : _GradientCard(
              milestone: milestone,
              babyName: babyName,
              theme: theme,
            ),
    );
  }
}

// ── Photo card (when attachment exists) ───────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final Milestone milestone;
  final String babyName;
  final File Function() _photoFile;
  final ProfileTheme theme;

  _PhotoCard({
    required this.milestone,
    required this.babyName,
    required Attachment photo,
    required this.theme,
  }) : _photoFile = (() => File(photo.localPath));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-bleed photo
        SizedBox(
          width: 320,
          height: 420,
          child: Image.file(
            _photoFile(),
            fit: BoxFit.cover,
          ),
        ),

        // Dark gradient overlay (bottom two-thirds)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 1.0],
                colors: [
                  Colors.black.withAlpha(60),
                  Colors.transparent,
                  Colors.black.withAlpha(220),
                ],
              ),
            ),
          ),
        ),

        // Top branding pill
        Positioned(
          top: 16,
          left: 16,
          child: _BrandingPill(theme: theme),
        ),

        // Bottom content
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tags
                if (milestone.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: milestone.tags
                        .take(3)
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.accent.withAlpha(200),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '#$t',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Title
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.3,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Baby name + date
                Row(
                  children: [
                    Text(
                      theme.decalEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$babyName · ${formatDate(milestone.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (milestone.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    milestone.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withAlpha(180),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                _Footer(theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient card (no photo) ──────────────────────────────────────────────────

class _GradientCard extends StatelessWidget {
  final Milestone milestone;
  final String babyName;
  final ProfileTheme theme;

  const _GradientCard({
    required this.milestone,
    required this.babyName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(gradient: theme.headerGradient),
      child: Stack(
        children: [
          // Decorative circles
          ..._decorativeCircles(theme),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandingPill(theme: theme, dark: false),
                const SizedBox(height: 32),

                // Big emoji
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withAlpha(60), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      theme.decalEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 8),

                // Baby + date
                Row(
                  children: [
                    Icon(Icons.child_care,
                        size: 13, color: Colors.white.withAlpha(200)),
                    const SizedBox(width: 5),
                    Text(
                      '$babyName · ${formatDate(milestone.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (milestone.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withAlpha(30), width: 1),
                    ),
                    child: Text(
                      milestone.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(210),
                        height: 1.55,
                      ),
                    ),
                  ),
                ],

                if (milestone.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: milestone.tags
                        .take(4)
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withAlpha(50),
                                    width: 1),
                              ),
                              child: Text(
                                '#$t',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 24),
                _Footer(theme: theme, onGradient: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _decorativeCircles(ProfileTheme theme) {
    final specs = [
      (120.0, -40.0, -40.0, 18),
      (80.0, -20.0, 60.0, 12),
      (60.0, null, -20.0, 14),
      (40.0, null, 40.0, 20),
      (30.0, 80.0, null, 10),
    ];
    return specs.map<Widget>((s) {
      final (size, top, left, alpha) = s;
      return Positioned(
        top: top,
        left: left,
        right: left == null ? -10 : null,
        bottom: top == null ? 60 : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(alpha),
          ),
        ),
      );
    }).toList();
  }
}

// ── Branding pill ─────────────────────────────────────────────────────────────

class _BrandingPill extends StatelessWidget {
  final ProfileTheme theme;
  final bool dark;

  const _BrandingPill({required this.theme, this.dark = true});

  @override
  Widget build(BuildContext context) {
    final bg = dark
        ? Colors.black.withAlpha(100)
        : Colors.white.withAlpha(35);
    final border = dark
        ? Colors.white.withAlpha(40)
        : Colors.white.withAlpha(60);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(theme.decalEmoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            const Text(
              'Born Again Memories',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final ProfileTheme theme;
  final bool onGradient;

  const _Footer({required this.theme, this.onGradient = false});

  @override
  Widget build(BuildContext context) {
    final color = onGradient ? Colors.white.withAlpha(180) : theme.accent;
    final bg = onGradient
        ? Colors.white.withAlpha(20)
        : theme.soft;
    final border = onGradient
        ? Colors.white.withAlpha(30)
        : theme.accent.withAlpha(30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            '#BornAgainMemories',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
