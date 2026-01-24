import 'package:flutter/foundation.dart';
import '../state/navigation_state.dart';
import 'instruction_builder.dart';

/// Controls instruction progression and state
class InstructionController {
  final NavigationState _state;

  VoidCallback? _stateListener;
  List<String>? _lastKnownRoute;

  InstructionController(this._state);

  void initialize() {
    _stateListener = () => _onStateChanged();
    _state.addListener(_stateListener!);
  }

  void dispose() {
    if (_stateListener != null) {
      _state.removeListener(_stateListener!);
      _stateListener = null;
    }
  }

  void _onStateChanged() {
    // Check if route has changed
    if (!_listEquals(_lastKnownRoute, _state.currentRoute)) {
      _lastKnownRoute = List.from(_state.currentRoute);
      generateInstructions();
    }
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Generate instructions for the current route
  void generateInstructions() {
    final route = _state.currentRoute;
    if (route.isEmpty) {
      if (_state.instructions.isNotEmpty) {
        _state.setInstructions([]);
      }
      return;
    }
    
    debugPrint('InstructionController: Generating instructions for route of ${route.length} nodes');
    final instructions = InstructionBuilder.buildInstructions(route);
    _state.setInstructions(InstructionBuilder.toMapList(instructions));
  }

  /// Insert an intermediate instruction (hint)
  void insertIntermediateInstruction(String text) {
    debugPrint('InstructionController: Inserting intermediate hint: $text');
    final hint = {
      'text': text,
      'type': 'info', // Special type for hints
      'distanceEstimate': 0.0,
      'toNode': _state.currentNode, // Stay at current node logic
    };
    _state.insertInstruction(hint);
  }

  /// Get current instruction
  Map<String, dynamic>? get currentInstruction => _state.currentInstruction;

  /// Get current instruction index
  int get currentIndex => _state.currentInstructionIndex;

  /// Get total instruction count
  int get totalInstructions => _state.instructions.length;

  /// Check if there are more instructions
  bool get hasMoreInstructions => 
      _state.currentInstructionIndex < _state.instructions.length - 1;

  /// Check if navigation is complete
  bool get isComplete => 
      _state.instructions.isNotEmpty && 
      _state.currentInstructionIndex >= _state.instructions.length - 1;

  /// Advance to next instruction (only when verified)
  /// Returns true if advanced, false if at end
  bool advanceToNext() {
    if (!hasMoreInstructions) return false;
    return _state.advanceInstruction();
  }

  /// Get expected next node for current instruction
  String? get expectedNextNode {
    final instruction = currentInstruction;
    if (instruction == null) return null;
    return instruction['toNode'] as String?;
  }

  /// Check if current node matches expected
  bool isAtExpectedNode() {
    final expected = expectedNextNode;
    final current = _state.currentNode;
    if (expected == null || current == null) return false;
    return expected == current;
  }

  /// Get instruction type
  String? get currentInstructionType {
    return currentInstruction?['type'] as String?;
  }

  /// Get instruction text
  String? get currentInstructionText {
    return currentInstruction?['text'] as String?;
  }

  /// Get distance estimate
  double? get currentDistanceEstimate {
    return currentInstruction?['distanceEstimate'] as double?;
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (totalInstructions == 0) return 0;
    return currentIndex / totalInstructions;
  }
}
