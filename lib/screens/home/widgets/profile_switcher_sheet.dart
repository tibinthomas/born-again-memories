import 'package:flutter/material.dart';
import '../../../models/kid_profile.dart';
import '../../../utils/profile_theme.dart';

class ProfileSwitcherSheet extends StatelessWidget {
  final List<KidProfile> profiles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddProfile;

  const ProfileSwitcherSheet({
    super.key,
    required this.profiles,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Row(
            children: [
              const Text('Switch profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddProfile,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...profiles.asMap().entries.map((e) {
            final i = e.key;
            final profile = e.value;
            final pTheme = ProfileTheme.forProfile(profile);
            final isSelected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? pTheme.soft : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? pTheme.accent : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: pTheme.accent.withAlpha(40), blurRadius: 10)]
                        : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? pTheme.accent : pTheme.soft,
                        ),
                        child: Center(
                          child: Text(pTheme.decalEmoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.nickname ?? profile.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? pTheme.accent : const Color(0xFF2D2D2D),
                                )),
                            if (profile.nickname != null && profile.nickname!.isNotEmpty)
                              Text(profile.name,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade500)),
                            Text(profile.ageText,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: pTheme.accent, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
