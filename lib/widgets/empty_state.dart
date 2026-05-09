import 'package:flutter/material.dart';
import '../models/kid_profile.dart';
import '../utils/profile_theme.dart';

class EmptyState extends StatelessWidget {
  final ThemeData theme;
  final Gender gender;

  const EmptyState({
    super.key,
    required this.theme,
    this.gender = Gender.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final pTheme = ProfileTheme.forGender(gender);

    final message = switch (gender) {
      Gender.boy => "Tap 'Add' to capture his very first moments.",
      Gender.girl => "Tap 'Add' to capture her very first moments.",
      Gender.neutral => "Tap 'Add' to capture those first precious moments.",
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: pTheme.soft,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: pTheme.accent.withAlpha(50), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(pTheme.decalEmoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No milestones yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
