import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/date_formatter.dart';
import '../utils/device_performance.dart';
import '../utils/profile_theme.dart';

class MilestoneCard extends StatefulWidget {
  final Milestone milestone;
  final ProfileTheme? profileTheme;
  final int animIndex;
  final bool animationsEnabled;
  final DateTime? dateOfBirth;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.profileTheme,
    this.animIndex = 0,
    this.animationsEnabled = true,
    this.dateOfBirth,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onFavorite,
  });

  @override
  State<MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<MilestoneCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );
    _scale = Tween(begin: 0.92, end: 1.0).animate(curved);
    _slide = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(curved);

    final delay = (widget.animIndex * 60).clamp(0, 320);
    if (delay == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.profileTheme ?? ProfileTheme.forGender(Gender.neutral);
    final milestone = widget.milestone;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.975 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: _CrystalCard(
                milestone: milestone,
                theme: theme,
                animationsEnabled: widget.animationsEnabled,
                dateOfBirth: widget.dateOfBirth,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
                onShare: widget.onShare,
                onFavorite: widget.onFavorite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrystalCard extends StatefulWidget {
  final Milestone milestone;
  final ProfileTheme theme;
  final bool animationsEnabled;
  final DateTime? dateOfBirth;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;

  const _CrystalCard({
    required this.milestone,
    required this.theme,
    this.animationsEnabled = true,
    this.dateOfBirth,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onFavorite,
  });

  @override
  State<_CrystalCard> createState() => _CrystalCardState();
}

class _CrystalCardState extends State<_CrystalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  late final List<double> _phases; // random phase per bubble — loop-safe
  late final List<double> _amps;   // amplitude multipliers
  late final List<double> _signs;  // orbit direction per bubble

  @override
  void initState() {
    super.initState();
    // Stable randomness seeded by milestone id — each card looks unique
    final rng = math.Random(widget.milestone.id.hashCode);
    _phases = List.generate(5, (_) => rng.nextDouble() * 2 * math.pi);
    _amps   = List.generate(5, (_) => 0.75 + rng.nextDouble() * 0.5);
    _signs  = List.generate(5, (_) => rng.nextBool() ? 1.0 : -1.0);

    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.animationsEnabled) _float.repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.theme.accent;
    final secondary = widget.theme.secondary;
    final theme = widget.theme;
    final milestone = widget.milestone;

    // Rich pastel tones anchored to the profile theme
    final bgTL = Color.lerp(Colors.white, accent, 0.45)!;
    final bgBR = Color.lerp(Colors.white, secondary, 0.40)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.42, 1.0],
          colors: [bgTL, Colors.white.withAlpha(245), bgBR],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withAlpha(70),
          width: 1.4,
        ),
        boxShadow: DevicePerformance.isLowEnd
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: accent.withAlpha(60),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: secondary.withAlpha(45),
                  blurRadius: 16,
                  spreadRadius: -4,
                  offset: const Offset(6, 14),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Bubbles moving across the card ────────────────────
            if (!DevicePerformance.isLowEnd)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, box) {
                  final w = box.maxWidth;
                  final h = box.maxHeight;
                  return AnimatedBuilder(
                    animation: _float,
                    builder: (_, __) {
                      final t = _float.value * 2 * math.pi;
                      // Integer multipliers + phase offsets → seamless loop
                      // sin(2π·n + φ) == sin(φ), so no jump at reset.
                      double s(double v) => math.sin(v);
                      double c(double v) => math.cos(v);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Large accent — horizontal sweep near top
                          Positioned(
                            left: (s(t + _phases[0]) * 0.5 + 0.5) * (w + 92) - 46,
                            top: h * 0.04 + s(t * 2 + _phases[0]) * h * 0.07 * _amps[0],
                            child: _CardBubble(92, accent, 50),
                          ),
                          // Large secondary — opposite sweep near bottom
                          Positioned(
                            left: (c(_signs[1] * t + _phases[1]) * 0.5 + 0.5) * (w + 72) - 36,
                            top: h * 0.62 + s(t * 3 + _phases[1]) * h * 0.07 * _amps[1],
                            child: _CardBubble(72, secondary, 44),
                          ),
                          // Small secondary — diagonal figure-8
                          Positioned(
                            left: (s(_signs[2] * t * 2 + _phases[2]) * 0.5 + 0.5) * w,
                            top: (c(t * 2 + _phases[2]) * 0.5 + 0.5) * h,
                            child: _CardBubble(24, secondary, 38),
                          ),
                          // Medium accent — circular orbit
                          Positioned(
                            left: w * 0.5 + c(_signs[3] * t + _phases[3]) * w * 0.44 * _amps[3],
                            top: h * 0.5 + s(t + _phases[3]) * h * 0.40 * _amps[3],
                            child: _CardBubble(38, accent, 30),
                          ),
                          // Tiny accent — small fast orbit
                          Positioned(
                            left: w * 0.35 + c(_signs[4] * t * 3 + _phases[4]) * w * 0.28 * _amps[4],
                            top: h * 0.28 + s(t * 3 + _phases[4]) * h * 0.22 * _amps[4],
                            child: _CardBubble(16, accent, 24),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Shimmer ───────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1.2, -1.0),
                    end: const Alignment(0.6, 1.0),
                    stops: const [0.0, 0.30, 0.62, 1.0],
                    colors: [
                      Colors.white.withAlpha(150),
                      Colors.white.withAlpha(0),
                      Colors.white.withAlpha(90),
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Specular top-edge glint ────────────────────────────
            Positioned(
              top: 0, left: 24, right: 24, height: 1.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withAlpha(200),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon bubble — solid gradient, white icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.accent,
                              Color.lerp(theme.accent, theme.secondary, 0.55)!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withAlpha(80),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome,
                            size: 17, color: Colors.white),
                      ),
                      const SizedBox(width: 11),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.dateOfBirth != null) ...[
                                  Text(
                                    '  ·  ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.accent.withAlpha(120),
                                    ),
                                  ),
                                  Icon(Icons.cake_outlined,
                                      size: 11, color: theme.accent.withAlpha(180)),
                                  const SizedBox(width: 3),
                                  Text(
                                    _preciseAge(widget.dateOfBirth!, milestone.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.onFavorite != null)
                        IconButton(
                          onPressed: widget.onFavorite,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: milestone.isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
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
                      if (widget.onEdit != null || widget.onDelete != null || widget.onShare != null)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              size: 18, color: Colors.grey.shade500),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          itemBuilder: (_) => [
                            if (widget.onShare != null)
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(children: [
                                  Icon(Icons.share_outlined,
                                      size: 18, color: Color(0xFF5B9BD5)),
                                  SizedBox(width: 10),
                                  Text('Share'),
                                ]),
                              ),
                            if (widget.onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ]),
                              ),
                            if (widget.onDelete != null)
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
                            if (v == 'share') widget.onShare?.call();
                            if (v == 'edit') widget.onEdit?.call();
                            if (v == 'delete') widget.onDelete?.call();
                          },
                        ),
                    ],
                  ),

                  if (milestone.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      milestone.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],

                  if (milestone.attachments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MediaCountRow(milestone: milestone, accent: theme.accent),
                  ],

                  if (milestone.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: milestone.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.accent.withAlpha(14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.accent.withAlpha(75),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
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

                  // Spark badge — shown when this memory was created from a spark
                  if (milestone.sparkTitle != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.shade200, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  size: 11, color: Colors.amber.shade700),
                              const SizedBox(width: 3),
                              Text(
                                milestone.sparkTitle!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _MediaCountRow extends StatelessWidget {
  final Milestone milestone;
  final Color accent;
  const _MediaCountRow({required this.milestone, required this.accent});

  @override
  Widget build(BuildContext context) {
    final photos = milestone.attachments.where((a) => a.type == AttachmentType.image).length;
    final videos = milestone.attachments.where((a) => a.type == AttachmentType.video).length;
    final audios = milestone.attachments.where((a) => a.type == AttachmentType.audio).length;

    return Row(
      children: [
        if (photos > 0) _MediaChip(Icons.photo_camera_outlined, photos, accent),
        if (photos > 0 && (videos > 0 || audios > 0)) const SizedBox(width: 6),
        if (videos > 0) _MediaChip(Icons.videocam_outlined, videos, accent),
        if (videos > 0 && audios > 0) const SizedBox(width: 6),
        if (audios > 0) _MediaChip(Icons.mic_outlined, audios, accent),
      ],
    );
  }
}

class _MediaChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color accent;
  const _MediaChip(this.icon, this.count, this.accent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(60), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CardBubble extends StatelessWidget {
  final double size;
  final Color color;
  final int alpha;
  const _CardBubble(this.size, this.color, this.alpha);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(alpha),
      ),
    );
  }
}

String _preciseAge(DateTime birth, DateTime date) {
  int years = date.year - birth.year;
  int months = date.month - birth.month;
  int days = date.day - birth.day;

  if (days < 0) {
    months -= 1;
    days += DateTime(date.year, date.month, 0).day;
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }

  final parts = <String>[];
  if (years > 0) parts.add('${years}y');
  if (months > 0) parts.add('${months}m');
  if (days > 0 || parts.isEmpty) parts.add('${days}d');
  return parts.join(' ');
}
