enum ShareInviteStatus { pending, active, expired }

class ShareInvite {
  final String email;
  final DateTime sentAt;
  final ShareInviteStatus status;

  const ShareInvite({
    required this.email,
    required this.sentAt,
    required this.status,
  });

  bool get isActive => status == ShareInviteStatus.active;
  bool get isPending => status == ShareInviteStatus.pending;
  bool get isExpired => status == ShareInviteStatus.expired;

  ShareInvite copyWith({ShareInviteStatus? status, DateTime? sentAt}) =>
      ShareInvite(
        email: email,
        sentAt: sentAt ?? this.sentAt,
        status: status ?? this.status,
      );
}
