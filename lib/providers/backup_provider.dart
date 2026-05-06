import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' show DriveApi;
import '../models/attachment.dart';
import '../services/database_service.dart';
import '../services/drive_service.dart';
import 'auth_provider.dart';
import 'profiles_provider.dart';

// ── Derived stats (computed from profiles state) ──────────────────────────────

class BackupStats {
  final int total;
  final int backedUp;
  final int pending;
  final int failed;

  const BackupStats({
    this.total = 0,
    this.backedUp = 0,
    this.pending = 0,
    this.failed = 0,
  });

  bool get allDone => total == 0 || backedUp == total;
}

final backupStatsProvider = Provider<BackupStats>((ref) {
  final profiles = ref.watch(profilesProvider);
  int total = 0, backedUp = 0, failed = 0;
  for (final p in profiles) {
    for (final m in p.milestones) {
      for (final a in m.attachments) {
        total++;
        if (a.backupStatus == BackupStatus.backedUp) backedUp++;
        if (a.backupStatus == BackupStatus.failed) failed++;
      }
    }
  }
  return BackupStats(
    total: total,
    backedUp: backedUp,
    pending: total - backedUp - failed,
    failed: failed,
  );
});

// ── Sync state (Drive quota, progress, last sync) ─────────────────────────────

class BackupSyncState {
  final bool isSyncing;
  final bool isRequestingAccess;
  final bool driveAccessGranted;
  final String? currentUploadName;
  final String? accessError;
  final DriveQuota? quota;
  final DateTime? lastSyncedAt;

  const BackupSyncState({
    this.isSyncing = false,
    this.isRequestingAccess = false,
    this.driveAccessGranted = false,
    this.currentUploadName,
    this.accessError,
    this.quota,
    this.lastSyncedAt,
  });

