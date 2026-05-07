import 'package:flutter/material.dart';
import '../models/milestone.dart';
import '../utils/date_formatter.dart';
import 'attachment_preview.dart';

class MilestoneCard extends StatelessWidget {
  final Milestone milestone;

  const MilestoneCard({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: milestone.color.withAlpha(46),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: milestone.color),
            child: const Icon(Icons.star, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  milestone.description,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      formatDate(milestone.date),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                if (milestone.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: milestone.attachments.map((a) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AttachmentPreview(attachment: a),
                          if (a.label != null && a.label!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 2),
                              child: Text(
                                a.label!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
