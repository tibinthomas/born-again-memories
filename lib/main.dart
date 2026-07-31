import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
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
import 'utils/wcag_colors.dart';

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
    final authIdentity = authState.valueOrNull?.uid ?? 'signed-out';

    return MaterialApp(
      // Recreate the root Navigator when the signed-in identity changes. This
      // prevents authenticated or login routes from a previous session from
      // remaining above the new auth-controlled home screen.
      key: ValueKey('app-$authIdentity'),
      debugShowCheckedModeBanner: false,
      title: 'First Moments',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      localeResolutionCallback: (locale, _) => locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: settings.themeColor)
            .copyWith(
              onSurface: WcagColors.primaryText,
              onSurfaceVariant: WcagColors.secondaryText,
              outline: WcagColors.controlBorder,
            ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.grey.shade900,
          displayColor: Colors.grey.shade900,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          hintStyle: const TextStyle(color: WcagColors.secondaryText),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: WcagColors.controlBorder),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: WcagColors.focusIndicator, width: 2),
          ),
        ),
        dialogTheme: const DialogThemeData(
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
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
        uid,
        unread.map((d) => d.id).toList(),
      );
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

    final deletedAt = DateTime.fromMillisecondsSinceEpoch(
      (deletedAtMs as num).toInt(),
    );
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

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Center(
        child: SizedBox.square(
          dimension: 180,
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
