import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../models/reminder.dart';
import '../providers/profiles_provider.dart';
import '../services/notification_service.dart';
import '../utils/profile_theme.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class RemindersScreen extends ConsumerWidget {
  final int profileIndex;

  const RemindersScreen({super.key, required this.profileIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (profiles.isEmpty || profileIndex >= profiles.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = profiles[profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final reminders = profile.reminders
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcoming = reminders.where((r) => !r.isDone).toList();
    final done = reminders.where((r) => r.isDone).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _Header(profile: profile, theme: theme),
          if (upcoming.isEmpty && done.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(theme: theme, kidName: profile.name),
            )
          else ...[
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(label: 'Upcoming', color: theme.accent),
              SliverList.separated(
                itemCount: upcoming.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ReminderCard(
                    reminder: upcoming[i],
                    theme: theme,
                    profileIndex: profileIndex,
                    profileName: profile.name,
                  ),
                ),
              ),
            ],
            if (done.isNotEmpty) ...[
              _SectionHeader(label: 'Completed', color: Colors.grey.shade500),
              SliverList.separated(
                itemCount: done.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ReminderCard(
                    reminder: done[i],
                    theme: theme,
                    profileIndex: profileIndex,
                    profileName: profile.name,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, profile, theme, profileIndex),
        backgroundColor: theme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_outlined),
        label: const Text('Add Reminder'),
      ),
    );
  }

  static void _showAddSheet(
    BuildContext context,
    KidProfile profile,
    ProfileTheme theme,
    int profileIndex,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderSheet(
        profileIndex: profileIndex,
        profile: profile,
        theme: theme,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final KidProfile profile;
  final ProfileTheme theme;

  const _Header({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: theme.accent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Text(
              '${theme.decalEmoji} ',
              style: const TextStyle(fontSize: 20),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.name}\'s Reminders',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    profile.ageText,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        background: DecoratedBox(
          decoration: BoxDecoration(gradient: theme.headerGradient),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final ProfileTheme theme;
  final int profileIndex;
  final String profileName;

  const _ReminderCard({
    required this.reminder,
    required this.theme,
    required this.profileIndex,
    required this.profileName,
  });

  Color get _typeColor => switch (reminder.type) {
        ReminderType.vaccination => const Color(0xFF2E9E6E),
        ReminderType.appointment => const Color(0xFF3B82F6),
        ReminderType.birthday => const Color(0xFFEC4899),
        ReminderType.swimClass => const Color(0xFF06B6D4),
        ReminderType.other => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = reminder.isDone;
    final isOverdue = reminder.isOverdue;
    final dateLabel = _formatDateTime(reminder.dateTime);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete reminder?'),
            content: Text('Remove "${reminder.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(profilesProvider.notifier).deleteReminder(profileIndex, reminder.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('"${reminder.title}" deleted')));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDone ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _typeColor.withAlpha(isDone ? 10 : 25),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Coloured left rail — uses Positioned so it stretches to card height
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: ColoredBox(color: isDone ? Colors.grey.shade300 : _typeColor),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? Colors.grey.shade100
                          : _typeColor.withAlpha(20),
                    ),
                    child: Center(
                      child: Text(
                        reminder.type.emoji,
                        style: TextStyle(fontSize: isDone ? 18 : 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? Colors.grey.shade400
                                : const Color(0xFF1F2937),
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOverdue ? Icons.warning_amber_rounded : Icons.access_time_outlined,
                              size: 13,
                              color: isOverdue ? Colors.orange.shade700 : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? Colors.orange.shade700 : Colors.grey.shade500,
                                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (reminder.repeat != ReminderRepeat.none) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _typeColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  reminder.repeat.fullLabel,
                                  style: TextStyle(fontSize: 10, color: _typeColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            reminder.notes!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Done toggle
                      Transform.scale(
                        scale: 0.85,
                        child: Checkbox(
                          value: isDone,
                          shape: const CircleBorder(),
                          activeColor: _typeColor,
                          onChanged: (v) => ref
                              .read(profilesProvider.notifier)
                              .markReminderDone(profileIndex, reminder.id, v ?? false),
                        ),
                      ),
                      // Edit button
                      if (!isDone)
                        GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _ReminderSheet(
                              profileIndex: profileIndex,
                              profile: ref.read(profilesProvider)![profileIndex],
                              theme: theme,
                              existing: reminder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.edit_outlined, size: 17, color: Colors.grey.shade400),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    final past = diff.isNegative;
    final abs = diff.abs();

    String relative;
    if (abs.inDays == 0) {
      relative = 'Today';
    } else if (abs.inDays == 1) {
      relative = past ? 'Yesterday' : 'Tomorrow';
    } else if (abs.inDays < 7) {
      relative = '${abs.inDays}d ${past ? "ago" : "away"}';
    } else if (abs.inDays < 31) {
      relative = '${(abs.inDays / 7).floor()}w ${past ? "ago" : "away"}';
    } else {
      relative = '${(abs.inDays / 30).floor()}mo ${past ? "ago" : "away"}';
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day} · $hour:$min $ampm  ($relative)';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ProfileTheme theme;
  final String kidName;

  const _EmptyState({required this.theme, required this.kidName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.soft,
                boxShadow: [BoxShadow(color: theme.accent.withAlpha(40), blurRadius: 24, spreadRadius: 4)],
              ),
              child: const Center(child: Text('🔔', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),
            Text(
              'Add vaccinations, appointments, birthdays\nor any event for ${kidName.split(' ').first}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit sheet ──────────────────────────────────────────────────────────

class _ReminderSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final KidProfile profile;
  final ProfileTheme theme;
  final Reminder? existing;

  const _ReminderSheet({
    required this.profileIndex,
    required this.profile,
    required this.theme,
    this.existing,
  });

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late ReminderType _type;
  late DateTime _dateTime;
  late ReminderRepeat _repeat;
  bool _saving = false;
  String? _titleError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _type = e?.type ?? ReminderType.other;
    _dateTime = e?.dateTime ?? DateTime.now().add(const Duration(days: 1, hours: 1));
    _repeat = e?.repeat ?? ReminderRepeat.none;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: widget.theme.accent),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: widget.theme.accent),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    // Request notification permissions on first save
    await NotificationService.requestPermissions();

    setState(() => _saving = true);

    final reminder = Reminder(
      id: widget.existing?.id ?? 'rem_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      dateTime: _dateTime,
      type: _type,
      repeat: _repeat,
    );

    if (_isEditing) {
      await ref.read(profilesProvider.notifier).updateReminder(widget.profileIndex, reminder);
    } else {
      await ref.read(profilesProvider.notifier).addReminder(widget.profileIndex, reminder);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = widget.theme;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dt = _dateTime;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final dateLabel = '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $hour:$min $ampm';

    final inputDeco = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: pTheme.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 18),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: pTheme.soft),
                  child: Icon(Icons.add_alarm_outlined, color: pTheme.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Edit Reminder' : 'New Reminder',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Type selector
            _label('Type'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReminderType.values.map((t) {
                  final selected = _type == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? pTheme.accent : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? pTheme.accent : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            _label('Title *'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) { if (_titleError != null) setState(() => _titleError = null); },
              decoration: inputDeco.copyWith(
                hintText: 'e.g. 6-month vaccination',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 18),

            // Date & time
            _label('Date & Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: pTheme.soft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: pTheme.accent.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, color: pTheme.accent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      dateLabel,
                      style: TextStyle(fontSize: 14, color: pTheme.accent, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_calendar_outlined, size: 16, color: pTheme.accent.withAlpha(150)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Repeat
            _label('Repeat'),
            const SizedBox(height: 8),
            SegmentedButton<ReminderRepeat>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: pTheme.accent,
                selectedForegroundColor: Colors.white,
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade200),
                textStyle: const TextStyle(fontSize: 12),
              ),
              segments: ReminderRepeat.values.map((r) => ButtonSegment(
                value: r,
                label: Text(r.label),
              )).toList(),
              selected: {_repeat},
              onSelectionChanged: (s) => setState(() => _repeat = s.first),
            ),
            const SizedBox(height: 18),

            // Notes
            _label('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: inputDeco.copyWith(hintText: 'e.g. Bring the vaccination card'),
            ),
            const SizedBox(height: 28),

            // Save button
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: pTheme.accent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _isEditing ? 'Save Changes' : 'Set Reminder',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
      );
}
