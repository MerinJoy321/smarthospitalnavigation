// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services.dart';

void main() {
  testWidgets('Hospital Navigator app loads correctly', (WidgetTester tester) async {
    // Create the required services
    final mapRepository = MapRepository();
    final routingService = RoutingService();
    final updatesService = UpdatesService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      HospitalNavigatorApp(
        mapRepository: mapRepository,
        routingService: routingService,
        updatesService: updatesService,
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('Smart Hospital Navigator'), findsOneWidget);
    
    // Verify that the home screen content is present
    expect(find.text('Find your way with confidence'), findsOneWidget);
  });
}
