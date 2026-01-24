// This is a basic Flutter widget test for Indoor Navigation app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IndoorNavigationApp());

    // Verify that the app loads
    expect(find.text('Indoor Navigation'), findsOneWidget);
  });
}
