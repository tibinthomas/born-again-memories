import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;

  // Entrance sequence (plays once)
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;
  late final Animation<double> _pillsFade;
  late final Animation<Offset> _pillsSlide;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  // Continuous logo pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double> _logoPulse;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    CurvedAnimation iv(double b, double e, Curve c) =>
        CurvedAnimation(parent: _entryCtrl, curve: Interval(b, e, curve: c));

    // Logo: elastic pop 0–40%
    _logoScale = iv(0.0, 0.40, Curves.elasticOut);

    // Title: 22–55%
    final titleAnim = iv(0.22, 0.55, Curves.easeOut);
    _titleFade = titleAnim;
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(titleAnim);

    // Tagline: 32–62%
    final tagAnim = iv(0.32, 0.62, Curves.easeOut);
    _tagFade = tagAnim;
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(tagAnim);

    // Feature pills: 44–76%
    final pillsAnim = iv(0.44, 0.76, Curves.easeOut);
    _pillsFade = pillsAnim;
    _pillsSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(pillsAnim);

    // Buttons: 58–92%
    final btnAnim = iv(0.58, 0.92, Curves.easeOut);
    _btnFade = btnAnim;
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(btnAnim);

    // Gentle logo pulse after entrance
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _logoPulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithApple();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Stack(
        children: [
          // ── Animated background blobs ────────────────────────────────────
          _FloatingBlob(
            top: -70, right: -70,
            size: 240,
            color: const Color(0xFFFFE4C8),
            period: const Duration(milliseconds: 5200),
            amplitude: 22,
            phase: 0.0,
          ),
          _FloatingBlob(
            bottom: -90, left: -70,
            size: 280,
            color: const Color(0xFFFFD6E8),
            period: const Duration(milliseconds: 7100),
            amplitude: 28,
            phase: math.pi * 0.7,
          ),
          _FloatingBlob(
            top: 190, left: -50,
            size: 130,
            color: const Color(0xFFD6EEFF).withAlpha(180),
            period: const Duration(milliseconds: 6300),
            amplitude: 16,
            phase: math.pi * 1.3,
          ),
          _FloatingBlob(
            top: 320, right: -30,
            size: 90,
            color: const Color(0xFFFFF0A0).withAlpha(160),
            period: const Duration(milliseconds: 4800),
            amplitude: 12,
            phase: math.pi * 0.4,
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo: elastic entrance + continuous pulse
                  ScaleTransition(
                    scale: _logoScale,
                    child: ScaleTransition(
                      scale: _logoPulse,
                      child: SizedBox(
                        height: 150,
                        width: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer halo
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFB347).withAlpha(25),
                              ),
                            ),
                            // Mid glow
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFB347).withAlpha(45),
                              ),
                            ),
                            // Main disc
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFB347),
                                    Color(0xFFFF8C00),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x65FFB347),
                                    blurRadius: 30,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            // Orbiting emojis
                            _OrbitEmoji(
                              emoji: '🌸',
                              radius: 58,
                              period: const Duration(milliseconds: 5800),
                              startAngle: -math.pi * 0.3,
                            ),
                            _OrbitEmoji(
                              emoji: '⭐',
                              radius: 54,
                              period: const Duration(milliseconds: 8200),
                              startAngle: math.pi * 0.85,
                            ),
                            _OrbitEmoji(
                              emoji: '🚀',
                              radius: 56,
                              period: const Duration(milliseconds: 4600),
                              startAngle: math.pi * 1.55,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // App name
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'Born Again\nMemories',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  SlideTransition(
                    position: _tagSlide,
                    child: FadeTransition(
                      opacity: _tagFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB347).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Capture every precious moment ✨',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFCC8800),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Feature pills — staggered entrance
                  SlideTransition(
                    position: _pillsSlide,
                    child: FadeTransition(
                      opacity: _pillsFade,
                      child: const Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _FeaturePill(
                              icon: Icons.photo_library_outlined,
                              label: 'Photos & Videos'),
                          _FeaturePill(
                              icon: Icons.mic_outlined,
                              label: 'Voice Memos'),
                          _FeaturePill(
                              icon: Icons.cloud_done_outlined,
                              label: 'Auto Backup'),
                          _FeaturePill(
                              icon: Icons.timeline_outlined,
                              label: 'Timeline'),
                          _FeaturePill(
                              icon: Icons.star_outline_rounded,
                              label: 'Favourites'),
                          _FeaturePill(
                              icon: Icons.link_outlined,
                              label: 'Saved Links'),
                          _FeaturePill(
                              icon: Icons.folder_outlined,
                              label: 'Documents'),
                          _FeaturePill(
                              icon: Icons.notifications_outlined,
                              label: 'Reminders'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign-in buttons — last to appear
                  SlideTransition(
                    position: _btnSlide,
                    child: FadeTransition(
                      opacity: _btnFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GoogleSignInButton(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 12),
                          if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...[
                            _AppleSignInButton(
                              onPressed: _isLoading ? null : _signInWithApple,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            !kIsWeb && (Platform.isIOS || Platform.isMacOS)
                                ? 'Back up to Google Drive or iCloud'
                                : 'Your memories are backed up securely to Google Drive',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated floating background blob ────────────────────────────────────────

class _FloatingBlob extends StatefulWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final Duration period;
  final double amplitude;
  final double phase;

  const _FloatingBlob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.period,
    required this.amplitude,
    required this.phase,
  });

  @override
  State<_FloatingBlob> createState() => _FloatingBlobState();
}

class _FloatingBlobState extends State<_FloatingBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value * 2 * math.pi + widget.phase;
        final dy = math.sin(t) * widget.amplitude;
        final dx = math.cos(t * 0.7) * widget.amplitude * 0.45;
        return Positioned(
          top: widget.top != null ? widget.top! + dy : null,
          bottom: widget.bottom != null ? widget.bottom! - dy : null,
          left: widget.left != null ? widget.left! + dx : null,
          right: widget.right != null ? widget.right! - dx : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

// ── Orbiting emoji ────────────────────────────────────────────────────────────

class _OrbitEmoji extends StatefulWidget {
  final String emoji;
  final double radius;
  final Duration period;
  final double startAngle;

  const _OrbitEmoji({
    required this.emoji,
    required this.radius,
    required this.period,
    required this.startAngle,
  });

  @override
  State<_OrbitEmoji> createState() => _OrbitEmojiState();
}

class _OrbitEmojiState extends State<_OrbitEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final angle = _ctrl.value * 2 * math.pi + widget.startAngle;
        final dx = math.cos(angle) * widget.radius;
        final dy = math.sin(angle) * widget.radius * 0.52;
        // Subtle size wobble makes it feel alive
        final size = 16.0 + 4.0 * math.sin(angle * 2 + 1).abs();
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Text(
            widget.emoji,
            style: TextStyle(
              fontSize: size,
              shadows: [
                Shadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 1)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Feature pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFB347)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Apple sign-in button ──────────────────────────────────────────────────────

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.black.withAlpha(70)),
          elevation: 2,
          shadowColor: Colors.black.withAlpha(20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, size: 20, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Apple',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Google sign-in button ─────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.grey.shade200),
          elevation: 2,
          shadowColor: Colors.black.withAlpha(20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Color(0xFFFFB347), strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final r = size.width / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);

    canvas.drawArc(rect, -2.36, 2.09, false,
        redPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, -0.27, 1.57, false,
        bluePaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, 1.3, 1.57, false,
        greenPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, 2.87, 0.8, false,
        yellowPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.36
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(center.dx, center.dy), Offset(center.dx + r, center.dy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
