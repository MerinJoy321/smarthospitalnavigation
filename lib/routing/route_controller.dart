import 'package:flutter/foundation.dart';
import '../state/navigation_state.dart';
import '../graph/graph_loader.dart';
import '../graph/cost_modifiers.dart';
import 'dijkstra.dart';

/// Route controller that manages route calculation and recalculation
class RouteController {
  final NavigationState _state;
  VoidCallback? _stateListener;

  RouteController(this._state);

  /// Initialize the controller and start listening for state changes
  void initialize() {
    _stateListener = () => _onStateChanged();
    _state.addListener(_stateListener!);
  }

  /// Dispose the controller
  void dispose() {
    if (_stateListener != null) {
      _state.removeListener(_stateListener!);
      _stateListener = null;
    }
  }

  /// Called when navigation state changes
  void _onStateChanged() {
    // Check if we need to recalculate
    if (_state.currentNode != null && _state.destinationNode != null) {
      // If we don't have a route, or the start/end doesn't match current state, recalculate
      if (_state.currentRoute.isEmpty || 
          _state.currentRoute.first != _state.currentNode || 
          _state.currentRoute.last != _state.destinationNode) {
        recalculateRoute();
      }
    }
  }

  /// Manually trigger route recalculation
  void recalculateRoute() {
    final currentNode = _state.currentNode;
    final destinationNode = _state.destinationNode;

    if (currentNode == null || destinationNode == null) {
      if (_state.currentRoute.isNotEmpty) {
        _state.setCurrentRoute([]);
      }
      return;
    }

    // Already at destination
    if (currentNode == destinationNode) {
      if (_state.currentRoute.length != 1 || _state.currentRoute.first != currentNode) {
        _state.setCurrentRoute([currentNode]);
      }
      return;
    }

    final graph = GraphLoader.graph;
    final costFn = CostModifiers.getCostFunction(
      _state.accessibilityProfile,
      _state.activeConditions,
    );

    debugPrint('RouteController: Calculating path from $currentNode to $destinationNode');
    final path = Dijkstra.findShortestPath(
      currentNode,
      destinationNode,
      graph,
      costFunction: costFn,
    );

    if (path.isEmpty) {
      debugPrint('RouteController: No path found');
      if (_state.currentRoute.isNotEmpty) {
        _state.setCurrentRoute([]);
      }
    } else {
      // Only update if path is different to avoid cycles
      if (!_listEquals(_state.currentRoute, path)) {
        debugPrint('RouteController: Path found with ${path.length} nodes');
        _state.setCurrentRoute(path);
      }
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

  /// Get remaining route from current position
  List<String> getRemainingRoute() {
    final route = _state.currentRoute;
    final currentNode = _state.currentNode;

    if (route.isEmpty || currentNode == null) return [];

    final currentIndex = route.indexOf(currentNode);
    if (currentIndex == -1) {
      // Current node not in route - need recalculation
      recalculateRoute();
      return _state.currentRoute;
    }

    return route.sublist(currentIndex);
  }

  /// Check if currently on route
  bool isOnRoute() {
    final route = _state.currentRoute;
    final currentNode = _state.currentNode;

    if (route.isEmpty || currentNode == null) return false;
    return route.contains(currentNode);
  }

  /// Get next node in route
  String? getNextNode() {
    final remaining = getRemainingRoute();
    if (remaining.length < 2) return null;
    return remaining[1];
  }
}
