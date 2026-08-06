import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ugc_safety_service.dart';

const ugcTermsSummary = '''
Be respectful and keep Growing Memories safe for families.

Do not post sexual or exploitative content, especially content involving minors; hate speech; harassment; threats; graphic violence; self-harm encouragement; illegal activity; scams; dangerous medical misinformation; another person's private information; spam; or content you do not have permission to share.

Community posts may be reported, hidden, or removed. Accounts may be restricted for repeated or serious violations. If content may involve child exploitation or immediate danger, contact the appropriate local authorities in addition to reporting it here.
''';

Future<bool> ensureUgcTermsAccepted(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  if (await UgcSafetyService.hasAcceptedTerms(uid)) return true;
  if (!context.mounted) return false;

  var agreed = false;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Community Terms'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(ugcTermsSummary),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: agreed,
                  onChanged: (value) => setState(() => agreed = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I agree to follow these Community Terms.'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: agreed ? () => Navigator.pop(dialogContext, true) : null,
            child: const Text('Agree and continue'),
          ),
        ],
      ),
    ),
  );
  if (accepted != true) return false;
  await UgcSafetyService.acceptTerms(uid);
  return true;
}

class UgcSafetyMenu extends StatelessWidget {
  final String authorId;
  final String authorName;
  final String targetType;
  final String targetId;
  final String targetPath;

  const UgcSafetyMenu({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.targetType,
    required this.targetId,
    required this.targetPath,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Safety actions',
      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF616161)),
      onSelected: (action) {
        if (action == 'report_content') _report(context, false);
        if (action == 'report_user') _report(context, true);
        if (action == 'block') _block(context);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'report_content',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.flag_outlined),
            title: Text('Report content'),
          ),
        ),
        PopupMenuItem(
          value: 'report_user',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_off_outlined),
            title: Text('Report user'),
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.block_outlined, color: Colors.red),
            title: Text('Block user', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context, bool userReport) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Why are you reporting this?'),
              subtitle: Text('Reports are confidential and reviewed.'),
            ),
            for (final entry in const {
              'harassment': 'Harassment or bullying',
              'hate': 'Hate speech',
              'sexual': 'Sexual or child-safety concern',
              'violence': 'Violence or threats',
              'privacy': 'Private information',
              'misinformation': 'Dangerous misinformation',
              'spam': 'Spam or scam',
              'other': 'Other violation',
            }.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !context.mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UgcSafetyService.submitReport(
      reporterId: uid,
      targetType: userReport ? 'user' : targetType,
      targetId: userReport ? authorId : targetId,
      targetPath: userReport ? 'users/$authorId' : targetPath,
      authorId: authorId,
      reason: reason,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted for review.')),
      );
    }
  }

  Future<void> _block(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Block $authorName?'),
        content: const Text(
          'Their Forum questions, answers, and Stories will be hidden from you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UgcSafetyService.blockUser(
      uid: uid,
      blockedUid: authorId,
      blockedName: authorName,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$authorName has been blocked.')));
    }
  }
}
