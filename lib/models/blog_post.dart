class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> likedByUids;

  const BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.createdAt,
    this.tags = const [],
    this.likedByUids = const [],
  });

  int get likesCount => likedByUids.length;
  bool isLikedBy(String uid) => likedByUids.contains(uid);

  String get excerpt {
    final plain = content.trim();
    return plain.length > 160 ? '${plain.substring(0, 157)}…' : plain;
  }

  BlogPost copyWith({
    String? title,
    String? content,
    List<String>? tags,
    List<String>? likedByUids,
  }) =>
      BlogPost(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: createdAt,
        tags: tags ?? this.tags,
        likedByUids: likedByUids ?? this.likedByUids,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (tags.isNotEmpty) 'tags': tags,
        if (likedByUids.isNotEmpty) 'likedByUids': likedByUids,
      };

  factory BlogPost.fromJson(Map<String, dynamic> j) => BlogPost(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'Anonymous',
        authorPhotoUrl: j['authorPhotoUrl'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (j['createdAt'] as num).toInt()),
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        likedByUids:
            (j['likedByUids'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
