import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cdc_milestones.dart';
import '../models/milestone.dart';
import '../providers/profiles_provider.dart';
import '../utils/app_date_picker.dart';
import '../utils/profile_theme.dart';
import 'home/widgets/add_milestone_sheet.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class DevChecklistScreen extends ConsumerStatefulWidget {
  final int profileIndex;
  const DevChecklistScreen({super.key, required this.profileIndex});

  @override
  ConsumerState<DevChecklistScreen> createState() => _DevChecklistScreenState();
}

class _DevChecklistScreenState extends ConsumerState<DevChecklistScreen> {
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

  // ── Tap handler ────────────────────────────────────────────────────────────

  void _handleTap(DevMilestone m) {
    final profile = (ref.read(profilesProvider) ?? [])[widget.profileIndex];
    final ageMonths =
        DateTime.now().difference(profile.dateOfBirth).inDays ~/ 30;
    if (ageMonths < m.ageMonths) return;

    final isChecked = profile.checkedMilestones.contains(m.id);
    final linkedId = profile.devMilestoneLinks[m.id];

    if (!isChecked) {
      // Not yet achieved — show action sheet
      _showCheckActionSheet(m);
    } else if (linkedId != null) {
      // Checked and has a linked memory — open edit sheet
      _editLinkedMilestone(linkedId);
    } else {
      // Checked but no memory linked — toggle off
      ref.read(profilesProvider.notifier).toggleDevMilestone(widget.profileIndex, m.id);
    }
  }

  void _showCheckActionSheet(DevMilestone m) {
    final theme = ProfileTheme.forProfile(
        (ref.read(profilesProvider) ?? [])[widget.profileIndex]);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        cdcMilestone: m,
        accent: theme.accent,
        onMarkDone: () {
          Navigator.pop(context);
          ref
              .read(profilesProvider.notifier)
              .toggleDevMilestone(widget.profileIndex, m.id);
        },
        onAddMemory: () {
          Navigator.pop(context);
          _showAddMemorySheet(m);
        },
      ),
    );
  }

  void _showAddMemorySheet(DevMilestone m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickMemorySheet(
        profileIndex: widget.profileIndex,
        cdcMilestone: m,
      ),
    );
  }

  void _editLinkedMilestone(String milestoneId) {
    final profile = (ref.read(profilesProvider) ?? [])[widget.profileIndex];
    final milestone =
        profile.milestones.where((m) => m.id == milestoneId).firstOrNull;
    if (milestone == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddMilestoneSheet(initialMilestone: milestone),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (widget.profileIndex >= profiles.length) return const SizedBox.shrink();

    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final checked = profile.checkedMilestones;
    final links = profile.devMilestoneLinks;
    final totalAll = cdcMilestones.length;
    final checkedAll = cdcMilestones.where((m) => checked.contains(m.id)).length;
    final ageMonths = DateTime.now().difference(profile.dateOfBirth).inDays ~/ 30;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    tooltip: 'Back',
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

            // Overall progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _OverallProgress(
                checked: checkedAll,
                total: totalAll,
                linkedCount: links.length,
                accent: theme.accent,
              ),
            ),

            // Age group list
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

                  final groupItems =
                      cdcMilestones.where((m) => m.ageMonths == age).toList();
                  final groupChecked =
                      groupItems.where((m) => checked.contains(m.id)).length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AgeGroupCard(
                      age: age,
                      milestones: groupItems,
                      checkedIds: checked,
                      linkedIds: links.keys.toSet(),
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
                      onTap: _handleTap,
                      onAddMemory: _showAddMemorySheet,
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
  final int linkedCount;
  final Color accent;

  const _OverallProgress({
    required this.checked,
    required this.total,
    required this.linkedCount,
    required this.accent,
  });

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
              if (linkedCount > 0) ...[
                Icon(Icons.photo_camera_outlined,
                    size: 13, color: Colors.teal.shade400),
                const SizedBox(width: 3),
                Text(
                  '$linkedCount memories',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.teal.shade500,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
              ],
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
            'Tap a milestone to mark it achieved or add it as a memory.',
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
  final Set<String> linkedIds;
  final bool isExpanded;
  final bool isCurrent;
  final bool isPast;
  final bool isFuture;
  final int groupChecked;
  final Color accent;
  final VoidCallback onToggleExpand;
  final ValueChanged<DevMilestone> onTap;
  final ValueChanged<DevMilestone> onAddMemory;

  const _AgeGroupCard({
    required this.age,
    required this.milestones,
    required this.checkedIds,
    required this.linkedIds,
    required this.isExpanded,
    required this.isCurrent,
    required this.isPast,
    required this.isFuture,
    required this.groupChecked,
    required this.accent,
    required this.onToggleExpand,
    required this.onTap,
    required this.onAddMemory,
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
          // Header row
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
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
                              _Chip('Current', accent.withAlpha(30), accent),
                            if (isAllDone && !isFuture)
                              _Chip('All done ✓', Colors.green.shade50,
                                  Colors.green.shade600),
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

          // Expanded domain sections
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
                          linkedIds: linkedIds,
                          isFuture: isFuture,
                          accent: accent,
                          onTap: onTap,
                          onAddMemory: onAddMemory,
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

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg)),
      );
}

