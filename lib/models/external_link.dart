class ExternalLink {
  final String url;
  final String? label;

  ExternalLink({required this.url, this.label});

  Map<String, dynamic> toJson() => {
        'url': url,
        if (label != null) 'label': label,
      };

  factory ExternalLink.fromJson(Map<String, dynamic> j) =>
      ExternalLink(url: j['url'] as String, label: j['label'] as String?);
}
