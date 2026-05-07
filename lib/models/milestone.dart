import 'package:flutter/material.dart';
import 'attachment.dart';

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;

  Milestone({
    String? id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    Color? color,
    List<Attachment>? attachments,
  }) =>
      Milestone(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        color: color ?? this.color,
        attachments: attachments ?? this.attachments,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'color': color.toARGB32(),
        'attachments': {for (final a in attachments) a.id: a.toJson()},
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
    );
  }
}
