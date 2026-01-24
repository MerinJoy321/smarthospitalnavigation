import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// State
import 'state/navigation_state.dart';

// Graph & Location
import 'graph/graph_loader.dart';
import 'location/beacon_config.dart';
import 'location/beacon_emitter.dart';

// Routing & Instructions
import 'routing/route_controller.dart';
import 'instructions/instruction_controller.dart';

// Verification
import 'verification/verification_controller.dart';

// Demo
import 'demo/demo_controller.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const IndoorNavigationApp());
}

class IndoorNavigationApp extends StatelessWidget {
  const IndoorNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationState(),
      child: MaterialApp(
        title: 'Indoor Navigation',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, // More medical/accessible teal
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: const AppShell(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

/// Main app shell that manages navigation between screens
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isLoading = true;
  bool _isNavigating = false;
  String? _error;
  bool _isLoggedIn = false;

  // Controllers
  late BeaconEmitter _beaconEmitter;
  late RouteController _routeController;
  late InstructionController _instructionController;
  late VerificationController _verificationController;
  late DemoController _demoController;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final state = context.read<NavigationState>();

      // Initialize controllers
      _beaconEmitter = BeaconEmitter(state);
      _routeController = RouteController(state);
      _instructionController = InstructionController(state);
      _verificationController = VerificationController(
        state: state,
        instructionController: _instructionController,
        beaconEmitter: _beaconEmitter,
      );
      _demoController = DemoController(
        state: state,
        beaconEmitter: _beaconEmitter,
        instructionController: _instructionController,
      );

      // Load data
      await GraphLoader.loadGraph();
      await BeaconConfigLoader.loadBeacons();
      await _demoController.loadScenarios();

      // Initialize route controller
      _routeController.initialize();
      _instructionController.initialize();

      // Set initial position (simulate beacon detection at Main Entrance)
      _beaconEmitter.emitNodeDetected('F0_ENTRY');

      // Setup verification callbacks
      _verificationController.onVerification = (result) {
        if (result == VerificationResult.confirmed) {
          final state = context.read<NavigationState>();
          if (_instructionController.isComplete) {
            _showCompletionDialog();
          }
        }
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _instructionController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  void _startNavigation() {
    final state = context.read<NavigationState>();
    _routeController.recalculateRoute();
    _instructionController.generateInstructions();
    setState(() {
      _isNavigating = true;
    });
  }

  void _cancelNavigation() {
    setState(() {
      _isNavigating = false;
    });
  }

  void _onDonePressed() {
    _verificationController.confirmInstruction();
  }

  void _onNegativePressed() {
    _verificationController.verifyNegative();
  }

  void _onLostPressed() {
    _verificationController.reportLost();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Arrived!'),
          ],
        ),
        content: const Text('You have reached your destination.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isNavigating = false;
              });
              context.read<NavigationState>().resetNavigation();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.indigo,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Navigation System...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to initialize',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initializeApp();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }

    if (_isNavigating) {
      return NavigationScreen(
        onNavigationComplete: () => setState(() => _isNavigating = false),
        onNavigationCancelled: _cancelNavigation,
        onDonePressed: _onDonePressed,
        onNegativePressed: _onNegativePressed,
        onLostPressed: _onLostPressed,
        onNodeReconfirmed: (nodeId) {
          final state = context.read<NavigationState>();
          state.setCurrentNode(nodeId);
          // Force recalculation if same node to restart instructions
          if (state.currentNode == nodeId) {
            _routeController.recalculateRoute();
            _instructionController.generateInstructions();
          }
        },
      );
    }

    return HomeScreen(
      onNavigationStarted: _startNavigation,
    );
  }
}
