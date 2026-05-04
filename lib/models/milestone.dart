import 'package:flutter/material.dart';
import 'attachment.dart';
import 'external_link.dart';

class Milestone {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;
  final List<ExternalLink> externalLinks;

  Milestone({
    String? id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
    this.externalLinks = const [],
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    Color? color,
    List<Attachment>? attachments,
    List<ExternalLink>? externalLinks,
  }) =>
      Milestone(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        color: color ?? this.color,
        attachments: attachments ?? this.attachments,
        externalLinks: externalLinks ?? this.externalLinks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'color': color.toARGB32(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'externalLinks': externalLinks.map((l) => l.toJson()).toList(),
      };

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        date: DateTime.parse(j['date'] as String),
        color: Color(j['color'] as int),
        attachments: (j['attachments'] as List? ?? [])
            .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
            .toList(),
        externalLinks: (j['externalLinks'] as List? ?? [])
            .map((l) => ExternalLink.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}
