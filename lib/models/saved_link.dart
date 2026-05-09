class SavedLink {
  final String id;
  final String url;
  final String title;
  final String? description;
  final List<String> tags;
  final DateTime dateAdded;
  final String? previewTitle;
  final String? previewDescription;
  final String? previewImageUrl;
  final bool isFavorite;

  const SavedLink({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.tags = const [],
    required this.dateAdded,
    this.previewTitle,
    this.previewDescription,
    this.previewImageUrl,
    this.isFavorite = false,
  });

  String get domain {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Link';
    return uri.host.replaceFirst('www.', '');
  }

  SavedLink copyWith({
    String? title,
    String? url,
    String? description,
    List<String>? tags,
    DateTime? dateAdded,
    String? previewTitle,
    String? previewDescription,
    String? previewImageUrl,
    bool? isFavorite,
    bool clearDescription = false,
    bool clearPreviewDescription = false,
  }) =>
      SavedLink(
        id: id,
        url: url ?? this.url,
        title: title ?? this.title,
        description: clearDescription ? null : (description ?? this.description),
        tags: tags ?? this.tags,
        dateAdded: dateAdded ?? this.dateAdded,
        previewTitle: previewTitle ?? this.previewTitle,
        previewDescription: clearPreviewDescription ? null : (previewDescription ?? this.previewDescription),
        previewImageUrl: previewImageUrl ?? this.previewImageUrl,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        if (description != null) 'description': description,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
        if (previewTitle != null) 'previewTitle': previewTitle,
        if (previewDescription != null) 'previewDescription': previewDescription,
        if (previewImageUrl != null) 'previewImageUrl': previewImageUrl,
        if (isFavorite) 'isFavorite': isFavorite,
      };

  factory SavedLink.fromJson(Map<String, dynamic> j) => SavedLink(
        id: j['id'] as String,
        url: j['url'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        dateAdded: DateTime.parse(j['dateAdded'] as String),
        previewTitle: j['previewTitle'] as String?,
        previewDescription: j['previewDescription'] as String?,
        previewImageUrl: j['previewImageUrl'] as String?,
        isFavorite: (j['isFavorite'] as bool?) ?? false,
      );
}
