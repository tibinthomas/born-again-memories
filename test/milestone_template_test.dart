import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/milestone.dart';
import 'package:my_app/utils/milestone_templates.dart';

void main() {
  test('template key is stable across case and whitespace', () {
    const template = MilestoneTemplate(
      title: ' First   Smile ',
      description: 'A smile',
      emoji: '😊',
      category: ' First Weeks ',
    );

    expect(template.key, 'first weeks:first smile');
  });

  test('milestone template key survives serialization', () {
    final milestone = Milestone(
      id: 'memory-1',
      title: 'First Smile',
      description: 'A special smile',
      date: DateTime(2026, 1, 2),
      color: Colors.pink,
      templateKey: 'first weeks:first smile',
    );

    final restored = Milestone.fromJson(milestone.toJson());

    expect(restored.templateKey, milestone.templateKey);
  });
}
