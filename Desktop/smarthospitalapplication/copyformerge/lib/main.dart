import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'services.dart';
import 'services/digital_twin_service.dart';
import 'services/admin_auth_service.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final mapRepository = MapRepository();
  final digitalTwinService = DigitalTwinService();
  final routingService = RoutingService(
    mapRepository: mapRepository,
    digitalTwinService: digitalTwinService,
  );
  final updatesService = UpdatesService();
  final authProvider = AuthProvider();
  final adminAuthService = AdminAuthService();

  // Initialize admin auth
  await adminAuthService.initialize();

  runApp(
    HospitalNavigatorApp(
      mapRepository: mapRepository,
      routingService: routingService,
      updatesService: updatesService,
      authProvider: authProvider,
      digitalTwinService: digitalTwinService,
      adminAuthService: adminAuthService,
    ),
  );
}

class HospitalNavigatorApp extends StatefulWidget {
  const HospitalNavigatorApp({
    super.key,
    required this.mapRepository,
    required this.routingService,
    required this.updatesService,
    required this.authProvider,
    required this.digitalTwinService,
    required this.adminAuthService,
  });

  final MapRepository mapRepository;
  final RoutingService routingService;
  final UpdatesService updatesService;
  final AuthProvider authProvider;
  final DigitalTwinService digitalTwinService;
  final AdminAuthService adminAuthService;

  @override
  State<HospitalNavigatorApp> createState() => _HospitalNavigatorAppState();
}

class _HospitalNavigatorAppState extends State<HospitalNavigatorApp> {
  // Track current app mode
  AppMode _currentMode = AppMode.userAuth;

  @override
  void initState() {
    super.initState();
    // Check if admin is already logged in
    if (widget.adminAuthService.isAuthenticated) {
      _currentMode = AppMode.adminDashboard;
    }
  }

  void _switchToAdminLogin() {
    setState(() {
      _currentMode = AppMode.adminAuth;
    });
  }

  void _switchToUserAuth() {
    setState(() {
      _currentMode = AppMode.userAuth;
    });
  }

  void _onAdminLoginSuccess() {
    setState(() {
      _currentMode = AppMode.adminDashboard;
    });
  }

  void _onAdminLogout() {
    setState(() {
      _currentMode = AppMode.userAuth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Hospital Navigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_currentMode) {
      case AppMode.userAuth:
        return _UserAuthWrapper(
          authProvider: widget.authProvider,
          mapRepository: widget.mapRepository,
          routingService: widget.routingService,
          updatesService: widget.updatesService,
          digitalTwinService: widget.digitalTwinService,
          onAdminLogin: _switchToAdminLogin,
        );
      case AppMode.adminAuth:
        return AdminLoginScreen(
          adminAuthService: widget.adminAuthService,
          onLoginSuccess: _onAdminLoginSuccess,
          onBackToUser: _switchToUserAuth,
        );
      case AppMode.adminDashboard:
        return AdminDashboardScreen(
          digitalTwinService: widget.digitalTwinService,
          adminAuthService: widget.adminAuthService,
          mapRepository: widget.mapRepository,
          onLogout: _onAdminLogout,
        );
    }
  }
}

enum AppMode {
  userAuth,
  adminAuth,
  adminDashboard,
}

/// User authentication and home wrapper
class _UserAuthWrapper extends StatelessWidget {
  const _UserAuthWrapper({
    required this.authProvider,
    required this.mapRepository,
    required this.routingService,
    required this.updatesService,
    required this.digitalTwinService,
    required this.onAdminLogin,
  });

  final AuthProvider authProvider;
  final MapRepository mapRepository;
  final RoutingService routingService;
  final UpdatesService updatesService;
  final DigitalTwinService digitalTwinService;
  final VoidCallback onAdminLogin;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authProvider,
      builder: (context, _) {
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

        if (authProvider.isAuthenticated) {
          return ListenableBuilder(
            listenable: digitalTwinService,
            builder: (context, _) {
              return HomeScreen(
                mapRepository: mapRepository,
                routingService: routingService,
                updatesService: updatesService,
                authProvider: authProvider,
                digitalTwinService: digitalTwinService,
              );
            },
          );
        }

        return AuthScreen(
          authProvider: authProvider,
          onAdminLogin: onAdminLogin,
        );
      },
    );
  }
}
