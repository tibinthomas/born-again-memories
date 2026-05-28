import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cdc_milestones.dart';
import '../providers/profiles_provider.dart';
import '../utils/profile_theme.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class DevChecklistScreen extends ConsumerStatefulWidget {
  final int profileIndex;
  const DevChecklistScreen({super.key, required this.profileIndex});

  @override
  ConsumerState<DevChecklistScreen> createState() => _DevChecklistScreenState();
}

class _DevChecklistScreenState extends ConsumerState<DevChecklistScreen> {
  // Which age groups are expanded
  late Set<int> _expanded;

  @override
  void initState() {
    super.initState();
    final profiles = ref.read(profilesProvider) ?? [];
    if (widget.profileIndex < profiles.length) {
      final dob = profiles[widget.profileIndex].dateOfBirth;
      final current = currentAgeGroup(dob);
      _expanded = current != null ? {current} : {cdcAgeGroups.first};
    } else {
      _expanded = {cdcAgeGroups.first};
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (widget.profileIndex >= profiles.length) return const SizedBox.shrink();

    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final checked = profile.checkedMilestones;
    final totalAll = cdcMilestones.length;
    final checkedAll = cdcMilestones.where((m) => checked.contains(m.id)).length;
    final ageMonths = DateTime.now().difference(profile.dateOfBirth).inDays ~/ 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: const Color(0xFF1A1A2E),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile.nickname ?? profile.name}\'s Milestones',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'CDC developmental checklist',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Overall progress bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _OverallProgress(
                checked: checkedAll,
                total: totalAll,
                accent: theme.accent,
              ),
            ),

            // ── Age group list ────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: cdcAgeGroups.length,
                itemBuilder: (context, i) {
                  final age = cdcAgeGroups[i];
                  final isExpanded = _expanded.contains(age);
                  final isCurrent = ageMonths >= age &&
                      (i == cdcAgeGroups.length - 1 ||
                          ageMonths < cdcAgeGroups[i + 1]);
                  final isPast = i < cdcAgeGroups.length - 1 &&
                      ageMonths >= cdcAgeGroups[i + 1];
                  final isFuture = ageMonths < age;

                  final groupItems = cdcMilestones
                      .where((m) => m.ageMonths == age)
                      .toList();
                  final ignored = profile.ignoredMilestones;
                  final groupChecked =
                      groupItems.where((m) => checked.contains(m.id)).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AgeGroupCard(
                      age: age,
                      milestones: groupItems,
                      checkedIds: checked,
                      ignoredIds: ignored,
                      isExpanded: isExpanded,
                      isCurrent: isCurrent,
                      isPast: isPast,
                      isFuture: isFuture,
                      groupChecked: groupChecked,
                      accent: theme.accent,
                      onToggleExpand: () => setState(() {
                        if (isExpanded) {
                          _expanded.remove(age);
                        } else {
                          _expanded.add(age);
                        }
                      }),
                      onToggle: (id) => ref
                          .read(profilesProvider.notifier)
                          .toggleDevMilestone(widget.profileIndex, id),
                      onIgnore: (id) => ref
                          .read(profilesProvider.notifier)
                          .ignoreDevMilestone(widget.profileIndex, id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overall progress card ─────────────────────────────────────────────────────

class _OverallProgress extends StatelessWidget {
  final int checked;
  final int total;
  final Color accent;
  const _OverallProgress(
      {required this.checked, required this.total, required this.accent});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : checked / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$checked of $total milestones',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, accent, 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any milestone below to mark it as achieved.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Age group card ────────────────────────────────────────────────────────────

class _AgeGroupCard extends StatelessWidget {
  final int age;
  final List<DevMilestone> milestones;
  final Set<String> checkedIds;
  final Set<String> ignoredIds;
  final bool isExpanded;
  final bool isCurrent;
  final bool isPast;
  final bool isFuture;
  final int groupChecked;
  final Color accent;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onIgnore;

  const _AgeGroupCard({
    required this.age,
    required this.milestones,
    required this.checkedIds,
    required this.ignoredIds,
    required this.isExpanded,
    required this.isCurrent,
    required this.isPast,
    required this.isFuture,
    required this.groupChecked,
    required this.accent,
    required this.onToggleExpand,
    required this.onToggle,
    required this.onIgnore,
  });

  Color get _headerColor {
    if (isCurrent) return accent;
    if (isPast) return Colors.green.shade400;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isAllDone = groupChecked == milestones.length;
    final headerColor = _headerColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: accent.withAlpha(80), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ─────────────────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAllDone
                          ? Colors.green.shade400
                          : isCurrent
                              ? accent
                              : isFuture
                                  ? Colors.grey.shade300
                                  : Colors.orange.shade300,
                    ),
                  ),
                  // Age label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cdcAgeLabel(age),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isFuture
                                    ? Colors.grey.shade400
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accent),
                                ),
                              ),
                            if (isAllDone && !isFuture)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'All done ✓',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$groupChecked / ${milestones.length} achieved',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  // Progress mini arc + chevron
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: milestones.isEmpty
                              ? 0
                              : groupChecked / milestones.length,
                          strokeWidth: 3,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(headerColor),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded milestones ────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: isExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade100),
                      ...DevDomain.values.map((domain) {
                        final items = milestones
                            .where((m) => m.domain == domain)
                            .toList();
                        if (items.isEmpty) return const SizedBox.shrink();
                        return _DomainSection(
                          domain: domain,
                          items: items,
                          checkedIds: checkedIds,
                          ignoredIds: ignoredIds,
                          accent: accent,
                          isFuture: isFuture,
                          onToggle: onToggle,
                          onIgnore: onIgnore,
                        );
                      }),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Domain section ────────────────────────────────────────────────────────────

class _DomainSection extends StatelessWidget {
  final DevDomain domain;
  final List<DevMilestone> items;
  final Set<String> checkedIds;
  final Set<String> ignoredIds;
  final Color accent;
  final bool isFuture;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onIgnore;

