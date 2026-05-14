import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../utils/profile_theme.dart';

// ── Title header bubble layer ─────────────────────────────────────────────────

class TitleBubbleLayer extends StatefulWidget {
  final Color accent;
  final Color secondary;
  final String seed;
  const TitleBubbleLayer(
      {super.key, required this.accent, required this.secondary, required this.seed});

  @override
  State<TitleBubbleLayer> createState() => _TitleBubbleLayerState();
}

class _TitleBubbleLayerState extends State<TitleBubbleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.seed.hashCode ^ 0xABCD);
    _phases = List.generate(5, (_) => rng.nextDouble() * 2 * math.pi);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = _ctrl.value * 2 * math.pi;
            double s(double v) => math.sin(v);
            double c(double v) => math.cos(v);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Large accent blob — drifts right-to-left near top
                Positioned(
                  right: -30 + s(t + _phases[0]) * 18,
                  top: -20 + c(t * 0.7 + _phases[0]) * 10,
                  child: DetailBubble(90, widget.accent, 28),
                ),
                // Medium secondary — bottom-left drift
                Positioned(
                  left: -20 + c(t * 0.8 + _phases[1]) * 14,
                  bottom: -18 + s(t + _phases[1]) * 8,
                  child: DetailBubble(64, widget.secondary, 22),
                ),
                // Small accent — gentle mid-right float
                Positioned(
                  right: w * 0.28 + s(t * 1.2 + _phases[2]) * 12,
                  top: h * 0.1 + c(t * 0.9 + _phases[2]) * 10,
                  child: DetailBubble(28, widget.accent, 30),
                ),
                // Tiny secondary — near drag handle
                Positioned(
                  left: w * 0.55 + c(t * 1.3 + _phases[3]) * 10,
                  top: 6 + s(t + _phases[3]) * 6,
                  child: DetailBubble(16, widget.secondary, 35),
                ),
                // Tiny accent — bottom centre
                Positioned(
                  left: w * 0.42 + s(t * 1.1 + _phases[4]) * 14,
                  bottom: 4 + c(t * 0.8 + _phases[4]) * 6,
                  child: DetailBubble(20, widget.accent, 25),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Animated bubble layer ─────────────────────────────────────────────────────

class BubbleLayer extends StatefulWidget {
  final ProfileTheme pTheme;
  final String seed;
  const BubbleLayer({super.key, required this.pTheme, required this.seed});

  @override
  State<BubbleLayer> createState() => _BubbleLayerState();
}

class _BubbleLayerState extends State<BubbleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<double> _phases;
  late final List<double> _amps;
  late final List<double> _signs;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.seed.hashCode);
    _phases = List.generate(6, (_) => rng.nextDouble() * 2 * math.pi);
    _amps   = List.generate(6, (_) => 0.7 + rng.nextDouble() * 0.6);
    _signs  = List.generate(6, (_) => rng.nextBool() ? 1.0 : -1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.pTheme.accent;
    final secondary = widget.pTheme.secondary;
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = _ctrl.value * 2 * math.pi;
            double s(double v) => math.sin(v);
            double c(double v) => math.cos(v);
            return Stack(
              fit: StackFit.expand,
              children: [
                // Large accent — horizontal sweep near top
                Positioned(
                  left: (s(t + _phases[0]) * 0.5 + 0.5) * (w + 130) - 65,
                  top: h * 0.04 + s(t * 2 + _phases[0]) * h * 0.05 * _amps[0],
                  child: DetailBubble(130, accent, 32),
                ),
                // Large secondary — opposite sweep near bottom
                Positioned(
                  left: (c(_signs[1] * t + _phases[1]) * 0.5 + 0.5) * (w + 100) - 50,
                  top: h * 0.68 + s(t * 3 + _phases[1]) * h * 0.05 * _amps[1],
                  child: DetailBubble(100, secondary, 28),
                ),
                // Mid secondary — diagonal figure-8
                Positioned(
                  left: (s(_signs[2] * t * 2 + _phases[2]) * 0.5 + 0.5) * w,
                  top: (c(t * 2 + _phases[2]) * 0.5 + 0.5) * h,
                  child: DetailBubble(55, secondary, 24),
                ),
                // Medium accent — wide circular orbit
                Positioned(
                  left: w * 0.5 + c(_signs[3] * t + _phases[3]) * w * 0.44 * _amps[3],
                  top: h * 0.38 + s(t + _phases[3]) * h * 0.32 * _amps[3],
                  child: DetailBubble(75, accent, 22),
                ),
                // Small accent — fast small orbit
                Positioned(
                  left: w * 0.3 + c(_signs[4] * t * 3 + _phases[4]) * w * 0.22 * _amps[4],
                  top: h * 0.22 + s(t * 3 + _phases[4]) * h * 0.16 * _amps[4],
                  child: DetailBubble(32, accent, 20),
                ),
                // Tiny secondary — bottom sweep
                Positioned(
                  left: (s(t * 2 + _phases[5]) * 0.5 + 0.5) * w * 0.75,
                  top: h * 0.82 + s(t * 3 + _phases[5]) * h * 0.06 * _amps[5],
                  child: DetailBubble(46, secondary, 18),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DetailBubble extends StatelessWidget {
  final double size;
  final Color color;
  final int alpha;
  const DetailBubble(this.size, this.color, this.alpha, {super.key});

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
