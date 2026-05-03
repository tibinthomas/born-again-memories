import 'package:flutter/material.dart';
import 'attachment.dart';
import 'external_link.dart';

class Milestone {
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;
  final List<ExternalLink> externalLinks;

  Milestone({
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
    this.externalLinks = const [],
  });
}