  const _DomainSection({
    required this.domain,
    required this.items,
    required this.checkedIds,
    required this.ignoredIds,
    required this.accent,
    required this.isFuture,
    required this.onToggle,
    required this.onIgnore,
  });

  Color get _domainColor => switch (domain) {
        DevDomain.social => const Color(0xFFE67E22),
        DevDomain.language => const Color(0xFF2980B9),
        DevDomain.cognitive => const Color(0xFF8E44AD),
        DevDomain.motor => const Color(0xFF27AE60),
      };

  @override
  Widget build(BuildContext context) {
    final color = _domainColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Domain label
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              Text(domain.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                domain.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        // Milestone rows
        ...items.map((m) {
          final isChecked = checkedIds.contains(m.id);
          final isIgnored = ignoredIds.contains(m.id);
          // Dim future items but keep them tappable — parents observe early
          final textColor = isChecked || isIgnored
              ? Colors.grey.shade400
              : isFuture
                  ? Colors.grey.shade400
                  : const Color(0xFF1A1A2E);

          return InkWell(
            onTap: () => onToggle(m.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Checkbox circle ──────────────────────────────
                  GestureDetector(
                    onTap: () => onToggle(m.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChecked
                            ? color
                            : isIgnored
                                ? Colors.grey.shade200
                                : Colors.transparent,
                        border: Border.all(
                          color: isChecked
                              ? color
                              : isIgnored
                                  ? Colors.grey.shade300
                                  : isFuture
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : isIgnored
                              ? Icon(Icons.remove_rounded,
                                  size: 14, color: Colors.grey.shade400)
                              : null,
                    ),
                  ),

                  // ── Title ────────────────────────────────────────
                  Expanded(
                    child: Text(
                      m.title,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: textColor,
                        decoration: isChecked || isIgnored
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  // ── Ignore / Undo button ─────────────────────────
                  if (!isChecked)
                    GestureDetector(
                      onTap: () => onIgnore(m.id),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isIgnored
                                ? Colors.orange.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isIgnored
                                  ? Colors.orange.shade200
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            isIgnored ? 'Undo' : 'Ignore',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isIgnored
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}
