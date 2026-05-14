import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'settings_card.dart';

class AccountCard extends StatelessWidget {
  final Color accent;
  final Color secondary;
  final VoidCallback onSignOut;

  const AccountCard({
    super.key,
    required this.accent,
    required this.secondary,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SettingsCard(children: [
      // Gradient top strip
      Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, secondary]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              backgroundColor: Color.lerp(Colors.white, accent, 0.15),
              child: user?.photoURL == null
                  ? Icon(Icons.person_rounded, color: accent, size: 26)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
