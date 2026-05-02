// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('Baby Milestones app launches and shows profile', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BabyMilestonesApp());

    // Verify that the app shows a kid profile
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('Baby Milestones'), findsNothing); // Title no longer appears
  });
}
