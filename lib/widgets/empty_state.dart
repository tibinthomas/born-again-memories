import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final ThemeData theme;

  const EmptyState({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 82,
            color: theme.colorScheme.primary.withAlpha(77),
          ),
          const SizedBox(height: 18),
          const Text(
            'No milestones yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to capture your baby's first moments.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
