import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../services.dart';

/// Wrapper widget that handles authentication routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.authProvider,
    required this.mapRepository,
    required this.routingService,
    required this.updatesService,
  });

  final AuthProvider authProvider;
  final MapRepository mapRepository;
  final RoutingService routingService;
  final UpdatesService updatesService;

  @override
  Widget build(BuildContext context) {
    // Listen to auth provider changes
    return ListenableBuilder(
      listenable: authProvider,
      builder: (context, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
              ),
            ),
          );
        }

        // If authenticated, show home screen
        if (authProvider.isAuthenticated) {
          return HomeScreen(
            mapRepository: mapRepository,
            routingService: routingService,
            updatesService: updatesService,
            authProvider: authProvider,
          );
        }

        // If not authenticated, show auth screen
        return AuthScreen(authProvider: authProvider);
      },
    );
  }
}
