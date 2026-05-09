import 'dart:typed_data';
import 'package:flutter/material.dart';

enum DocumentCategory { medical, vaccination, legal, insurance, education, other }

extension DocumentCategoryInfo on DocumentCategory {
  String get label => switch (this) {
        DocumentCategory.medical => 'Medical',
        DocumentCategory.vaccination => 'Vaccination',
        DocumentCategory.legal => 'Legal',
        DocumentCategory.insurance => 'Insurance',
        DocumentCategory.education => 'Education',
        DocumentCategory.other => 'Other',
      };

  String get emoji => switch (this) {
        DocumentCategory.medical => '🏥',
        DocumentCategory.vaccination => '💉',
        DocumentCategory.legal => '📜',
        DocumentCategory.insurance => '🛡️',
        DocumentCategory.education => '📚',
        DocumentCategory.other => '📄',
      };

  Color get color => switch (this) {
        DocumentCategory.medical => const Color(0xFF3B82F6),
        DocumentCategory.vaccination => const Color(0xFF2E9E6E),
        DocumentCategory.legal => const Color(0xFF8B5CF6),
        DocumentCategory.insurance => const Color(0xFFEC4899),
        DocumentCategory.education => const Color(0xFFF59E0B),
        DocumentCategory.other => const Color(0xFF6B7280),
      };
}

class BabyDocument {
  final String id;
  final String name;
  final String? notes;
  final DocumentCategory category;
  final DateTime dateAdded;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  // web-only, in-memory only — not serialized
  final Uint8List? webBytes;

  const BabyDocument({
    required this.id,
    required this.name,
    this.notes,
    required this.category,
    required this.dateAdded,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    this.webBytes,
  });

  String get fileExtension {
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  bool get isPdf => fileExtension == 'pdf';
  bool get isImage =>
      const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(fileExtension);
  bool get isAudio =>
      const {'mp3', 'wav', 'm4a', 'aac', 'ogg'}.contains(fileExtension);

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get typeIcon => isPdf
      ? Icons.picture_as_pdf_outlined
      : isImage
          ? Icons.image_outlined
          : isAudio
              ? Icons.audio_file_outlined
              : Icons.insert_drive_file_outlined;

  BabyDocument copyWith({
    String? name,
    String? notes,
    DocumentCategory? category,
    DateTime? dateAdded,
    String? localPath,
    String? mimeType,
    int? sizeBytes,
    Uint8List? webBytes,
    bool clearNotes = false,
  }) =>
      BabyDocument(
        id: id,
        name: name ?? this.name,
        notes: clearNotes ? null : notes ?? this.notes,
        category: category ?? this.category,
        dateAdded: dateAdded ?? this.dateAdded,
        localPath: localPath ?? this.localPath,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        webBytes: webBytes ?? this.webBytes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (notes != null) 'notes': notes,
        'category': category.name,
        'dateAdded': dateAdded.toIso8601String(),
        'localPath': localPath,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      };

  factory BabyDocument.fromJson(Map<String, dynamic> j) => BabyDocument(
        id: j['id'] as String,
        name: j['name'] as String,
        notes: j['notes'] as String?,
        category: DocumentCategory.values.firstWhere(
          (c) => c.name == (j['category'] as String? ?? 'other'),
          orElse: () => DocumentCategory.other,
        ),
        dateAdded: DateTime.parse(j['dateAdded'] as String),
        localPath: j['localPath'] as String? ?? '',
        mimeType: j['mimeType'] as String? ?? '',
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
      );
}
