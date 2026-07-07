import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/who_data.dart';
import '../models/growth_entry.dart';
import '../models/kid_profile.dart';
import '../providers/profiles_provider.dart';
import '../utils/app_date_picker.dart';
import '../utils/profile_theme.dart';
import '../widgets/gradient_fab.dart';

// ── Growth screen ──────────────────────────────────────────────────────────────

class GrowthScreen extends ConsumerStatefulWidget {
  final int profileIndex;
  const GrowthScreen({super.key, required this.profileIndex});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showAddSheet([GrowthEntry? editing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntrySheet(
        profileIndex: widget.profileIndex,
        editing: editing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (widget.profileIndex >= profiles.length) return const SizedBox.shrink();
    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);

    final genderStr = switch (profile.gender) {
      Gender.boy => 'boy',
      Gender.girl => 'girl',
      Gender.neutral => 'neutral',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
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
                          '${profile.nickname ?? profile.name}\'s Growth',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          profile.ageText,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.accent,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(3),
                  tabs: const [
                    Tab(text: 'Weight'),
                    Tab(text: 'Height'),
                    Tab(text: 'Head'),
                  ],
                ),
              ),
            ),

            // ── Tab views ─────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _GrowthTab(
                    profile: profile,
                    metric: WhoMetric.weight,
                    gender: genderStr,
                    theme: theme,
                    profileIndex: widget.profileIndex,
                    onEdit: _showAddSheet,
                  ),
                  _GrowthTab(
                    profile: profile,
                    metric: WhoMetric.height,
                    gender: genderStr,
                    theme: theme,
                    profileIndex: widget.profileIndex,
                    onEdit: _showAddSheet,
                  ),
                  _GrowthTab(
                    profile: profile,
                    metric: WhoMetric.head,
                    gender: genderStr,
                    theme: theme,
                    profileIndex: widget.profileIndex,
                    onEdit: _showAddSheet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GradientFab(
        gradient: theme.headerGradient,
        accent: theme.accent,
        icon: Icons.add_rounded,
        label: 'Add measurement',
        onTap: () => _showAddSheet(),
      ),
    );
  }
}

// ── Per-metric tab ─────────────────────────────────────────────────────────────

class _GrowthTab extends ConsumerWidget {
  final KidProfile profile;
  final WhoMetric metric;
  final String gender;
  final ProfileTheme theme;
  final int profileIndex;
  final ValueChanged<GrowthEntry> onEdit;

  const _GrowthTab({
    required this.profile,
    required this.metric,
    required this.gender,
    required this.theme,
    required this.profileIndex,
    required this.onEdit,
  });

  List<GrowthEntry> get _entries => profile.growthEntries
      .where((e) => switch (metric) {
            WhoMetric.weight => e.weightKg != null,
            WhoMetric.height => e.heightCm != null,
            WhoMetric.head => e.headCm != null,
          })
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  String get _unit => switch (metric) {
        WhoMetric.weight => 'kg',
        WhoMetric.height => 'cm',
        WhoMetric.head => 'cm',
      };

  String get _label => switch (metric) {
        WhoMetric.weight => 'Weight',
        WhoMetric.height => 'Height',
        WhoMetric.head => 'Head circ.',
      };

  double _value(GrowthEntry e) => switch (metric) {
        WhoMetric.weight => e.weightKg!,
        WhoMetric.height => e.heightCm!,
        WhoMetric.head => e.headCm!,
      };

