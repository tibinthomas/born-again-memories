import 'package:flutter/material.dart';
import '../../../models/share_invite.dart';
import 'settings_card.dart';

class ShareCard extends StatelessWidget {
  final Color accent;
  final List<ShareInvite> invites;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onResend;

  const ShareCard({
    super.key,
    required this.accent,
    required this.invites,
    required this.onAdd,
    required this.onRemove,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(children: [
      if (invites.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text('Not shared with anyone yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        )
      else
        ...invites.map((invite) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InviteRow(
                  invite: invite,
                  accent: accent,
                  onRemove: () => onRemove(invite.email),
                  onResend: () => onResend(invite.email),
                ),
                settingsDivider(),
              ],
            )),
      // Add button
      GestureDetector(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                'Add Gmail address',
                style: TextStyle(
                    fontSize: 13, color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class InviteRow extends StatelessWidget {
  final ShareInvite invite;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onResend;

  const InviteRow({
    super.key,
    required this.invite,
    required this.accent,
    required this.onRemove,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeIcon, badgeLabel) = switch (invite.status) {
      ShareInviteStatus.active => (
          const Color(0xFF27AE60),
          const Color(0xFFEAF7EF),
          Icons.check_circle_rounded,
          'Active',
        ),
      ShareInviteStatus.pending => (
          const Color(0xFFE67E22),
          const Color(0xFFFEF3E2),
          Icons.schedule_rounded,
          'Pending',
        ),
      ShareInviteStatus.expired => (
          Colors.red.shade400,
          Colors.red.shade50,
          Icons.error_outline_rounded,
          'Expired',
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar initial
              CircleAvatar(
                radius: 16,
                backgroundColor: Color.lerp(Colors.white, accent, 0.14),
                child: Text(
                  invite.email[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.email,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 11, color: badgeColor),
                              const SizedBox(width: 3),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor),
                              ),
                            ],
                          ),
                        ),
                        if (invite.isActive) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Viewing your memories',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ] else if (invite.isPending) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Waiting for them to sign up',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (invite.isExpired)
                GestureDetector(
                  onTap: onResend,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.white, accent, 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withAlpha(60)),
                    ),
                    child: Text(
                      'Resend',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.remove_circle_outline_rounded,
                    size: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
          // Expired explanation
          if (invite.isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This invite expired after 30 days. Tap Resend to refresh it.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
