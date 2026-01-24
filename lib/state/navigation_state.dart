import 'package:flutter/foundation.dart';

/// Accessibility profiles for routing
enum AccessibilityProfile {
  normal,
  wheelchair,
  assisted,
}

/// Active condition presets
enum ActiveCondition {
  normal,
  emergency,
  maintenance,
  congestion,
  construction,
}

/// Global navigation state manager using ChangeNotifier
/// Single source of truth for all navigation-related state
class NavigationState extends ChangeNotifier {
  // Private state
  String? _currentNode;
  String? _destinationNode;
  AccessibilityProfile _accessibilityProfile = AccessibilityProfile.normal;
  Set<ActiveCondition> _activeConditions = {ActiveCondition.normal};
  int _currentInstructionIndex = 0;
  List<String> _currentRoute = [];
  List<Map<String, dynamic>> _instructions = [];

  // Getters
  String? get currentNode => _currentNode;
  String? get destinationNode => _destinationNode;
  AccessibilityProfile get accessibilityProfile => _accessibilityProfile;
  Set<ActiveCondition> get activeConditions => Set.unmodifiable(_activeConditions);
  int get currentInstructionIndex => _currentInstructionIndex;
  List<String> get currentRoute => List.unmodifiable(_currentRoute);
  List<Map<String, dynamic>> get instructions => List.unmodifiable(_instructions);
  
  /// True when navigation is actively in progress
  bool get isNavigating => _destinationNode != null && _currentRoute.isNotEmpty;

  // Setters with notification

  void setCurrentNode(String? nodeId) {
    if (_currentNode != nodeId) {
      _currentNode = nodeId;
      notifyListeners();
    }
  }

  void setDestinationNode(String? nodeId) {
    if (_destinationNode != nodeId) {
      _destinationNode = nodeId;
      _currentInstructionIndex = 0; // Reset on new destination
      notifyListeners();
    }
  }

  void setAccessibilityProfile(AccessibilityProfile profile) {
    if (_accessibilityProfile != profile) {
      _accessibilityProfile = profile;
      notifyListeners();
    }
  }

  void setActiveConditions(Set<ActiveCondition> conditions) {
    if (!setEquals(_activeConditions, conditions)) {
      _activeConditions = Set.from(conditions);
      notifyListeners();
    }
  }

  void addCondition(ActiveCondition condition) {
    if (_activeConditions.add(condition)) {
      notifyListeners();
    }
  }

  void removeCondition(ActiveCondition condition) {
    if (_activeConditions.remove(condition)) {
      notifyListeners();
    }
  }

  void setCurrentRoute(List<String> route) {
    _currentRoute = List.from(route);
    _currentInstructionIndex = 0;
    notifyListeners();
  }

  void setInstructions(List<Map<String, dynamic>> newInstructions) {
    _instructions = List.from(newInstructions);
    _currentInstructionIndex = 0;
    notifyListeners();
  }

  /// Insert an instruction at the current index (shifts current and subsequent forward)
  /// or at specific index if needed.
  void insertInstruction(Map<String, dynamic> instruction) {
    if (_instructions.isEmpty) {
      _instructions = [instruction];
      _currentInstructionIndex = 0;
    } else {
      // meaningful place: right now? or next?
      // Logic: If user says "No", we want to show a hint immediately.
      // So we insert at current index, pushing the current one to next?
      // Or we replace current?
      // Better: Insert at current index so it becomes the displayed one.
      _instructions.insert(_currentInstructionIndex, instruction);
      // do not increment index, as we want to see the new one.
    }
    notifyListeners();
  }

  /// Advance to next instruction
  /// Returns true if advanced, false if already at end
  bool advanceInstruction() {
    if (_currentInstructionIndex < _instructions.length - 1) {
      _currentInstructionIndex++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get current instruction or null if none
  Map<String, dynamic>? get currentInstruction {
    if (_instructions.isEmpty || _currentInstructionIndex >= _instructions.length) {
      return null;
    }
    return _instructions[_currentInstructionIndex];
  }

  /// Reset all navigation state
  void resetNavigation() {
    _destinationNode = null;
    _currentRoute = [];
    _instructions = [];
    _currentInstructionIndex = 0;
    notifyListeners();
  }

  /// Full reset including location
  void resetAll() {
    _currentNode = null;
    _destinationNode = null;
    _accessibilityProfile = AccessibilityProfile.normal;
    _activeConditions = {ActiveCondition.normal};
    _currentRoute = [];
    _instructions = [];
    _currentInstructionIndex = 0;
    notifyListeners();
  }
}
