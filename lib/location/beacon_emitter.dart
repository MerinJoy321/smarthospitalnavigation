import '../state/navigation_state.dart';
import 'beacon_config.dart';

/// Simulated beacon event emitter
/// In production, this would integrate with real BLE beacon hardware
class BeaconEmitter {
  final NavigationState _navigationState;
  
  /// Listeners for beacon detection events
  final List<void Function(String nodeId)> _listeners = [];

  BeaconEmitter(this._navigationState);

  /// Emit a simulated beacon detection event
  /// This updates the navigation state and notifies listeners
  void emitNodeDetected(String nodeId) {
    // Update the navigation state
    _navigationState.setCurrentNode(nodeId);
    
    // Notify all listeners
    for (final listener in _listeners) {
      listener(nodeId);
    }
  }

  /// Emit beacon detection by beacon ID (looks up node ID)
  Future<bool> emitBeaconDetected(String beaconId) async {
    final beacon = BeaconConfigLoader.getByBeaconId(beaconId);
    if (beacon != null) {
      emitNodeDetected(beacon.nodeId);
      return true;
    }
    return false;
  }

  /// Add a listener for beacon events
  void addListener(void Function(String nodeId) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(void Function(String nodeId) listener) {
    _listeners.remove(listener);
  }

  /// Simulate walking through a sequence of nodes (for demo)
  Future<void> simulateWalk(List<String> nodeSequence, {Duration delay = const Duration(seconds: 2)}) async {
    for (final nodeId in nodeSequence) {
      await Future.delayed(delay);
      emitNodeDetected(nodeId);
    }
  }
}
