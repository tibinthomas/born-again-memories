import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory_sparks.dart';
import '../models/custom_spark.dart';
import '../models/milestone.dart';
import '../providers/app_settings_provider.dart';
import '../providers/profiles_provider.dart';
import '../utils/profile_theme.dart';
import 'home/widgets/add_milestone_sheet.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class SparksScreen extends ConsumerStatefulWidget {
  final int profileIndex;
  const SparksScreen({super.key, required this.profileIndex});

  @override
  ConsumerState<SparksScreen> createState() => _SparksScreenState();
}

class _SparksScreenState extends ConsumerState<SparksScreen> {
  SparkCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (widget.profileIndex >= profiles.length) return const SizedBox.shrink();

    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final settings = ref.watch(appSettingsProvider);
    final ageMonths =
        DateTime.now().difference(profile.dateOfBirth).inDays ~/ 30;

    final ageSparks = sparksForAge(ageMonths, category: _filter);
    final allCustom = settings.customSparks
        .where((s) => _filter == null || s.category == _filter)
        .toList();
    final todaySpark = sparkOfTheDay(ageMonths);

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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20),
                    color: const Color(0xFF1A1A2E),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile.nickname ?? profile.name}\'s Memory Sparks',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Activity ideas to spark a new memory',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Category filter chips ─────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                children: [
                  _FilterChip(
                    label: 'All',
                    emoji: '✨',
                    selected: _filter == null,
                    accent: theme.accent,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...SparkCategory.values.map((c) => _FilterChip(
                        label: c.label,
                        emoji: c.emoji,
                        selected: _filter == c,
                        accent: theme.accent,
                        onTap: () =>
                            setState(() => _filter = _filter == c ? null : c),
                      )),
                ],
              ),
            ),

            // ── Scrollable list ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // Today's Spark — featured hero card
                  if (_filter == null) ...[
                    _SparkOfDayCard(
                      spark: todaySpark,
                      accent: theme.accent,
                      secondary: theme.secondary,
                      onUse: () => _useSpark(todaySpark),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Ideas for ${profile.ageText}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ],

                  // Age-appropriate built-in sparks
                  ...ageSparks
                      .where((s) => _filter == null || s.id != todaySpark.id)
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SparkCard(
                              title: s.title,
                              description: s.description,
                              category: s.category,
                              accent: theme.accent,
                              onUse: () => _useSpark(s),
                            ),
                          )),

                  if (ageSparks.isEmpty && _filter != null)
                    _EmptyFilter(accent: theme.accent),

                  // Custom sparks section
                  if (allCustom.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                        'Your ideas',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500),
                      ),
                    ),
                    ...allCustom.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SparkCard(
                            title: s.title,
                            description: s.description,
                            category: s.category,
                            accent: theme.accent,
                            isCustom: true,
                            onUse: () => _useCustomSpark(s),
                            onDelete: () => _deleteCustomSpark(s.id),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomSheet,
        backgroundColor: theme.accent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add your idea',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _useSpark(MemorySpark spark) {
    _showSparkActionSheet(
      title: spark.title,
      onCreateMemory: () => _openAddMilestone(
        sparkId: spark.id,
        sparkTitle: spark.title,
        prefillTitle: spark.title,
      ),
    );
  }

  void _useCustomSpark(CustomSpark spark) {
    _showSparkActionSheet(
      title: spark.title,
      onCreateMemory: () => _openAddMilestone(
        sparkId: spark.id,
        sparkTitle: spark.title,
        prefillTitle: spark.title,
      ),
    );
  }

  void _showSparkActionSheet({
    required String title,
    required VoidCallback onCreateMemory,
  }) {
    final profiles = ref.read(profilesProvider) ?? [];
    final theme = ProfileTheme.forProfile(profiles[widget.profileIndex]);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SparkActionSheet(
        title: title,
        accent: theme.accent,
        onCreateMemory: () {
          Navigator.pop(context);
          onCreateMemory();
        },
      ),
    );
  }

  void _openAddMilestone({
    required String sparkId,
    required String sparkTitle,
    required String prefillTitle,
  }) {
    final profiles = ref.read(profilesProvider) ?? [];
    final profile = profiles[widget.profileIndex];
    final count = profile.milestones.length;
    final prefilled = Milestone(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: prefillTitle,
      description: '',
      date: DateTime.now(),
      color: Colors.primaries[count % Colors.primaries.length].shade300,
      sparkId: sparkId,
      sparkTitle: sparkTitle,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddMilestoneSheet(initialMilestone: prefilled),
    );
  }

  void _showAddCustomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomSparkSheet(
        onSave: (spark) {
          final settings = ref.read(appSettingsProvider);
          ref.read(appSettingsProvider.notifier).update(
                settings.copyWith(
                    customSparks: [...settings.customSparks, spark]),
              );
        },
      ),
    );
  }

  void _deleteCustomSpark(String id) {
    final settings = ref.read(appSettingsProvider);
    ref.read(appSettingsProvider.notifier).update(
          settings.copyWith(
            customSparks:
                settings.customSparks.where((s) => s.id != id).toList(),
          ),
        );
  }
}

