import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/profile_theme.dart';
import '../widgets/memory_share_card.dart';

/// Shows a share sheet with a branded memory card preview.
class MemorySharer {
  static final GlobalKey _key = GlobalKey();

  static Future<void> show(
    BuildContext context,
    Milestone milestone,
    String babyName,
    Gender gender,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        milestone: milestone,
        babyName: babyName,
        gender: gender,
        cardKey: _key,
      ),
    );
  }
}

// ── Share sheet ───────────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final Milestone milestone;
  final String babyName;
  final Gender gender;
  final GlobalKey cardKey;

  const _ShareSheet({
    required this.milestone,
    required this.babyName,
    required this.gender,
    required this.cardKey,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet>
    with SingleTickerProviderStateMixin {
  bool _sharing = false;
  late final AnimationController _pulse;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<String?> _captureCard() async {
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary = widget.cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/memory_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final path = await _captureCard();
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not create share image')),
          );
        }
        return;
      }
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'image/png')],
          text: '#BornAgainMemories',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ProfileTheme.forGender(widget.gender);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        // Subtle gradient tinted with the profile accent
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.soft,
            Colors.white,
            theme.cardBg,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.accent.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: theme.headerGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share this memory',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Your moment, beautifully packaged',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Card preview with subtle float animation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: RepaintBoundary(
                key: widget.cardKey,
                child: MemoryShareCard(
                  milestone: widget.milestone,
                  babyName: widget.babyName,
                  gender: widget.gender,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider with label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Expanded(
                  child: Divider(color: theme.accent.withAlpha(40), height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Share via',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.accent.withAlpha(160),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: theme.accent.withAlpha(40), height: 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Share buttons
          if (_sharing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.accent,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareBtn(
                    label: 'WhatsApp',
                    emoji: '💬',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _share,
                  ),
                  _ShareBtn(
                    label: 'Instagram',
                    emoji: '📸',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF58529), Color(0xFFE1306C), Color(0xFF833AB4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _share,
                  ),
                  _ShareBtn(
                    label: 'Save',
                    emoji: '💾',
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accent.withAlpha(180)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _share,
                  ),
                  _ShareBtn(
                    label: 'More',
                    emoji: '🔗',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C6C6C),
                        const Color(0xFF3C3C3C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: _share,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Hint text
          Text(
            'Tap any option to share your memory card',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 16,
          ),
        ],
      ),
    );
  }
}

// ── Share button ──────────────────────────────────────────────────────────────

class _ShareBtn extends StatefulWidget {
  final String label;
  final String emoji;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ShareBtn({
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ShareBtn> createState() => _ShareBtnState();
}

class _ShareBtnState extends State<_ShareBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient as LinearGradient)
                        .colors
                        .first
                        .withAlpha(80),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
