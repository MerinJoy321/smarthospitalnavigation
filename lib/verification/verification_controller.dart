import 'package:flutter/foundation.dart';
import '../state/navigation_state.dart';
import '../graph/graph_loader.dart';
import '../routing/dijkstra.dart';
import '../graph/cost_modifiers.dart';
import '../instructions/instruction_controller.dart';
import '../location/beacon_emitter.dart';

/// Verification result types
enum VerificationResult {
  confirmed,
  lost,
  autoVerified,
}

/// Controller for user verification and rerouting
class VerificationController {
  final NavigationState _state;
  final InstructionController _instructionController;
  final BeaconEmitter _beaconEmitter;

  /// Callback when verification happens
  void Function(VerificationResult result)? onVerification;

  /// Callback when rerouting happens
  void Function()? onReroute;

  VerificationController({
    required NavigationState state,
    required InstructionController instructionController,
    required BeaconEmitter beaconEmitter,
  })  : _state = state,
        _instructionController = instructionController,
        _beaconEmitter = beaconEmitter {
    // Listen for beacon events for auto-verification
    _beaconEmitter.addListener(_onNodeDetected);
  }

  void dispose() {
    _beaconEmitter.removeListener(_onNodeDetected);
  }

  /// Called when user taps "Done" button
  /// Called when user taps "Done" button
  void confirmInstruction() {
    debugPrint('VerificationController: Done pressed');
    
    // Get the current instruction to find the next node
    final instruction = _instructionController.currentInstruction;
    final prevNode = _state.currentNode;
    bool nodeChanged = false;

    if (instruction != null) {
      final nextNode = instruction['toNode'] as String?;
      if (nextNode != null && nextNode != prevNode) {
        // Update current position to the destination of this instruction
        _state.setCurrentNode(nextNode);
        debugPrint('VerificationController: Moved to node $nextNode');
        nodeChanged = true;
      }
    }
    
    // If the node changed, the RouteController has likely recalculated the route
    // and reset the instruction index to 0 (pointing to the NEXT step from the new node).
    // So we do NOT need to advance manually. 
    // We only advance manually if the node did NOT change (e.g., "Turn Left" at same node).
    
    if (!nodeChanged) {
      if (_instructionController.hasMoreInstructions) {
        // Advance to next instruction
        _instructionController.advanceToNext();
        debugPrint('VerificationController: Advanced to instruction ${_instructionController.currentIndex}');
        onVerification?.call(VerificationResult.confirmed);
      } else if (_instructionController.isComplete) {
        // Navigation complete
        debugPrint('VerificationController: Navigation complete!');
        onVerification?.call(VerificationResult.confirmed);
      }
    } else {
      // Node changed, just notify confirmed
       onVerification?.call(VerificationResult.confirmed);
    }
  }

  /// Called when user taps "I'm lost" button
  void reportLost() {
    debugPrint('VerificationController: User reported lost');
    
    // For now, we'll just trigger a state update that might cause re-routing if we had a "lost" state.
    // Since we don't have a "lost" state in NavigationState yet, we'll just log it.
    // In a real app, this might reset position to "unknown" or trigger a scan.
    
    // Changing position to null to force a reset might be one way, 
    // but without a scan it's hard to recover.
    // Let's just try to re-trigger routing by setting current node to itself if known.
    
    final currentNode = _state.currentNode;
    if (currentNode != null) {
      // This is a no-op state change but might help if we add a "force reroute" flag later.
      // Ideally, the user should be asked to scan a beacon.
      debugPrint('VerificationController: Staying at $currentNode, but reported lost.');
    }
    
    onVerification?.call(VerificationResult.lost);
  }

  /// Called when a beacon is detected
  void _onNodeDetected(String nodeId) {
    // Just update the current node. The RouteController and InstructionController
    // will handle the rest (re-routing, instruction updates, etc.)
    _state.setCurrentNode(nodeId);
    
    final expectedNode = _instructionController.expectedNextNode;
    if (expectedNode == nodeId) {
      debugPrint('VerificationController: Auto-verified at $nodeId');
      confirmInstruction();
      onVerification?.call(VerificationResult.autoVerified);
    }
  }

  /// Manually trigger a reroute (for recovery scenarios)
  void triggerReroute() {
    // No-op: RouteController handles this automatically on state change
  }

  /// Snap to nearest valid node and reroute
  void snapAndReroute(String nearestNodeId) {
    _state.setCurrentNode(nearestNodeId);
  }
}
