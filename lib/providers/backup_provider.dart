import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' show DriveApi;
import '../models/attachment.dart';
import '../services/drive_service.dart';
import '../services/firestore_service.dart';
import '../services/icloud_service.dart';
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
  final profiles = ref.watch(profilesProvider) ?? [];
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

// ── Sync state ────────────────────────────────────────────────────────────────

class BackupSyncState {
  final bool isSyncing;
  final bool isRequestingAccess;
  final bool driveAccessGranted;
  final bool iCloudAccessGranted;
  final String? currentUploadName;
  final String? accessError;
  final String? syncError;
  final DriveQuota? quota;
  final DateTime? lastSyncedAt;

  const BackupSyncState({
    this.isSyncing = false,
    this.isRequestingAccess = false,
    this.driveAccessGranted = false,
    this.iCloudAccessGranted = false,
    this.currentUploadName,
    this.accessError,
    this.syncError,
    this.quota,
    this.lastSyncedAt,
  });

  bool get cloudAccessGranted => driveAccessGranted || iCloudAccessGranted;

  BackupSyncState copyWith({
    bool? isSyncing,
    bool? isRequestingAccess,
    bool? driveAccessGranted,
    bool? iCloudAccessGranted,
    String? currentUploadName,
    String? accessError,
    String? syncError,
    DriveQuota? quota,
    DateTime? lastSyncedAt,
    bool clearCurrentUpload = false,
    bool clearError = false,
    bool clearSyncError = false,
  }) =>
      BackupSyncState(
        isSyncing: isSyncing ?? this.isSyncing,
        isRequestingAccess: isRequestingAccess ?? this.isRequestingAccess,
        driveAccessGranted: driveAccessGranted ?? this.driveAccessGranted,
        iCloudAccessGranted: iCloudAccessGranted ?? this.iCloudAccessGranted,
        currentUploadName:
            clearCurrentUpload ? null : currentUploadName ?? this.currentUploadName,
        accessError: clearError ? null : accessError ?? this.accessError,
        syncError: clearSyncError ? null : syncError ?? this.syncError,
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
    if (kIsWeb) return;
    await _loadCachedState();

    final authService = _ref.read(authServiceProvider);

    if (authService.isAppleUser) {
      // iCloud: user must have previously enabled it (persisted in Firestore).
      // state.iCloudAccessGranted is loaded by _loadCachedState.
      if (!state.iCloudAccessGranted) return;
      final available = await ICloudService.isAvailable();
      if (!mounted) return;
      if (!available) {
        state = state.copyWith(
          iCloudAccessGranted: false,
          syncError: 'iCloud is not available. Please check your iCloud settings.',
        );
        return;
      }
      _runSync();
    } else {
      final gs = authService.googleSignIn;
      final client = await gs.authenticatedClient();
      if (!mounted) return;

      bool driveGranted = false;
      if (client != null) {
        try {
          driveGranted = await gs.canAccessScopes([DriveApi.driveFileScope]);
        } catch (_) {
          driveGranted = false;
        }
      }

      state = state.copyWith(driveAccessGranted: driveGranted);
      if (driveGranted) _runSync();
    }
  }

