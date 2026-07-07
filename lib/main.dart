import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:math' show pi, sin;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/account_recovery_screen.dart';
import 'screens/login_screen.dart';
import 'screens/milestone_home_page.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

// Top-level handler required by firebase_messaging for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  unawaited(NotificationService.initialize());
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
      title: 'M 4 Memories',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      localeResolutionCallback: (locale, _) => locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: settings.themeColor),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.grey.shade900,
              displayColor: Colors.grey.shade900,
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        dialogTheme: const DialogThemeData(
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      ),
      home: authState.when(
        data: (user) =>
            user != null ? const _AuthedRoot() : const LoginScreen(),
        loading: () => const _AppLoadingScreen(),
        error: (err, stack) => const LoginScreen(),
      ),
    );
  }
}

class _AuthedRoot extends ConsumerStatefulWidget {
  const _AuthedRoot();

  @override
  ConsumerState<_AuthedRoot> createState() => _AuthedRootState();
}

class _AuthedRootState extends ConsumerState<_AuthedRoot> {
  bool _checked = false;
  bool _pendingDeletion = false;
  DateTime? _scheduledDeletion;
  bool _deleteDriveBackup = false;
  StreamSubscription<QuerySnapshot>? _notifSub;

  @override
  void initState() {
    super.initState();
    _checkDeletion();
    _initFcm();
    _listenForSharedNotifications();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _listenForSharedNotifications() {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null || uid.isEmpty) return;
    _notifSub = FirestoreService.streamNotifications(uid).listen((snap) async {
      final unread = snap.docs.where((d) => d.data()['read'] == false).toList();
      if (unread.isEmpty) return;
      for (final doc in unread) {
        final data = doc.data();
        await NotificationService.showSharedMilestoneNotification(
          senderName: data['senderName'] as String? ?? 'Someone',
          milestoneTitle: data['milestoneTitle'] as String? ?? 'a new memory',
        );
      }
      await FirestoreService.markNotificationsRead(
          uid, unread.map((d) => d.id).toList());
    });
  }

  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    final uid = ref.read(authStateProvider).value?.uid;
    if (token != null && uid != null && uid.isNotEmpty) {
      await FirestoreService.saveFcmToken(uid, token);
    }
    // Refresh token whenever it rotates (e.g. after reinstall).
    messaging.onTokenRefresh.listen((newToken) {
      final currentUid = ref.read(authStateProvider).value?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        FirestoreService.saveFcmToken(currentUid, newToken);
      }
    });
  }

  Future<void> _checkDeletion() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) setState(() => _checked = true);
      return;
    }

    final doc = await FirestoreService.getUserDoc(uid);
    if (!mounted) return;

    final deletedAtMs = doc?['deletedAt'];
    if (deletedAtMs == null) {
      setState(() => _checked = true);
      return;
    }

    final deletedAt =
        DateTime.fromMillisecondsSinceEpoch((deletedAtMs as num).toInt());
    if (DateTime.now().difference(deletedAt).inDays >= 28) {
      try {
        await ref.read(authServiceProvider).permanentlyDelete();
      } catch (_) {
        // Deletion failed (e.g. requires-recent-login). Fall through so the
        // recovery screen is shown — the user can sign in and retry from there.
      }
      if (mounted) setState(() => _checked = true);
      return;
    }

    setState(() {
      _checked = true;
      _pendingDeletion = true;
      _scheduledDeletion = deletedAt.add(const Duration(days: 28));
      _deleteDriveBackup = doc?['deleteDriveBackup'] as bool? ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const _AppLoadingScreen();
    }
    if (_pendingDeletion) {
      return AccountRecoveryScreen(
        scheduledDeletion: _scheduledDeletion!,
        deleteDriveBackup: _deleteDriveBackup,
      );
    }
    return const MilestoneHomePage();
  }
}

// ── Shared loading / splash screen ────────────────────────────────────────────

class _AppLoadingScreen extends StatefulWidget {
  const _AppLoadingScreen();

  @override
  State<_AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<_AppLoadingScreen>
    with TickerProviderStateMixin {
  // One long-running controller drives all bubbles (Lissajous paths)
  late final AnimationController _bubbleCtrl;

  // Bubble specs: (size, startX-fraction, startY-fraction, color)
  static const _bubbles = [
    (110.0, -0.08, 0.04, Color(0xFFFFD6A5)),  // top-left peach
    (70.0,   0.02, 0.38, Color(0xFFFFB3C6)),  // mid-left pink
    (90.0,   0.82, 0.10, Color(0xFFB5D8FF)),  // top-right blue
    (55.0,   0.72, 0.55, Color(0xFFFFD6E8)),  // mid-right blush
    (80.0,   0.30, 0.80, Color(0xFFD6EEFF)),  // bottom-center blue
    (40.0,   0.55, 0.20, Color(0xFFFFF0A0)),  // upper-mid yellow
    (60.0,   0.15, 0.65, Color(0xFFFFE4C8)),  // lower-left peach
    (35.0,   0.88, 0.78, Color(0xFFCBF0D9)),  // bottom-right mint
  ];

  @override
  void initState() {
    super.initState();
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 22000),
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F0),
              Color(0xFFFFF0F5),
              Color(0xFFEEF6FF),
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Lissajous bubbles ────────────────────────────────────
            for (final b in _bubbles)
              _SplashBubble(
                ctrl: _bubbleCtrl,
                diameter: b.$1,
                color: b.$4,
                originX: size.width * b.$2,
                originY: size.height * b.$3,
              ),

            // ── Icon + text (static, centred) ────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB347).withAlpha(90),
                          blurRadius: 48,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFB347).withAlpha(40),
                          blurRadius: 90,
                          spreadRadius: 24,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('👶', style: TextStyle(fontSize: 62)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // App name
                  const Text(
                    'M 4 Memories',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A3728),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  Text(
                    'Every moment, treasured forever',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF4A3728).withAlpha(150),
                      letterSpacing: 0.3,
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

// ── Single Lissajous bubble ───────────────────────────────────────────────────

class _SplashBubble extends StatelessWidget {
  final AnimationController ctrl;
  final double diameter;
  final Color color;
  final double originX;
  final double originY;

  const _SplashBubble({
    required this.ctrl,
    required this.diameter,
    required this.color,
    required this.originX,
    required this.originY,
  });

  @override
  Widget build(BuildContext context) {
    // Unique phase per bubble so each follows a different path
    final phase = (diameter * 37 % 100) / 100.0 * 2 * pi;

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) {
        final t = ctrl.value * 2 * pi;
        final dx = sin(t + phase) * 55.0;
        final dy = sin(t * 1.37 + phase) * 38.0;
        final scale = 0.88 + sin(t * 0.7 + phase) * 0.12;
        return Positioned(
          left: originX + dx,
          top: originY + dy,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(180),
              ),
            ),
          ),
        );
      },
    );
  }
}
