import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/future_plan.dart';
import '../models/kid_profile.dart';
import '../providers/profiles_provider.dart';
import '../utils/app_date_picker.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';
import '../widgets/gradient_fab.dart';

// ── Future Plans Screen ────────────────────────────────────────────────────────

class FuturePlansScreen extends ConsumerWidget {
  final int profileIndex;

  const FuturePlansScreen({super.key, required this.profileIndex});

  static void push(BuildContext context, int profileIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FuturePlansScreen(profileIndex: profileIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (profileIndex >= profiles.length) return const SizedBox.shrink();
    final profile = profiles[profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final plans = profile.futurePlans;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          _AppBar(profile: profile, theme: theme),
          if (plans.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(theme: theme, onAdd: () => _showAddSheet(context, ref, theme)),
            )
          else ...[
            _SummaryBar(plans: plans, theme: theme),
            for (final cat in FuturePlanCategory.values)
              _CategorySection(
                category: cat,
                plans: plans.where((p) => p.category == cat).toList(),
                theme: theme,
                onAdd: () => _showAddSheet(context, ref, theme, initialCategory: cat),
                onEdit: (plan) => _showEditSheet(context, ref, theme, plan),
                onDelete: (plan) => _confirmDelete(context, ref, plan),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButton: GradientFab(
        gradient: theme.headerGradient,
        accent: theme.accent,
        icon: Icons.add_rounded,
        label: 'Add plan',
        onTap: () => _showAddSheet(context, ref, theme),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, ProfileTheme theme,
      {FuturePlanCategory? initialCategory}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanSheet(
        profileIndex: profileIndex,
        theme: theme,
        initialCategory: initialCategory,
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, ProfileTheme theme, FuturePlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanSheet(
        profileIndex: profileIndex,
        theme: theme,
        editing: plan,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FuturePlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete plan?'),
        content: Text('Delete "${plan.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(profilesProvider.notifier).deleteFuturePlan(profileIndex, plan.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final KidProfile profile;
  final ProfileTheme theme;

  const _AppBar({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: theme.accent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: theme.headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🌟', style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Future Plans',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'For ${profile.nickname ?? profile.name}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<FuturePlan> plans;
  final ProfileTheme theme;

  const _SummaryBar({required this.plans, required this.theme});

  @override
  Widget build(BuildContext context) {
    final totalTarget = plans.fold<double>(
        0, (s, p) => s + (p.targetAmount ?? 0));
    final totalCurrent = plans.fold<double>(
        0, (s, p) => s + (p.currentAmount ?? 0));
    final overall = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${plans.length} plan${plans.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.accent,
                    ),
                  ),
                  const Spacer(),
                  if (totalTarget > 0)
                    Text(
                      '${(overall * 100).toStringAsFixed(0)}% funded',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              if (totalTarget > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overall,
                    minHeight: 8,
                    backgroundColor: theme.soft,
                    valueColor: AlwaysStoppedAnimation(theme.accent),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _fmt(totalCurrent, 'INR'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(totalTarget, 'INR'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category section ──────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final FuturePlanCategory category;
  final List<FuturePlan> plans;
  final ProfileTheme theme;
  final VoidCallback onAdd;
  final ValueChanged<FuturePlan> onEdit;
  final ValueChanged<FuturePlan> onDelete;

  const _CategorySection({
    required this.category,
    required this.plans,
    required this.theme,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${category.emoji}  ${category.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 14, color: theme.accent),
                        const SizedBox(width: 3),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (plans.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      'No ${category.label.toLowerCase()} plans yet',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...plans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlanCard(
                      plan: plan,
                      theme: theme,
                      onEdit: () => onEdit(plan),
                      onDelete: () => onDelete(plan),
                    ),
                  )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final FuturePlan plan;
  final ProfileTheme theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAmount = plan.targetAmount != null && plan.targetAmount! > 0;
    final progress = plan.progressPercent;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Asset type badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        plan.assetType.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.soft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan.assetType.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.accent,
                                ),
                              ),
                            ),
                            if (plan.targetDate != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.calendar_today_outlined,
                                  size: 11, color: Colors.grey.shade400),
                              const SizedBox(width: 3),
                              Text(
                                formatMonthYear(plan.targetDate!),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Colors.grey.shade400, size: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              if (plan.description != null && plan.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (hasAmount) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: theme.soft,
                              valueColor: AlwaysStoppedAnimation(
                                progress >= 1.0
                                    ? Colors.green
                                    : theme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                _fmt(plan.currentAmount ?? 0, plan.currency),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.accent,
                                ),
                              ),
                              Text(
                                ' / ${_fmt(plan.targetAmount!, plan.currency)}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: progress >= 1.0 ? Colors.green : theme.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ProfileTheme theme;
  final VoidCallback onAdd;

  const _EmptyState({required this.theme, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.soft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌟', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Plan their future',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Track gold, land, savings, stocks and more — everything you\'re building for their education, marriage and future.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: theme.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add first plan',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ──────────────────────────────────────────────────────────

class _PlanSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final ProfileTheme theme;
  final FuturePlanCategory? initialCategory;
  final FuturePlan? editing;

  const _PlanSheet({
    required this.profileIndex,
    required this.theme,
    this.initialCategory,
    this.editing,
  });

  @override
  ConsumerState<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<_PlanSheet> {
  late FuturePlanCategory _category;
  late AssetType _assetType;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  String _currency = 'INR';
  DateTime? _targetDate;
  bool _saving = false;

  static const _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD'];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _category = e?.category ?? widget.initialCategory ?? FuturePlanCategory.education;
    _assetType = e?.assetType ?? AssetType.money;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _targetCtrl = TextEditingController(
        text: e?.targetAmount != null ? e!.targetAmount!.toStringAsFixed(0) : '');
    _currentCtrl = TextEditingController(
        text: e?.currentAmount != null ? e!.currentAmount!.toStringAsFixed(0) : '');
    _currency = e?.currency ?? 'INR';
    _targetDate = e?.targetDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.editing != null;

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    setState(() => _saving = true);

    final target = double.tryParse(_targetCtrl.text.trim());
    final current = double.tryParse(_currentCtrl.text.trim());

    if (_isEdit) {
      final updated = widget.editing!.copyWith(
        category: _category,
        assetType: _assetType,
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        clearDescription: _descCtrl.text.trim().isEmpty,
        targetAmount: target,
        clearTargetAmount: target == null,
        currentAmount: current,
        clearCurrentAmount: current == null,
        currency: _currency,
        targetDate: _targetDate,
        clearTargetDate: _targetDate == null,
      );
      await ref.read(profilesProvider.notifier).updateFuturePlan(widget.profileIndex, updated);
    } else {
      final plan = FuturePlan(
        id: 'plan_${DateTime.now().microsecondsSinceEpoch}',
        category: _category,
        assetType: _assetType,
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        targetAmount: target,
        currentAmount: current,
        currency: _currency,
        targetDate: _targetDate,
        createdAt: DateTime.now(),
      );
      await ref.read(profilesProvider.notifier).addFuturePlan(widget.profileIndex, plan);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  _isEdit ? 'Edit Plan' : 'New Plan',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: theme.accent),
                        )
                      : Text('Save',
                          style: TextStyle(
                              color: theme.accent,
                              fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category picker
                  _Label('Category'),
                  const SizedBox(height: 6),
                  Row(
                    children: FuturePlanCategory.values.map((cat) {
                      final sel = _category == cat;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? theme.accent : theme.soft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel ? theme.accent : theme.accent.withAlpha(40),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(cat.emoji,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : theme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Asset type
                  _Label('Asset Type'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AssetType.values.map((type) {
                      final sel = _assetType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _assetType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? theme.accent : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? theme.accent : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(type.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 5),
                              Text(
                                type.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      sel ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  _Label('Title'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDeco(
                      'e.g. Gold saved for marriage',
                      Icons.title_outlined,
                      theme,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _Label('Notes (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDeco(
                      'Add any details…',
                      Icons.notes_outlined,
                      theme,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount row
                  _Label('Amount'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Currency dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButton<String>(
                          value: _currency,
                          underline: const SizedBox.shrink(),
                          items: _currencies
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? _currency),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _currentCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'))
                          ],
                          decoration: _inputDeco(
                              'Current amount', Icons.account_balance_wallet_outlined, theme),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _targetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'))
                          ],
                          decoration:
                              _inputDeco('Target', Icons.flag_outlined, theme),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target date
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showAppDatePicker(
                        context: context,
                        initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                      );
                      if (picked != null) setState(() => _targetDate = picked);
                    },
                    icon: Icon(Icons.calendar_month_outlined, color: theme.accent),
                    label: Text(
                      _targetDate != null
                          ? 'Target: ${formatMonthYear(_targetDate!)}'
                          : 'Set target date (optional)',
                      style: TextStyle(
                          color: theme.accent, fontWeight: FontWeight.w500),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: theme.accent.withAlpha(120)),
                    ),
                  ),
                  if (_targetDate != null)
                    TextButton(
                      onPressed: () => setState(() => _targetDate = null),
                      child: const Text('Remove date',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, ProfileTheme theme) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: theme.accent, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.accent, width: 1.5),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      );
}

String _fmt(double amount, String currency) {
  if (amount == 0) return '$currency 0';
  if (amount >= 10000000) return '$currency ${(amount / 10000000).toStringAsFixed(1)}Cr';
  if (amount >= 100000) return '$currency ${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '$currency ${(amount / 1000).toStringAsFixed(1)}K';
  return '$currency ${amount.toStringAsFixed(0)}';
}