  // Called from settings — grants cloud access, then starts sync.
  Future<void> grantAndSync() async {
    if (!mounted) return;
    state = state.copyWith(isRequestingAccess: true, clearError: true);

    final authService = _ref.read(authServiceProvider);

    if (authService.isAppleUser) {
      try {
        final available = await ICloudService.isAvailable();
        if (!mounted) return;
        if (!available) {
          state = state.copyWith(
            isRequestingAccess: false,
            accessError:
                'iCloud is not available. Please sign in to iCloud in your device Settings.',
          );
          return;
        }
        // Persist the user's choice to enable iCloud backup.
        final uid = _ref.read(authStateProvider).value?.uid;
        if (uid != null) {
          await FirestoreService.updateUserDoc(uid, {'iCloudBackupEnabled': true});
        }
        if (!mounted) return;
        state = state.copyWith(
          iCloudAccessGranted: true,
          isRequestingAccess: false,
          clearError: true,
        );
        _runSync();
      } catch (e, st) {
        debugPrint('[BackupSync] iCloud grantAndSync error: $e\n$st');
        if (mounted) {
          state = state.copyWith(
            isRequestingAccess: false,
            accessError: e.toString(),
          );
        }
      }
    } else {
      try {
        final gs = authService.googleSignIn;

        bool granted = false;
        String? scopeError;
        try {
          granted = await gs.requestScopes([DriveApi.driveFileScope]);
        } catch (e, st) {
          scopeError = e.toString();
          debugPrint('[BackupSync] requestScopes error: $e\n$st');
        }

        if (!granted) {
          try {
            final account = await gs.signIn();
            granted = account != null;
            if (granted) scopeError = null;
          } catch (e, st) {
            scopeError ??= e.toString();
            debugPrint('[BackupSync] signIn error: $e\n$st');
          }
        }

        if (!mounted) return;

        if (!granted) {
          final msg = scopeError != null
              ? 'Drive access not granted.\n$scopeError'
              : 'Drive access was not granted. Please try again.';
          state = state.copyWith(isRequestingAccess: false, accessError: msg);
          return;
        }

        if (!mounted) return;

        try {
          await gs.currentUser?.authentication;
        } catch (_) {}

        if (!mounted) return;

        state = state.copyWith(
            driveAccessGranted: true, isRequestingAccess: false, clearError: true);
        _runSync();
      } catch (e, st) {
        debugPrint('[BackupSync] grantAndSync error: $e\n$st');
        if (mounted) {
          state = state.copyWith(
            isRequestingAccess: false,
            accessError: e.toString(),
          );
        }
      }
    }
  }

  Future<void> syncNow() => _runSync();