  BackupSyncState copyWith({
    bool? isSyncing,
    bool? isRequestingAccess,
    bool? driveAccessGranted,
    String? currentUploadName,
    String? accessError,
    DriveQuota? quota,
    DateTime? lastSyncedAt,
    bool clearCurrentUpload = false,
    bool clearError = false,
  }) =>
      BackupSyncState(
        isSyncing: isSyncing ?? this.isSyncing,
        isRequestingAccess: isRequestingAccess ?? this.isRequestingAccess,
        driveAccessGranted: driveAccessGranted ?? this.driveAccessGranted,
        currentUploadName:
            clearCurrentUpload ? null : currentUploadName ?? this.currentUploadName,
        accessError: clearError ? null : accessError ?? this.accessError,
        quota: quota ?? this.quota,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class BackupSyncNotifier extends StateNotifier<BackupSyncState> {
  final Ref _ref;
  bool _active = false;

  BackupSyncNotifier(this._ref) : super(const BackupSyncState()) {
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) return; // Drive API not available on web via this path
    await _loadCachedState();
    final gs = _ref.read(authServiceProvider).googleSignIn;
    final client = await gs.authenticatedClient();
    if (!mounted) return;
    state = state.copyWith(driveAccessGranted: client != null);
    if (client != null) _runSync();
  }

  // Called from settings — requests Drive scope, falls back to full re-auth.
  Future<void> grantAndSync() async {
    if (!mounted) return;
    state = state.copyWith(isRequestingAccess: true, clearError: true);

    try {
      final gs = _ref.read(authServiceProvider).googleSignIn;

      // Step 1: try lightweight scope request on existing session
      bool granted = false;
      try {
        granted = await gs.requestScopes([DriveApi.driveFileScope]);
      } catch (_) {}

      // Step 2: if that didn't work, trigger a full sign-in — the constructor
      //         scopes now include drive.file so the consent screen will show it.
      if (!granted) {
        try {
          final account = await gs.signIn();
          granted = account != null;
        } catch (_) {}
      }

      if (!mounted) return;

      if (!granted) {
        state = state.copyWith(
          isRequestingAccess: false,
          accessError: 'Drive access was not granted. Please try again.',
        );
        return;
      }

      // Verify we can actually get an authenticated client
      final client = await gs.authenticatedClient();
      if (!mounted) return;

      if (client == null) {
        state = state.copyWith(
          isRequestingAccess: false,
          accessError: 'Could not connect to Drive. Sign out and sign in again.',
        );
        return;
      }

      state = state.copyWith(
          driveAccessGranted: true, isRequestingAccess: false, clearError: true);
      _runSync();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isRequestingAccess: false,
          accessError: 'Something went wrong. Please try again.',
        );
      }
    }
  }

  // Public entry point — safe to call multiple times.
  Future<void> syncNow() => _runSync();

  Future<void> _runSync() async {
    if (_active || kIsWeb) return;
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    _active = true;
    if (mounted) state = state.copyWith(isSyncing: true);

    try {
      final authService = _ref.read(authServiceProvider);
      final profiles = _ref.read(profilesProvider);

      for (final profile in profiles) {
        for (final milestone in profile.milestones) {
          for (final attachment in milestone.attachments) {
            if (!mounted) return;
            if (attachment.backupStatus == BackupStatus.backedUp) continue;
            if (!attachment.localExists) continue;

            if (mounted) {
              state = state.copyWith(currentUploadName: attachment.name);
            }

            try {
              final fileId = await DriveService.uploadFile(
                googleSignIn: authService.googleSignIn,
                localPath: attachment.localPath,
                fileName: attachment.name,
                profileName: profile.name,
                milestoneId: milestone.id,
                type: attachment.type,
              );

              await DatabaseService.updateAttachmentBackup(
                uid: uid,
                profileId: profile.id,
                milestoneId: milestone.id,
                attachmentId: attachment.id,
                driveFileId: fileId,
                status: BackupStatus.backedUp,
              );

              _ref.read(profilesProvider.notifier).updateAttachmentBackupStatus(
                    profile.id,
                    milestone.id,
                    attachment.id,
                    fileId,
                    BackupStatus.backedUp,
                  );
            } on DriveNotAuthorizedException {
              // Stop processing — user revoked access
              if (mounted) {
                state = state.copyWith(
                    driveAccessGranted: false, clearCurrentUpload: true);
              }
              return;
            } catch (_) {
              await DatabaseService.updateAttachmentBackup(
                uid: uid,
                profileId: profile.id,
                milestoneId: milestone.id,
                attachmentId: attachment.id,
                driveFileId: null,
                status: BackupStatus.failed,
              );
              _ref.read(profilesProvider.notifier).updateAttachmentBackupStatus(
                    profile.id, milestone.id, attachment.id, null, BackupStatus.failed);
            }
          }
        }
      }

      // Refresh Drive quota after sync
      final quota =
          await DriveService.getQuota(authService.googleSignIn);
      final now = DateTime.now();
      if (quota != null) {
        await DatabaseService.updateDriveStats(uid, {
          'driveUsedBytes': quota.usedBytes,
          'driveLimitBytes': quota.limitBytes ?? 0,
          'lastSyncedAt': now.millisecondsSinceEpoch,
        });
      }
      if (mounted) {
        state = state.copyWith(
          quota: quota,
          lastSyncedAt: now,
          isSyncing: false,
          clearCurrentUpload: true,
        );
      }
    } finally {
      _active = false;
      if (mounted) state = state.copyWith(isSyncing: false, clearCurrentUpload: true);
    }
  }

  Future<void> _loadCachedState() async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final data = await DatabaseService.getDriveStats(uid);
    if (data == null || !mounted) return;

    DriveQuota? quota;
    final used = (data['driveUsedBytes'] as num?)?.toInt();
    if (used != null) {
      final limit = (data['driveLimitBytes'] as num?)?.toInt();
      quota = DriveQuota(
          usedBytes: used, limitBytes: (limit == 0) ? null : limit);
    }

    DateTime? lastSync;
    final ts = data['lastSyncedAt'];
    if (ts != null) {
      lastSync = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());
    }

    state = state.copyWith(quota: quota, lastSyncedAt: lastSync);
  }
}

final backupSyncProvider =
    StateNotifierProvider<BackupSyncNotifier, BackupSyncState>((ref) {
  return BackupSyncNotifier(ref);
});
