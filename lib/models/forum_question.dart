class ForumAnswer {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final bool edited;

  const ForumAnswer({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.createdAt,
    this.edited = false,
  });

  ForumAnswer copyWith({String? content, bool? edited}) => ForumAnswer(
        id: id,
        content: content ?? this.content,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: createdAt,
        edited: edited ?? this.edited,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (edited) 'edited': true,
      };

  factory ForumAnswer.fromJson(Map<String, dynamic> j) => ForumAnswer(
        id: j['id'] as String,
        content: j['content'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'Anonymous',
        authorPhotoUrl: j['authorPhotoUrl'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (j['createdAt'] as num).toInt()),
        edited: j['edited'] as bool? ?? false,
      );
}

class ForumQuestion {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final List<String> tags;
  final int answerCount;
  final bool edited;

  const ForumQuestion({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.createdAt,
    this.tags = const [],
    this.answerCount = 0,
    this.edited = false,
  });

  ForumQuestion copyWith({
    String? content,
    List<String>? tags,
    int? answerCount,
    bool? edited,
  }) =>
      ForumQuestion(
        id: id,
        content: content ?? this.content,
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: createdAt,
        tags: tags ?? this.tags,
        answerCount: answerCount ?? this.answerCount,
        edited: edited ?? this.edited,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (tags.isNotEmpty) 'tags': tags,
        'answerCount': answerCount,
        if (edited) 'edited': true,
      };

  factory ForumQuestion.fromJson(Map<String, dynamic> j) => ForumQuestion(
        id: j['id'] as String,
        content: j['content'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? 'Anonymous',
        authorPhotoUrl: j['authorPhotoUrl'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (j['createdAt'] as num).toInt()),
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        answerCount: (j['answerCount'] as num?)?.toInt() ?? 0,
        edited: j['edited'] as bool? ?? false,
      );
}
