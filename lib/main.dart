import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        data: (user) => user != null ? const AppShell() : const LoginScreen(),
        loading: () => const _SplashScreen(),
        error: (err, stack) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