// ── Today's Spark hero card ────────────────────────────────────────────────────

class _SparkOfDayCard extends StatelessWidget {
  final MemorySpark spark;
  final Color accent;
  final Color secondary;
  final VoidCallback onUse;

  const _SparkOfDayCard({
    required this.spark,
    required this.accent,
    required this.secondary,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withAlpha(220), secondary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accent.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      const Text(
                        'Spark of the day',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  spark.category.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              spark.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spark.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(220),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onUse,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      'Make a memory from this',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Regular spark card ─────────────────────────────────────────────────────────

class _SparkCard extends StatelessWidget {
  final String title;
  final String description;
  final SparkCategory category;
  final Color accent;
  final bool isCustom;
  final VoidCallback onUse;
  final VoidCallback? onDelete;

  const _SparkCard({
    required this.title,
    required this.description,
    required this.category,
    required this.accent,
    this.isCustom = false,
    required this.onUse,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onUse,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category emoji circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, accent, 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(category.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (isCustom && onDelete != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(Icons.delete_outline_rounded,
                                size: 17, color: Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Color.lerp(Colors.white, accent, 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.label,
                            style: TextStyle(
                                fontSize: 10,
                                color: accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to use →',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accent.withAlpha(40),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty filter state ────────────────────────────────────────────────────────

class _EmptyFilter extends StatelessWidget {
  final Color accent;
  const _EmptyFilter({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.bolt_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'No ideas in this category yet\nfor this age group.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap + to add your own idea',
            style: TextStyle(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Spark action sheet ────────────────────────────────────────────────────────

class _SparkActionSheet extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback onCreateMemory;

  const _SparkActionSheet({
    required this.title,
    required this.accent,
    required this.onCreateMemory,
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
          const Icon(Icons.bolt_rounded, size: 28, color: Color(0xFFFBBF24)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCreateMemory,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Color.lerp(Colors.white, accent, 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withAlpha(80)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Create a memory from this spark',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add custom spark sheet ────────────────────────────────────────────────────

class _AddCustomSparkSheet extends ConsumerStatefulWidget {
  final ValueChanged<CustomSpark> onSave;
  const _AddCustomSparkSheet({required this.onSave});

  @override
  ConsumerState<_AddCustomSparkSheet> createState() =>
      _AddCustomSparkSheetState();
}

class _AddCustomSparkSheetState extends ConsumerState<_AddCustomSparkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  SparkCategory _category = SparkCategory.play;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onSave(CustomSpark(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: _descCtrl.text.trim(),
      category: _category,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.read(profilesProvider) ?? [];
    final profile = profiles.isNotEmpty ? profiles.first : null;
    final accent = profile != null
        ? ProfileTheme.forProfile(profile).accent
        : Colors.pinkAccent;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
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
          const Text('Add your own idea',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('It will appear in your personal Sparks list.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 18),

          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Activity title',
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

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
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
          const SizedBox(height: 10),

          // Category picker
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SparkCategory>(
                value: _category,
                isExpanded: true,
                items: SparkCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Text(c.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(c.label,
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _titleCtrl.text.trim().isEmpty
                    ? Colors.grey.shade300
                    : accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed:
                  _titleCtrl.text.trim().isEmpty ? null : _save,
              child: const Text('Add idea',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
