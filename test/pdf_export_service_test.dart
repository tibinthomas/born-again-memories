import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/attachment.dart';
import 'package:my_app/models/kid_profile.dart';
import 'package:my_app/models/milestone.dart';
import 'package:my_app/services/pdf_export_service.dart';

void main() {
  test('includes Moment photo data when photos are enabled', () async {
    final directory = await Directory.systemTemp.createTemp('moment_pdf_test');
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/photo.png');
    await photo.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      ),
    );

    final milestone = Milestone(
      id: 'moment-1',
      title: 'First smile',
      description: 'A happy memory',
      date: DateTime(2025, 1, 2),
      color: Colors.blue,
      attachments: [
        Attachment(
          id: 'photo-1',
          name: 'photo.png',
          type: AttachmentType.image,
          sizeBytes: await photo.length(),
          localPath: photo.path,
        ),
      ],
    );
    final profile = KidProfile(
      id: 'profile-1',
      name: 'Sam',
      dateOfBirth: DateTime(2024, 1, 1),
      color: Colors.blue,
      milestones: [milestone],
    );

    final withPhotos = await PdfExportService.generateMemoryBook(
      profile: profile,
      milestones: [milestone],
      includePhotos: true,
    );
    final withoutPhotos = await PdfExportService.generateMemoryBook(
      profile: profile,
      milestones: [milestone],
      includePhotos: false,
    );

    expect(
      latin1.decode(withPhotos, allowInvalid: true),
      contains('/Subtype/Image'),
    );
    expect(
      latin1.decode(withoutPhotos, allowInvalid: true),
      isNot(contains('/Subtype/Image')),
    );
    expect(withPhotos.length, greaterThan(withoutPhotos.length));
  });
}
