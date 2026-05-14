import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/backup_provider.dart';
import 'settings_card.dart';

String _fmtBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  if (bytes < 1024 * 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return mb >= 100 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class BackupCard extends StatelessWidget {
  final Color accent;
  final BackupSyncState sync;
  final BackupStats stats;
  final VoidCallback onGrantAndSync;
  final VoidCallback onSyncNow;

  const BackupCard({
    super.key,
    required this.accent,
    required this.sync,
    required this.stats,
    required this.onGrantAndSync,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    String lastSync = 'Never';
    if (sync.lastSyncedAt != null) {
      final d = DateTime.now().difference(sync.lastSyncedAt!);
      if (d.inMinutes < 1) lastSync = 'Just now';
      else if (d.inHours < 1) lastSync = '${d.inMinutes}m ago';
      else if (d.inDays < 1) lastSync = '${d.inHours}h ago';
      else lastSync = '${d.inDays}d ago';
    }

    return SettingsCard(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, accent, 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    sync.driveAccessGranted
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sync.isSyncing
                            ? 'Backing up…'
                            : sync.driveAccessGranted
                                ? (stats.allDone ? 'All backed up' : '${stats.backedUp} of ${stats.total} files')
                                : 'Google Drive',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E)),
                      ),
                      if (sync.driveAccessGranted)
                        Text(
                          'Last backup: $lastSync',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                if (sync.driveAccessGranted)
                  GestureDetector(
                    onTap: sync.isSyncing ? null : onSyncNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.lerp(Colors.white, accent, 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withAlpha(60)),
                      ),
                      child: sync.isSyncing
                          ? SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                          : Text(
                              'Sync',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                            ),
                    ),
                  ),
              ],
            ),
            if (sync.driveAccessGranted && stats.total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.backedUp / stats.total,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
            if (sync.driveAccessGranted) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Files are stored in "⚠️ Born Again Memories — App Data (Do Not Delete)" in your Google Drive. Do not rename or delete this folder — doing so will break backup and may cause data loss.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            if (!sync.driveAccessGranted) ...[
              const SizedBox(height: 12),
              Text(
                'Back up photos and videos to Google Drive.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (sync.accessError != null) ...[
                const SizedBox(height: 4),
                Text(sync.accessError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: sync.isRequestingAccess ? null : onGrantAndSync,
                  icon: sync.isRequestingAccess
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload, size: 16),
                  label: Text(sync.isRequestingAccess ? 'Requesting…' : 'Enable Drive Backup'),
                ),
              ),
            ],
            if (sync.driveAccessGranted && sync.quota != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.storage_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${_fmtBytes(sync.quota!.usedBytes)}'
                  '${sync.quota!.limitBytes != null ? ' / ${_fmtBytes(sync.quota!.limitBytes!)}' : ''} used',
                  style: TextStyle(
                    fontSize: 11,
                    color: sync.quota!.isNearlyFull ? Colors.orange : Colors.grey.shade400,
                  ),
                ),
              ]),
            ],
            if (sync.syncError != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade500),
                        const SizedBox(width: 5),
                        Text(
                          '${stats.failed > 0 ? "${stats.failed} file${stats.failed == 1 ? "" : "s"} failed — " : ""}Backup error',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      sync.syncError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (stats.failed > 0) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${stats.failed} failed — tap Sync to retry',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
              ]),
            ],
          ],
        ),
      ),
    ]);
  }
}
