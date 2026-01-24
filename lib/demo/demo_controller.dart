import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../state/navigation_state.dart';
import '../location/beacon_emitter.dart';
import '../instructions/instruction_controller.dart';
import 'scenarios.dart';

/// Controller for managing demo scenarios
class DemoController {
  final NavigationState _state;
  final BeaconEmitter _beaconEmitter;
  final InstructionController _instructionController;
  
  List<DemoScenario>? _scenarios;

  DemoController({
    required NavigationState state,
    required BeaconEmitter beaconEmitter,
    required InstructionController instructionController,
  })  : _state = state,
        _beaconEmitter = beaconEmitter,
        _instructionController = instructionController;

  /// Load scenarios from JSON
  Future<List<DemoScenario>> loadScenarios() async {
    if (_scenarios != null) return _scenarios!;

    final String jsonString = await rootBundle.loadString('assets/data/scenarios.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> scenarioList = data['scenarios'];

    _scenarios = scenarioList.map((s) => DemoScenario.fromJson(s)).toList();
    return _scenarios!;
  }

  /// Get all available scenarios
  List<DemoScenario> get scenarios => _scenarios ?? [];

  /// Load and activate a specific scenario
  Future<void> activateScenario(DemoScenario scenario) async {
    // Set accessibility profile
    switch (scenario.accessibility) {
      case 'wheelchair':
        _state.setAccessibilityProfile(AccessibilityProfile.wheelchair);
        break;
      case 'assisted':
        _state.setAccessibilityProfile(AccessibilityProfile.assisted);
        break;
      default:
        _state.setAccessibilityProfile(AccessibilityProfile.normal);
    }

    // Set conditions
    final conditions = <ActiveCondition>{};
    for (final c in scenario.conditions) {
      switch (c) {
        case 'emergency':
          conditions.add(ActiveCondition.emergency);
          break;
        case 'maintenance':
          conditions.add(ActiveCondition.maintenance);
          break;
        case 'congestion':
          conditions.add(ActiveCondition.congestion);
          break;
        default:
          conditions.add(ActiveCondition.normal);
      }
    }
    _state.setActiveConditions(conditions);

    // Set current position
    _beaconEmitter.emitNodeDetected(scenario.startNode);

    // Set destination - this will trigger route calculation which will trigger instruction generation
    _state.setDestinationNode(scenario.destinationNode);
  }

  /// Activate scenario by ID
  Future<bool> activateScenarioById(String id) async {
    await loadScenarios();
    
    final scenario = _scenarios?.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Scenario not found: $id'),
    );

    if (scenario != null) {
      await activateScenario(scenario);
      return true;
    }
    return false;
  }

  /// Simulate walking through current route
  Future<void> simulateWalk({Duration delay = const Duration(seconds: 2)}) async {
    final route = _state.currentRoute;
    if (route.isEmpty) return;

    await _beaconEmitter.simulateWalk(route, delay: delay);
  }
}
