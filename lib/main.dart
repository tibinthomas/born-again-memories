import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/milestone_home_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(const ProviderScope(child: BabyMilestonesApp()));
}

class BabyMilestonesApp extends ConsumerWidget {
  const BabyMilestonesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Born Again Memories',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: settings.themeColor),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.grey.shade900,
              displayColor: Colors.grey.shade900,
            ),
      ),
      home: authState.when(
        data: (user) => user != null ? const MilestoneHomePage() : const LoginScreen(),
        loading: () => const _SplashScreen(),
        error: (err, stack) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  static const _particles = ['⭐', '🌸', '💫', '🎀', '✨', '🌙', '💕', '🍼'];

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _logoScale = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F0),
              Color(0xFFFFF0F5),
              Color(0xFFE8F4FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              top: -60,
              left: -60,
              child: _Blob(size: 200, color: const Color(0xFFFFE4C8)),
            ),
            Positioned(
              top: size.height * 0.3,
              right: -80,
              child: _Blob(size: 180, color: const Color(0xFFFFD6E8)),
            ),
            Positioned(
              bottom: -80,
              left: size.width * 0.2,
              child: _Blob(size: 220, color: const Color(0xFFD6EEFF)),
            ),
            // Floating particles
            for (int i = 0; i < _particles.length; i++)
              _FloatingParticle(
                emoji: _particles[i],
                floatCtrl: _floatCtrl,
                left: (size.width * ((i * 0.137 + 0.05) % 1.0)),
                top: size.height * ((i * 0.173 + 0.08) % 0.85),
                phaseOffset: i * 0.13,
              ),
            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo circle
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB347).withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFB347).withOpacity(0.15),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('👶', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'Born Again Memories',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4A3728),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Every moment, treasured forever',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF4A3728).withOpacity(0.6),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _FloatingParticle extends StatelessWidget {
  final String emoji;
  final AnimationController floatCtrl;
  final double left;
  final double top;
  final double phaseOffset;

  const _FloatingParticle({
    required this.emoji,
    required this.floatCtrl,
    required this.left,
    required this.top,
    required this.phaseOffset,
  });

  @override
  Widget build(BuildContext context) {
    final offset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -18),
    ).animate(
      CurvedAnimation(
        parent: floatCtrl,
        curve: Interval(
          (phaseOffset % 1.0),
          ((phaseOffset + 0.5) % 1.0).clamp(0.01, 1.0),
          curve: Curves.easeInOut,
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: floatCtrl,
        builder: (_, __) => Transform.translate(
          offset: offset.value,
          child: Opacity(
            opacity: 0.55,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
