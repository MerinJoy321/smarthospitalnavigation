// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_hospital_navigator/main.dart';
import 'package:smart_hospital_navigator/services.dart';
import 'package:smart_hospital_navigator/providers/auth_provider.dart';
import 'package:smart_hospital_navigator/services/digital_twin_service.dart';
import 'package:smart_hospital_navigator/services/admin_auth_service.dart';

void main() {
  testWidgets('Hospital Navigator app loads correctly',
      (WidgetTester tester) async {
    // Create the required services
    final mapRepository = MapRepository();
    final digitalTwinService = DigitalTwinService();
    final routingService = RoutingService(
      mapRepository: mapRepository,
      digitalTwinService: digitalTwinService,
    );
    final updatesService = UpdatesService();
    final authProvider = AuthProvider();
    final adminAuthService = AdminAuthService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      HospitalNavigatorApp(
        mapRepository: mapRepository,
        routingService: routingService,
        updatesService: updatesService,
        authProvider: authProvider,
        digitalTwinService: digitalTwinService,
        adminAuthService: adminAuthService,
      ),
    );

    // Wait for the app to settle
    await tester.pump();

    // Verify that the app loads (auth screen should be displayed)
    expect(find.text('Smart Hospital Navigator'), findsOneWidget);
  });
}
