import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/profile_theme.dart';

class PdfExportService {
  /// Generates a memory book PDF and returns the bytes.
  static Future<Uint8List> generateMemoryBook({
    required KidProfile profile,
    required List<Milestone> milestones,
    required bool includePhotos,
  }) async {
    final theme = ProfileTheme.forProfile(profile);
    final accentPdf = _toPdf(theme.accent);
    final softPdf = _toPdf(theme.soft);

    final doc = pw.Document(
      title: '${profile.name}\'s Memory Book',
      author: 'M 4 Memories',
    );

    // Pre-load images if requested (do it once, outside page builders)
    final Map<String, Uint8List> imageCache = {};
    if (includePhotos) {
      for (final m in milestones) {
        final first = _firstImage(m);
        if (first == null) continue;
        final bytes = await _loadImageBytes(first);
        if (bytes != null) imageCache[first.id] = bytes;
      }
    }

    // ── Cover page ─────────────────────────────────────────────────────────
    doc.addPage(_buildCoverPage(
      profile: profile,
      count: milestones.length,
      accentPdf: accentPdf,
      softPdf: softPdf,
    ));

    // ── Milestone pages (MultiPage handles pagination automatically) ────────
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context ctx) => [
        for (final m in milestones)
          _buildMilestoneCard(
            milestone: m,
            profile: profile,
            accentPdf: accentPdf,
            imageBytes: imageCache[_firstImage(m)?.id],
          ),
      ],
    ));

    return doc.save();
  }

  // ── Cover page ────────────────────────────────────────────────────────────

  static pw.Page _buildCoverPage({
    required KidProfile profile,
    required int count,
    required PdfColor accentPdf,
    required PdfColor softPdf,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Accent top section
            pw.Expanded(
              flex: 42,
              child: pw.Container(
                color: accentPdf,
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    // Circle logo
                    pw.Container(
                      width: 90,
                      height: 90,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : 'M',
                        style: pw.TextStyle(
                          fontSize: 48,
                          fontWeight: pw.FontWeight.bold,
                          color: accentPdf,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      '${profile.name}\'s',
                      style: pw.TextStyle(
                        fontSize: 20,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Memory Book',
                      style: pw.TextStyle(
                        fontSize: 34,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Soft bottom section
            pw.Expanded(
              flex: 58,
              child: pw.Container(
                color: softPdf,
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    // Stats box
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 32, vertical: 18),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(16)),
                        border: pw.Border.all(
                          color: PdfColors.grey200,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$count memories',
                            style: pw.TextStyle(
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold,
                              color: accentPdf,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'cherished forever',
                            style: const pw.TextStyle(
                              fontSize: 13,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      profile.ageText,
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      'M 4 Memories',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Milestone card ────────────────────────────────────────────────────────

  static pw.Widget _buildMilestoneCard({
    required Milestone milestone,
    required KidProfile profile,
    required PdfColor accentPdf,
    Uint8List? imageBytes,
  }) {
    final milestonePdf = _toPdf(milestone.color);
    final dateStr = _formatDate(milestone.date);
    final ageStr = _ageAtDate(milestone.date, profile.dateOfBirth);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 10,
        verticalRadius: 10,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Coloured left strip
            pw.Container(width: 6, color: milestonePdf),
            // Content
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Title + date row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            milestone.title,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              dateStr,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600),
                            ),
                            if (ageStr != null)
                              pw.Text(
                                ageStr,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey500),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Description
                    if (milestone.description.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        milestone.description,
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700),
                        maxLines: 4,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ],
                    // Photo
                    if (imageBytes != null) ...[
                      pw.SizedBox(height: 8),
                      pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(
                          pw.MemoryImage(imageBytes),
                          width: double.infinity,
                          height: 160,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ],
                    // Tags
                    if (milestone.tags.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: milestone.tags.map((tag) {
                          return pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              tag,
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.grey600),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Attachment? _firstImage(Milestone m) =>
      m.attachments.where((a) => a.type == AttachmentType.image).firstOrNull;

  static Future<Uint8List?> _loadImageBytes(Attachment a) async {
    try {
      // In-memory web bytes (short-lived but available during the session)
      if (a.webBytes != null) return a.webBytes;
      // Local file (native)
      if (!kIsWeb && a.localPath.isNotEmpty) {
        final f = File(a.localPath);
        if (await f.exists()) return await f.readAsBytes();
      }
      // Drive shareable URL (stored as localPath on web after upload)
      if (a.localPath.startsWith('http')) {
        final resp = await http.get(Uri.parse(a.localPath))
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static PdfColor _toPdf(Color c) => PdfColor(c.r, c.g, c.b);

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String? _ageAtDate(DateTime date, DateTime? dob) {
    if (dob == null) return null;
    final totalDays = date.difference(dob).inDays;
    if (totalDays < 0) return null;
    if (totalDays < 7) return '${totalDays}d old';
    if (totalDays < 30) return '${(totalDays / 7).floor()}w old';
    int y = date.year - dob.year;
    int m = date.month - dob.month;
    if (date.day < dob.day) m -= 1;
    if (m < 0) { y -= 1; m += 12; }
    final totalMonths = y * 12 + m;
    if (totalMonths < 24) return '${totalMonths}mo old';
    return '${y}yr${m > 0 ? ' ${m}mo' : ''} old';
  }
}