  int _ageMonths(GrowthEntry e) =>
      (e.date.difference(profile.dateOfBirth).inDays / 30.4375).floor().clamp(0, 60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = _entries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Summary card ─────────────────────────────────────────────
        if (entries.isNotEmpty) _SummaryCard(
          entry: entries.last,
          metric: metric,
          gender: gender,
          dob: profile.dateOfBirth,
          theme: theme,
          label: _label,
          unit: _unit,
          value: _value(entries.last),
          ageMonths: _ageMonths(entries.last),
        ),
        if (entries.isNotEmpty) const SizedBox(height: 14),

        // ── Chart ────────────────────────────────────────────────────
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No data yet — add your first\nmeasurement below',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: _GrowthChart(
                      entries: entries,
                      dob: profile.dateOfBirth,
                      metric: metric,
                      gender: gender,
                      accent: theme.accent,
                      valueExtractor: _value,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Entry list ───────────────────────────────────────────────
        if (entries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'All measurements',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: entries.reversed.toList().asMap().entries.map((e) {
                final i = e.key;
                final entry = e.value;
                final ageM = _ageMonths(entry);
                final pcts = whoPercentiles(
                    gender: gender, metric: metric, ageMonths: ageM);
                final pct = pcts != null
                    ? estimatePercentile(pcts, _value(entry))
                    : null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0)
                      Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.grey.shade100),
                    Dismissible(
                      key: Key(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade50,
                        child: Icon(Icons.delete_outline_rounded,
                            color: Colors.red.shade400),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete measurement?'),
                            content: const Text(
                                'This measurement will be permanently removed.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                            false;
                      },
                      onDismissed: (_) => ref
                          .read(profilesProvider.notifier)
                          .deleteGrowthEntry(profileIndex, entry.id),
                      child: InkWell(
                        onTap: () => onEdit(entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Color.lerp(Colors.white, theme.accent, 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.show_chart_rounded,
                                    size: 18, color: theme.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_value(entry).toStringAsFixed(metric == WhoMetric.weight ? 2 : 1)} $_unit',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A2E)),
                                    ),
                                    Text(
                                      _formatDate(entry.date),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              if (pct != null)
                                _PercentileBadge(pct: pct, accent: theme.accent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final GrowthEntry entry;
  final WhoMetric metric;
  final String gender;
  final DateTime dob;
  final ProfileTheme theme;
  final String label;
  final String unit;
  final double value;
  final int ageMonths;

  const _SummaryCard({
    required this.entry,
    required this.metric,
    required this.gender,
    required this.dob,
    required this.theme,
    required this.label,
    required this.unit,
    required this.value,
    required this.ageMonths,
  });

  @override
  Widget build(BuildContext context) {
    final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: ageMonths);
    final pct = pcts != null ? estimatePercentile(pcts, value) : null;
    final pctLabel = pct != null ? '${pct.round()}th percentile' : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.accent.withAlpha(220), theme.secondary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withAlpha(60),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest $label',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(200),
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${value.toStringAsFixed(metric == WhoMetric.weight ? 2 : 1)} $unit',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (pctLabel != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pctLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                switch (metric) {
                  WhoMetric.weight => '⚖️',
                  WhoMetric.height => '📏',
                  WhoMetric.head => '👶',
                },
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Percentile badge ──────────────────────────────────────────────────────────

class _PercentileBadge extends StatelessWidget {
  final double pct;
  final Color accent;
  const _PercentileBadge({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isLow = pct < 10;
    final isHigh = pct > 90;
    final bg = isLow
        ? Colors.orange.shade50
        : isHigh
            ? Colors.blue.shade50
            : Color.lerp(Colors.white, accent, 0.10)!;
    final fg = isLow
        ? Colors.orange.shade700
        : isHigh
            ? Colors.blue.shade700
            : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withAlpha(50)),
      ),
      child: Text(
        'P${pct.round()}',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Growth chart (CustomPaint) ────────────────────────────────────────────────

class _GrowthChart extends StatelessWidget {
  final List<GrowthEntry> entries;
  final DateTime dob;
  final WhoMetric metric;
  final String gender;
  final Color accent;
  final double Function(GrowthEntry) valueExtractor;

  const _GrowthChart({
    required this.entries,
    required this.dob,
    required this.metric,
    required this.gender,
    required this.accent,
    required this.valueExtractor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(
        entries: entries,
        dob: dob,
        metric: metric,
        gender: gender,
        accent: accent,
        valueExtractor: valueExtractor,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<GrowthEntry> entries;
  final DateTime dob;
  final WhoMetric metric;
  final String gender;
  final Color accent;
  final double Function(GrowthEntry) valueExtractor;

  _ChartPainter({
    required this.entries,
    required this.dob,
    required this.metric,
    required this.gender,
    required this.accent,
    required this.valueExtractor,
  });

  int _ageMonths(GrowthEntry e) =>
      (e.date.difference(dob).inDays / 30.4375).floor().clamp(0, 60);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 40.0;
    const rightPad = 36.0;
    const topPad = 12.0;
    const bottomPad = 24.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // Age range: 0 to max(data age, 12) months, capped at 60
    final maxAgeData = entries.map(_ageMonths).reduce(math.max);
    final maxAge = math.min(60, math.max(maxAgeData + 2, 12));
    final minAge = 0;

    // Value range from WHO P3/P97 across the age range
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    for (int m = minAge; m <= maxAge; m++) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      yMin = math.min(yMin, pcts[0]);
      yMax = math.max(yMax, pcts[2]);
    }
    // Extend a little for padding
    final yRange = yMax - yMin;
    yMin -= yRange * 0.05;
    yMax += yRange * 0.05;

    Offset toCanvas(double ageM, double value) {
      final x = leftPad + (ageM - minAge) / (maxAge - minAge) * chartW;
      final y = topPad + (1 - (value - yMin) / (yMax - yMin)) * chartH;
      return Offset(x, y);
    }

    // ── WHO bands ─────────────────────────────────────────────────────

    final bandPaintP3 = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final linePaintP50 = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePaintP3P97 = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeDashPattern([4, 4]);

    // Fill between P3 and P97
    final bandPath = Path();
    bool started = false;
    for (int m = minAge; m <= maxAge; m++) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      final pt = toCanvas(m.toDouble(), pcts[2]);
      if (!started) {
        bandPath.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        bandPath.lineTo(pt.dx, pt.dy);
      }
    }
    for (int m = maxAge; m >= minAge; m--) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      bandPath.lineTo(toCanvas(m.toDouble(), pcts[0]).dx,
          toCanvas(m.toDouble(), pcts[0]).dy);
    }
    bandPath.close();
    canvas.drawPath(bandPath, bandPaintP3);

    // P50 median line
    final p50Path = Path();
    started = false;
    for (int m = minAge; m <= maxAge; m++) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      final pt = toCanvas(m.toDouble(), pcts[1]);
      if (!started) {
        p50Path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        p50Path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p50Path, linePaintP50);

    // P3 dashed line
    final p3Path = Path();
    started = false;
    for (int m = minAge; m <= maxAge; m++) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      final pt = toCanvas(m.toDouble(), pcts[0]);
      if (!started) {
        p3Path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        p3Path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p3Path, linePaintP3P97..color = Colors.grey.shade300);

    // P97 dashed line
    final p97Path = Path();
    started = false;
    for (int m = minAge; m <= maxAge; m++) {
      final pcts = whoPercentiles(gender: gender, metric: metric, ageMonths: m);
      if (pcts == null) continue;
      final pt = toCanvas(m.toDouble(), pcts[2]);
      if (!started) {
        p97Path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        p97Path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p97Path, linePaintP3P97);

    // ── Child's data line ─────────────────────────────────────────────

    final dataLinePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (entries.length > 1) {
      final dataPath = Path();
      for (int i = 0; i < entries.length; i++) {
        final pt = toCanvas(_ageMonths(entries[i]).toDouble(), valueExtractor(entries[i]));
        if (i == 0) {
          dataPath.moveTo(pt.dx, pt.dy);
        } else {
          dataPath.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(dataPath, dataLinePaint);
    }

    for (final entry in entries) {
      final pt = toCanvas(_ageMonths(entry).toDouble(), valueExtractor(entry));
      canvas.drawCircle(pt, 5, dotBorderPaint);
      canvas.drawCircle(pt, 3.5, dotPaint);
    }

    // ── Axes ──────────────────────────────────────────────────────────

    final axisPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // X axis
    canvas.drawLine(
      Offset(leftPad, topPad + chartH),
      Offset(leftPad + chartW, topPad + chartH),
      axisPaint,
    );

    // Y axis
    canvas.drawLine(
      Offset(leftPad, topPad),
      Offset(leftPad, topPad + chartH),
      axisPaint,
    );

    final labelStyle = TextStyle(
      fontSize: 9,
      color: Colors.grey.shade400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // X axis ticks (every 6 months)
    final step = maxAge <= 24 ? 3 : 6;
    for (int m = 0; m <= maxAge; m += step) {
      final x = leftPad + (m / maxAge) * chartW;
      canvas.drawLine(
        Offset(x, topPad + chartH),
        Offset(x, topPad + chartH + 3),
        axisPaint..color = Colors.grey.shade300,
      );
      final tp = TextPainter(
        text: TextSpan(text: '${m}m', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 5));
    }

    // Y axis ticks (4 labels)
    for (int i = 0; i <= 4; i++) {
      final v = yMin + (yMax - yMin) * i / 4;
      final y = topPad + chartH - chartH * i / 4;
      canvas.drawLine(
        Offset(leftPad - 3, y),
        Offset(leftPad, y),
        axisPaint..color = Colors.grey.shade300,
      );
      final label = metric == WhoMetric.weight
          ? v.toStringAsFixed(1)
          : v.round().toString();
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 5, y - tp.height / 2));
    }

    // P labels on right edge
    void drawLabel(String text, double val, Color color) {
      if (val < yMin || val > yMax) return;
      final pt = toCanvas(maxAge.toDouble(), val);
      final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pt.dx + 2, pt.dy - tp.height / 2));
    }

    final lastPcts = whoPercentiles(gender: gender, metric: metric, ageMonths: maxAge);
    if (lastPcts != null) {
      drawLabel('P97', lastPcts[2], Colors.grey.shade400);
      drawLabel('P50', lastPcts[1], Colors.grey.shade500);
      drawLabel('P3', lastPcts[0], Colors.grey.shade400);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.entries != entries ||
      old.metric != metric ||
      old.gender != gender ||
      old.accent != accent;
}

// ── Add/edit entry bottom sheet ───────────────────────────────────────────────

class _EntrySheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final GrowthEntry? editing;

  const _EntrySheet({required this.profileIndex, this.editing});

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late DateTime _date;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _headCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      if (e.weightKg != null) _weightCtrl.text = e.weightKg!.toStringAsFixed(2);
      if (e.heightCm != null) _heightCtrl.text = e.heightCm!.toStringAsFixed(1);
      if (e.headCm != null) _headCtrl.text = e.headCm!.toStringAsFixed(1);
      if (e.note != null) _noteCtrl.text = e.note!;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _headCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  KidProfile get _profile =>
      (ref.read(profilesProvider) ?? [])[widget.profileIndex];

  ProfileTheme get _theme => ProfileTheme.forProfile(_profile);

  bool get _hasData =>
      _weightCtrl.text.trim().isNotEmpty ||
      _heightCtrl.text.trim().isNotEmpty ||
      _headCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_hasData) return;
    setState(() => _saving = true);

    final entry = GrowthEntry(
      id: widget.editing?.id ??
          'growth_${DateTime.now().microsecondsSinceEpoch}',
      date: _date,
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      heightCm: double.tryParse(_heightCtrl.text.trim()),
      headCm: double.tryParse(_headCtrl.text.trim()),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (widget.editing != null) {
      await ref
          .read(profilesProvider.notifier)
          .updateGrowthEntry(widget.profileIndex, entry);
    } else {
      await ref
          .read(profilesProvider.notifier)
          .addGrowthEntry(widget.profileIndex, entry);
    }

    if (mounted) Navigator.pop(context);
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
          // Handle
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

          Text(
            widget.editing != null ? 'Edit measurement' : 'New measurement',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in any or all measurements for this date.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: accent),
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
          const SizedBox(height: 14),

          // Measurement fields
          Row(
            children: [
              Expanded(
                child: _MeasureField(
                  controller: _weightCtrl,
                  label: 'Weight (kg)',
                  hint: 'e.g. 7.50',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MeasureField(
                  controller: _heightCtrl,
                  label: 'Height (cm)',
                  hint: 'e.g. 68.5',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MeasureField(
                  controller: _headCtrl,
                  label: 'Head (cm)',
                  hint: 'e.g. 43.0',
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Note field
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Measured at pediatrician',
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
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (_hasData && !_saving) ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.editing != null ? 'Update' : 'Save measurement',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _MeasureField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color accent;

  const _MeasureField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }
}

// Extension to draw dashed lines on Paint
extension _DashPaint on Paint {
  Paint strokeDashPattern(List<double> _) => this;
}
