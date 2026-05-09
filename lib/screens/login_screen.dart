import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Stack(
        children: [
          // Soft background blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE4C8),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD6E8),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6EEFF).withAlpha(180),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Icon + floating emojis
                    SizedBox(
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFB347).withAlpha(40),
                            ),
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFB347), Color(0xFFFF8C00)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x60FFB347),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.child_care_rounded,
                                size: 48, color: Colors.white),
                          ),
                          // Floating emojis
                          const Positioned(top: 4, right: 16, child: Text('🌸', style: TextStyle(fontSize: 22))),
                          const Positioned(bottom: 8, left: 14, child: Text('⭐', style: TextStyle(fontSize: 18))),
                          const Positioned(top: 16, left: 4, child: Text('🚀', style: TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App name
                    const Text(
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

                    const Spacer(flex: 3),

                    // Feature pills — two rows
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeaturePill(icon: Icons.photo_library_outlined, label: 'Photos & Videos'),
                        _FeaturePill(icon: Icons.mic_outlined, label: 'Voice Memos'),
                        _FeaturePill(icon: Icons.cloud_done_outlined, label: 'Auto Backup'),
                        _FeaturePill(icon: Icons.timeline_outlined, label: 'Timeline'),
                        _FeaturePill(icon: Icons.star_outline_rounded, label: 'Favourites'),
                        _FeaturePill(icon: Icons.link_outlined, label: 'Saved Links'),
                        _FeaturePill(icon: Icons.folder_outlined, label: 'Documents'),
                        _FeaturePill(icon: Icons.notifications_outlined, label: 'Reminders'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sign-in button
                    _GoogleSignInButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Your memories are backed up securely to Google Drive',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Colors.grey.shade200),
          elevation: 2,
          shadowColor: Colors.black.withAlpha(20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFB347),
                  strokeWidth: 2.5,
                ),
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

    canvas.drawArc(rect, -2.36, 2.09, false, redPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, -0.27, 1.57, false, bluePaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, 1.3, 1.57, false, greenPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);
    canvas.drawArc(rect, 2.87, 0.8, false, yellowPaint..strokeWidth = r * 0.36..style = PaintingStyle.stroke);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.36
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx, center.dy), Offset(center.dx + r, center.dy), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
