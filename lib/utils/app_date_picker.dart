import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet with a Cupertino-style spinning wheel date picker.
/// Returns the selected [DateTime] or null if the user dismissed without confirming.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  // Clamp initialDate within bounds.
  final clamped = initialDate.isBefore(firstDate)
      ? firstDate
      : initialDate.isAfter(lastDate)
          ? lastDate
          : initialDate;

  DateTime selected = clamped;
  bool confirmed = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      confirmed = true;
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Wheel picker ─────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: clamped,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (d) => selected = d,
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      );
    },
  );

  return confirmed ? selected : null;
}
