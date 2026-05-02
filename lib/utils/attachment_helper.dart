import '../models/attachment.dart';

AttachmentType getAttachmentTypeFromExtension(String extension) {
  final value = extension.toLowerCase();
  if (['jpg', 'jpeg', 'png'].contains(value)) return AttachmentType.image;
  if (['mp4', 'mov'].contains(value)) return AttachmentType.video;
  if (['wav', 'mp3', 'm4a', 'aac'].contains(value)) return AttachmentType.audio;
  return AttachmentType.other;
}
