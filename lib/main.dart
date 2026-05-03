import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_settings_provider.dart';
import 'screens/milestone_home_page.dart';

void main() {
  runApp(const ProviderScope(child: BabyMilestonesApp()));
}

class BabyMilestonesApp extends ConsumerWidget {
  const BabyMilestonesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baby Milestones',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: settings.themeColor),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.grey.shade900,
              displayColor: Colors.grey.shade900,
            ),
      ),
      home: const MilestoneHomePage(),
    );
  }
}