// ── Domain section ────────────────────────────────────────────────────────────

class _DomainSection extends StatelessWidget {
  final DevDomain domain;
  final List<DevMilestone> items;
  final Set<String> checkedIds;
  final Set<String> linkedIds;
  final bool isFuture;
  final Color accent;
  final ValueChanged<DevMilestone> onTap;
  final ValueChanged<DevMilestone> onAddMemory;

  const _DomainSection({
    required this.domain,
    required this.items,
    required this.checkedIds,
    required this.linkedIds,
    required this.isFuture,
    required this.accent,
    required this.onTap,
    required this.onAddMemory,
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
          final hasLink = linkedIds.contains(m.id);

          return InkWell(
            onTap: isFuture ? null : () => onTap(m),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isFuture ? null : () => onTap(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChecked ? color : Colors.transparent,
                        border: Border.all(
                          color: isChecked
                              ? color
                              : isFuture
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),

                  // Title
                  Expanded(
                    child: Text(
                      m.title,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isChecked
                            ? Colors.grey.shade400
                            : isFuture
                                ? Colors.grey.shade400
                                : const Color(0xFF1A1A2E),
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  // 📸 badge / add-memory button
                  if (hasLink)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: isFuture ? null : () => onTap(m),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_camera_outlined,
                              size: 14, color: Colors.teal.shade500),
                        ),
                      ),
                    )
                  else if (isChecked)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: isFuture ? null : () => onAddMemory(m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(
                                'Memory',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
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

// ── Action sheet (check or add memory) ───────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  final DevMilestone cdcMilestone;
  final Color accent;
  final VoidCallback onMarkDone;
  final VoidCallback onAddMemory;

  const _ActionSheet({
    required this.cdcMilestone,
    required this.accent,
    required this.onMarkDone,
    required this.onAddMemory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Milestone name
          Text(
            cdcMilestone.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          // Mark done
          _ActionTile(
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green.shade500,
            title: 'Mark as achieved',
            subtitle: 'Just check it off the list',
            onTap: onMarkDone,
          ),
          const SizedBox(height: 10),
          // Mark done + add memory
          _ActionTile(
            icon: Icons.add_photo_alternate_outlined,
            color: accent,
            title: 'Mark achieved + add to memories',
            subtitle: 'Check it off and save a memory',
            onTap: onAddMemory,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick memory creation sheet ───────────────────────────────────────────────

class _QuickMemorySheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final DevMilestone cdcMilestone;

  const _QuickMemorySheet({
    required this.profileIndex,
    required this.cdcMilestone,
  });

  @override
  ConsumerState<_QuickMemorySheet> createState() => _QuickMemorySheetState();
}

class _QuickMemorySheetState extends ConsumerState<_QuickMemorySheet> {
  late final TextEditingController _titleCtrl;
  final _notesCtrl = TextEditingController();
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.cdcMilestone.title);
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  ProfileTheme get _theme => ProfileTheme.forProfile(
      (ref.read(profilesProvider) ?? [])[widget.profileIndex]);

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final profile =
          (ref.read(profilesProvider) ?? [])[widget.profileIndex];
      final count = profile.milestones.length;
      final milestone = Milestone(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: _notesCtrl.text.trim(),
        date: _date,
        color: Colors.primaries[count % Colors.primaries.length].shade300,
      );
      await ref.read(profilesProvider.notifier).addMilestoneFromChecklist(
            widget.profileIndex,
            widget.cdcMilestone.id,
            milestone,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final accent = theme.accent;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text(
            'Add to memories',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Save this milestone as a memory in your timeline.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 18),

          // Title field
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // Date picker
          GestureDetector(
            onTap: () async {
              final picked = await showAppDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: accent),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(_date),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const Spacer(),
                  Text('Change',
                      style: TextStyle(fontSize: 12, color: accent)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Notes
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    _titleCtrl.text.trim().isEmpty ? Colors.grey.shade300 : accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (_titleCtrl.text.trim().isEmpty || _saving)
                  ? null
                  : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Save to memories',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
