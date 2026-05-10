import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/milestone.dart';
import '../models/kid_profile.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';
import 'attachment_preview.dart';

class MilestoneCard extends StatefulWidget {
  final Milestone milestone;
  final ProfileTheme? profileTheme;
  final int animIndex;
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onFavorite;

  const _CrystalCard({
    required this.milestone,
    required this.theme,
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

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
        boxShadow: [
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
            // ── Floating parallax bubbles ─────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _float,
                builder: (_, __) {
                  final t = _float.value * 2 * math.pi;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Large top-right — slow drift
                      Positioned(
                        top: -24, right: -24,
                        child: Transform.translate(
                          offset: Offset(math.cos(t * 0.5) * 6, math.sin(t * 0.7) * 10),
                          child: _CardBubble(92, accent, 50),
                        ),
                      ),
                      // Large bottom-left — opposite phase
                      Positioned(
                        bottom: -20, left: -20,
                        child: Transform.translate(
                          offset: Offset(math.cos(t * 0.4 + 1.0) * 5, math.sin(t * 0.6 + math.pi) * 9),
                          child: _CardBubble(72, secondary, 44),
                        ),
                      ),
                      // Mid small — faster
                      Positioned(
                        top: 22, right: 52,
                        child: Transform.translate(
                          offset: Offset(math.cos(t * 0.9 + 0.5) * 5, math.sin(t * 1.1 + 2.0) * 7),
                          child: _CardBubble(24, secondary, 36),
                        ),
                      ),
                      // Bottom-right small
                      Positioned(
                        bottom: 14, right: 8,
                        child: Transform.translate(
                          offset: Offset(math.cos(t * 1.2) * 4, math.sin(t * 0.8 + 1.5) * 6),
                          child: _CardBubble(38, accent, 28),
                        ),
                      ),
                      // Tiny top-centre
                      Positioned(
                        top: 8, left: 58,
                        child: Transform.translate(
                          offset: Offset(math.cos(t * 0.7 + 2.0) * 4, math.sin(t * 1.3 + 0.8) * 5),
                          child: _CardBubble(16, accent, 22),
                        ),
                      ),
                    ],
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
              padding: const EdgeInsets.fromLTRB(20, 14, 10, 16),
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
                        fontSize: 13.5,
                        height: 1.55,
                      ),
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
                ],
              ),
            ),
          ],
        ),
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
