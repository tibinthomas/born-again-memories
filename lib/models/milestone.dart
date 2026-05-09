import 'package:flutter/material.dart';
import 'attachment.dart';

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;
  final List<String> tags;
  final bool isFavorite;

  Milestone({
    String? id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
    this.tags = const [],
    this.isFavorite = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    Color? color,
    List<Attachment>? attachments,
    List<String>? tags,
    bool? isFavorite,
  }) =>
      Milestone(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        color: color ?? this.color,
        attachments: attachments ?? this.attachments,
        tags: tags ?? this.tags,
        isFavorite: isFavorite ?? this.isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'color': color.toARGB32(),
        'attachments': {for (final a in attachments) a.id: a.toJson()},
        if (tags.isNotEmpty) 'tags': tags,
        if (isFavorite) 'isFavorite': isFavorite,
      };

  factory Milestone.fromJson(Map<String, dynamic> j) {
    List<Attachment> parseAttachments() {
      final raw = j['attachments'];
      if (raw == null) return [];
      final items = raw is Map ? raw.values : (raw as List);
      return items
          .whereType<Map>()
          .map((a) => Attachment.fromJson(Map<String, dynamic>.from(a)))
          .toList();
    }

    return Milestone(
      id: j['id'] as String,
      title: j['title'] as String,
      description: j['description'] as String,
      date: DateTime.parse(j['date'] as String),
      color: Color(j['color'] as int),
      attachments: parseAttachments(),
      tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: (j['isFavorite'] as bool?) ?? false,
    );
  }
}
