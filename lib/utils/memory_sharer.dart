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
/// The card is captured as a PNG and shared via the OS share dialog.
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

class _ShareSheetState extends State<_ShareSheet> {
  bool _sharing = false;

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
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Share this memory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 18),

            // ── Card preview ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RepaintBoundary(
                key: widget.cardKey,
                child: MemoryShareCard(
                  milestone: widget.milestone,
                  babyName: widget.babyName,
                  gender: widget.gender,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Sharing buttons ───────────────────────────
            if (_sharing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareBtn(
                      label: 'WhatsApp',
                      icon: Icons.chat_rounded,
                      color: const Color(0xFF25D366),
                      onTap: _share,
                    ),
                    _ShareBtn(
                      label: 'Instagram',
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFFE1306C),
                      onTap: _share,
                    ),
                    _ShareBtn(
                      label: 'More',
                      icon: Icons.share_rounded,
                      color: theme.accent,
                      onTap: _share,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Share channel button ──────────────────────────────────────────────────────

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShareBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(70), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
