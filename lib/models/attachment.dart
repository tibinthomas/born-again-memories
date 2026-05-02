enum AttachmentType { image, video, audio, other }

class Attachment {
  final String name;
  final String path;
  final AttachmentType type;

  Attachment({
    required this.name,
    required this.path,
    required this.type,
  });
}