  Future<void> _runSync() async {
    if (_active || kIsWeb) return;
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    _active = true;
    if (mounted) state = state.copyWith(isSyncing: true, clearSyncError: true);

    String? firstError;

    try {
      final authService = _ref.read(authServiceProvider);
      final isApple = authService.isAppleUser;
      final profiles = _ref.read(profilesProvider) ?? [];

      for (final profile in profiles) {
        for (final milestone in profile.milestones) {
          for (final attachment in milestone.attachments) {
            if (!mounted) return;
            if (attachment.backupStatus == BackupStatus.backedUp) continue;
            if (!attachment.localExists) {
              debugPrint('[BackupSync] skipping "${attachment.name}" — file not found at ${attachment.localPath}');
              continue;
            }

            if (mounted) {
              state = state.copyWith(currentUploadName: attachment.name);
            }

            try {
              if (isApple) {
                debugPrint('[BackupSync] iCloud uploading "${attachment.name}"');
                final relativePath = await ICloudService.uploadFile(
                  localPath: attachment.localPath,
                  fileName: attachment.name,
                  profileName: profile.name,
                  milestoneId: milestone.id,
                  type: attachment.type,
                );
                debugPrint('[BackupSync] iCloud uploaded "${attachment.name}" → $relativePath');

                await FirestoreService.updateAttachmentBackup(
                  uid: uid,
                  profileId: profile.id,
                  milestoneId: milestone.id,
                  attachmentId: attachment.id,
                  driveFileId: null,
                  iCloudFileId: relativePath,
                  status: BackupStatus.backedUp,
                );

                _ref.read(profilesProvider.notifier).updateAttachmentBackupStatus(
                      profile.id,
                      milestone.id,
                      attachment.id,
                      BackupStatus.backedUp,
                      iCloudFileId: relativePath,
                    );
              } else {
                debugPrint('[BackupSync] Drive uploading "${attachment.name}" from ${attachment.localPath}');
                final fileId = await DriveService.uploadFile(
                  googleSignIn: authService.googleSignIn,
                  localPath: attachment.localPath,
                  fileName: attachment.name,
                  profileName: profile.name,
                  milestoneId: milestone.id,
                  type: attachment.type,
                );
                debugPrint('[BackupSync] Drive uploaded "${attachment.name}" → driveId=$fileId');

                await FirestoreService.updateAttachmentBackup(
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
                      BackupStatus.backedUp,
                      driveFileId: fileId,
                    );
              }
            } on ICloudNotAvailableException {
              debugPrint('[BackupSync] ICloudNotAvailableException on "${attachment.name}" — stopping sync');
              if (mounted) {
                state = state.copyWith(
                  iCloudAccessGranted: false,
                  clearCurrentUpload: true,
                  syncError: 'iCloud access lost. Tap "Enable iCloud Backup" to reconnect.',
                );
              }
              return;
            } on DriveNotAuthorizedException {
              debugPrint('[BackupSync] DriveNotAuthorizedException on "${attachment.name}" — stopping sync');
              if (mounted) {
                state = state.copyWith(
                  driveAccessGranted: false,
                  clearCurrentUpload: true,
                  syncError: 'Drive access revoked. Tap "Enable Drive Backup" to reconnect.',
                );
              }
              return;
            } catch (e, st) {
              final detail = '"${attachment.name}": ${e.runtimeType}: $e';
              debugPrint('[BackupSync] upload failed — $detail\n$st');
              firstError ??= detail;
              try {
                await FirestoreService.updateAttachmentBackup(
                  uid: uid,
                  profileId: profile.id,
                  milestoneId: milestone.id,
                  attachmentId: attachment.id,
                  driveFileId: null,
                  status: BackupStatus.failed,
                );
              } catch (fe, fst) {
                debugPrint('[BackupSync] Firestore status update failed: $fe\n$fst');
              }
              _ref.read(profilesProvider.notifier).updateAttachmentBackupStatus(
                    profile.id, milestone.id, attachment.id, BackupStatus.failed);
            }
          }
        }
      }

      // Drive quota refresh (skip for iCloud — no accessible quota API).
      DriveQuota? quota;
      DateTime? now;
      try {
        if (!isApple) {
          quota = await DriveService.getQuota(authService.googleSignIn);
          debugPrint('[BackupSync] quota: used=${quota?.usedBytes} limit=${quota?.limitBytes}');
        }
        now = DateTime.now();
        await FirestoreService.updateUserDoc(uid, {
          if (quota != null) 'driveUsedBytes': quota.usedBytes,
          if (quota != null) 'driveLimitBytes': quota.limitBytes ?? 0,
          'lastSyncedAt': now.millisecondsSinceEpoch,
        });
      } catch (e, st) {
        debugPrint('[BackupSync] post-sync update failed: $e\n$st');
        now ??= DateTime.now();
      }

      if (mounted) {
        state = state.copyWith(
          quota: quota,
          lastSyncedAt: now,
          isSyncing: false,
          clearCurrentUpload: true,
          syncError: firstError,
        );
      }
    } catch (e, st) {
      debugPrint('[BackupSync] unexpected sync error: $e\n$st');
      if (mounted) {
        state = state.copyWith(
          isSyncing: false,
          clearCurrentUpload: true,
          syncError: '${e.runtimeType}: $e',
        );
      }
    } finally {
      _active = false;
      if (mounted && state.isSyncing) {
        state = state.copyWith(isSyncing: false, clearCurrentUpload: true);
      }
    }
  }

  Future<void> _loadCachedState() async {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final data = await FirestoreService.getUserDoc(uid);
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

    final iCloudEnabled = data['iCloudBackupEnabled'] as bool? ?? false;

    state = state.copyWith(
      quota: quota,
      lastSyncedAt: lastSync,
      iCloudAccessGranted: iCloudEnabled,
    );
  }
}

final backupSyncProvider =
    StateNotifierProvider<BackupSyncNotifier, BackupSyncState>((ref) {
  return BackupSyncNotifier(ref);
});
