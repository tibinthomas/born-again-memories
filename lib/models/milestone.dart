import 'package:flutter/material.dart';
import 'attachment.dart';

class Milestone {
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;

  Milestone({
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
  });
}
