import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/milestone.dart';
import 'package:my_app/utils/milestone_sort.dart';

void main() {
  test(
    'memories are ordered newest first without changing the source list',
    () {
      final oldest = _milestone('oldest', DateTime(2025, 1, 1));
      final newest = _milestone('newest', DateTime(2026, 3, 1));
      final middle = _milestone('middle', DateTime(2025, 8, 15));
      final source = [oldest, newest, middle];

      final sorted = milestonesNewestFirst(source);

      expect(sorted.map((milestone) => milestone.id), [
        'newest',
        'middle',
        'oldest',
      ]);
      expect(source.map((milestone) => milestone.id), [
        'oldest',
        'newest',
        'middle',
      ]);
    },
  );
}

Milestone _milestone(String id, DateTime date) {
  return Milestone(
    id: id,
    title: id,
    description: '',
    date: date,
    color: Colors.blue,
  );
}
