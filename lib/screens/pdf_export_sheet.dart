import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../providers/profiles_provider.dart';
import '../services/pdf_export_service.dart';
import '../utils/profile_theme.dart';

// ── Date range option ─────────────────────────────────────────────────────────

enum _Range { allTime, last3, last6, thisYear }

extension _RangeLabel on _Range {
  String get label => switch (this) {
        _Range.allTime => 'All time',
        _Range.last3 => 'Last 3 months',
        _Range.last6 => 'Last 6 months',
        _Range.thisYear => 'This year',
      };

  DateTimeRange? dateRange() {
    final now = DateTime.now();
    return switch (this) {
      _Range.allTime => null,
      _Range.last3 =>
        DateTimeRange(start: DateTime(now.year, now.month - 3, now.day), end: now),
      _Range.last6 =>
        DateTimeRange(start: DateTime(now.year, now.month - 6, now.day), end: now),
      _Range.thisYear =>
        DateTimeRange(start: DateTime(now.year, 1, 1), end: now),
    };
  }
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class PdfExportSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  const PdfExportSheet({super.key, required this.profileIndex});

  @override
  ConsumerState<PdfExportSheet> createState() => _PdfExportSheetState();
}

class _PdfExportSheetState extends ConsumerState<PdfExportSheet> {
  _Range _range = _Range.allTime;
  bool _favoritesOnly = false;
  bool _includePhotos = true;
  bool _exporting = false;

  KidProfile get _profile =>
      (ref.read(profilesProvider) ?? [])[widget.profileIndex];

  ProfileTheme get _theme => ProfileTheme.forProfile(_profile);

  List<Milestone> get _filtered {
    var list = _profile.milestones;
    final range = _range.dateRange();
    if (range != null) {
      list = list
          .where((m) =>
              !m.date.isBefore(range.start) && !m.date.isAfter(range.end))
          .toList();
    }
    if (_favoritesOnly) list = list.where((m) => m.isFavorite).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> _export() async {
    final milestones = _filtered;
    if (milestones.isEmpty) return;

    setState(() => _exporting = true);
    try {
      final bytes = await PdfExportService.generateMemoryBook(
        profile: _profile,
        milestones: milestones,
        includePhotos: _includePhotos,
      );
      if (!mounted) return;
      final name = '${_profile.name.replaceAll(' ', '_')}_MemoryBook.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final accent = theme.accent;
    final count = _filtered.length;

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

          // Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, accent, 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.picture_as_pdf_outlined,
                    size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Memory Book',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  Text(
                    '$count memories selected',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Options card ─────────────────────────────────────────────
          Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date range
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_outlined,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        'Date range',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _Range.values.map((r) {
                      final selected = _range == r;
                      return GestureDetector(
                        onTap: () => setState(() => _range = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? Color.lerp(Colors.white, accent, 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? accent.withAlpha(120)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            r.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? accent : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100),

                // Favorites only
                _OptionRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Favorites only',
                  accent: accent,
                  value: _favoritesOnly,
                  onChanged: (v) => setState(() => _favoritesOnly = v),
                ),

                Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100),

                // Include photos
                _OptionRow(
                  icon: Icons.photo_outlined,
                  label: 'Include photos',
                  accent: accent,
                  value: _includePhotos,
                  onChanged: (v) => setState(() => _includePhotos = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Export button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: count == 0 ? Colors.grey.shade300 : accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (count == 0 || _exporting) ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined,
                      size: 18, color: Colors.white),
              label: Text(
                _exporting
                    ? 'Generating PDF…'
                    : count == 0
                        ? 'No memories in range'
                        : 'Export $count memories',
                style: const TextStyle(
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
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF1A1A2E))),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
          ),
        ],
      ),
    );
  }
}
