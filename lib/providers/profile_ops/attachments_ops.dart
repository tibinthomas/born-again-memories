import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attachment.dart';
import '../../models/kid_profile.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin AttachmentsOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  void updateAttachmentLocalPath(String attachmentId, String newPath) {
    // Find which profile+milestone owns this attachment so we can persist to Firestore
    for (final profile in state ?? <KidProfile>[]) {
      for (final ms in profile.milestones) {
        if (ms.attachments.any((a) => a.id == attachmentId)) {
          final updatedMs = ms.copyWith(
            attachments: ms.attachments
                .map((a) => a.id == attachmentId ? a.copyWith(localPath: newPath) : a)
                .toList(),
          );
          unawaited(FirestoreService.saveMilestone(uid, profile.id, updatedMs));
          break;
        }
      }
    }
    state = (state ?? <KidProfile>[])
        .map((profile) => profile.copyWith(
              milestones: profile.milestones
                  .map((ms) => ms.copyWith(
                        attachments: ms.attachments
                            .map((a) =>
                                a.id == attachmentId ? a.copyWith(localPath: newPath) : a)
                            .toList(),
                      ))
                  .toList(),
            ))
        .toList();
  }

  void updateAttachmentBackupStatus(
    String profileId,
    String milestoneId,
    String attachmentId,
    BackupStatus status, {
    String? driveFileId,
    String? iCloudFileId,
  }) {
    state = (state ?? <KidProfile>[]).map((profile) {
      if (profile.id != profileId) return profile;
      return profile.copyWith(
        milestones: profile.milestones.map((ms) {
          if (ms.id != milestoneId) return ms;
          return ms.copyWith(
            attachments: ms.attachments.map((a) {
              if (a.id != attachmentId) return a;
              return a.copyWith(
                driveFileId: driveFileId,
                iCloudFileId: iCloudFileId,
                backupStatus: status,
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }
}
