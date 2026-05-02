import 'package:flutter/material.dart';
import 'screens/milestone_home_page.dart';

void main() {
  runApp(const BabyMilestonesApp());
}

class BabyMilestonesApp extends StatelessWidget {
  const BabyMilestonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baby Milestones',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.grey.shade900,
              displayColor: Colors.grey.shade900,
            ),
      ),
      home: const MilestoneHomePage(),
    );
  }
}
