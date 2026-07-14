import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/kid_profile.dart';

void main() {
  test('native profile image paths survive serialization', () {
    final profile = KidProfile(
      id: 'profile-1',
      name: 'Sam',
      dateOfBirth: DateTime(2024, 1, 1),
      color: Colors.blue,
      avatarImagePath: '/app/documents/avatars/avatar_profile-1_1.jpg',
      backgroundImagePath: '/app/documents/backgrounds/bg_profile-1_1.jpg',
    );

    final restored = KidProfile.fromJson(profile.toJson());

    expect(restored.avatarImagePath, profile.avatarImagePath);
    expect(restored.backgroundImagePath, profile.backgroundImagePath);
  });
}
