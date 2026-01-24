import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/navigation_state.dart';
import '../views/three_d/navigation_visualizer.dart';
import '../views/maps/floor_map_view.dart';
import '../graph/graph_loader.dart';

/// Active navigation screen with 3D view, map, and instructions
class NavigationScreen extends StatefulWidget {
  final VoidCallback? onNavigationComplete;
  final VoidCallback? onNavigationCancelled;
  final VoidCallback? onDonePressed;
  final VoidCallback? onNegativePressed; // New callback
  final VoidCallback? onLostPressed;

  const NavigationScreen({
    super.key,
    this.onNavigationComplete,
    this.onNavigationCancelled,
    this.onDonePressed,
    this.onNegativePressed,
    this.onLostPressed,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, state, child) {
        final instruction = state.currentInstruction;
        final currentFloor = _getCurrentFloor(state);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text('Navigation'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                state.resetNavigation();
                widget.onNavigationCancelled?.call();
              },
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: Icon(_showMap ? Icons.explore : Icons.map, color: Colors.white),
                label: Text(
                  _showMap ? 'Show Street View' : 'Show Map',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: state.instructions.isEmpty
                      ? 0
                      : (state.currentInstructionIndex + 1) / state.instructions.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                ),

                // Main Content Area (Toggleable)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _showMap
                          ? FloorMapView(
                              floor: currentFloor,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : const NavigationVisualizer(),
                    ),
                  ),
                ),

                // Instruction card
                _buildInstructionCard(instruction),

                // Verification buttons
                _buildVerificationButtons(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getCurrentFloor(NavigationState state) {
    if (!GraphLoader.isLoaded) return 1;
    final currentNode = state.currentNode;
    if (currentNode == null) return 1;
    return GraphLoader.graph.getNode(currentNode)?.floor ?? 1;
  }

  Widget _buildInstructionCard(Map<String, dynamic>? instruction) {
    final text = instruction?['text'] as String? ?? 'Loading instructions...';
    // Hide distance for info/hints
    final isInfo = instruction?['type'] == 'info';
    final distance = isInfo ? null : instruction?['distanceEstimate'] as double?;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isInfo ? Colors.orange.shade50 : Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getInstructionIcon(instruction?['type'] as String?),
              color: isInfo ? Colors.orange : Colors.indigo,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (distance != null)
                  Text(
                    '~${distance.toInt()} meters',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationButtons(BuildContext context, NavigationState state) {
    // Contextual Helper Text Logic
    String helperText = '';
    final currentNodeId = state.currentNode;
    if (currentNodeId != null && GraphLoader.isLoaded) {
       final node = GraphLoader.graph.getNode(currentNodeId);
       if (node != null) {
          // Check if it's the final destination
          if (currentNodeId == state.destinationNode) {
             helperText = 'You are at ${node.name}';
          } else {
             helperText = 'You\'re near ${node.name}';
          }
       }
    }

    // Check if showing a hint (info)
    final isHint = state.currentInstruction?['type'] == 'info';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              // No Button (Replacing Lost or Next to it)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isHint ? widget.onDonePressed : widget.onNegativePressed, // If hint, Done dismisses it. Wait, "No" on hint?
                  // Design:
                  // If normal instruction: Yes = Done/Next, No = Show Hint.
                  // If hint: Yes = Done/Next (Proceed), No = Still lost? -> Maybe "I'm Lost"?
                  // Let's keep it simple:
                  // Button 1: "No" (or "Still Looking") -> Show Hint or Lost
                  // Button 2: "Yes" (or "Done") -> Next
                  
                  icon: Icon(isHint ? Icons.help : Icons.close),
                  label: Text(isHint ? "Still Can't Find" : 'No'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
               // Yes Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: widget.onDonePressed,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Yes, I am here'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (helperText.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Text(
                 helperText,
                 style: TextStyle(
                   color: Colors.grey.shade600,
                   fontStyle: FontStyle.italic,
                   fontSize: 12,
                 ),
               ),
             ),
          // Keep explicit Lost button? Maybe as a small text button below
          TextButton(
            onPressed: widget.onLostPressed, 
            child: const Text("Completely Lost? Reset Position"),
          )
        ],
      ),
    );
  }

  IconData _getInstructionIcon(String? type) {
    switch (type) {
      case 'walk':
        return Icons.straight;
      case 'turnLeft':
        return Icons.turn_left;
      case 'turnRight':
        return Icons.turn_right;
      case 'turnAround':
        return Icons.u_turn_left;
      case 'takeStairs':
        return Icons.stairs;
      case 'takeLift':
        return Icons.elevator;
      case 'arriveDestination':
        return Icons.flag;
      case 'info': // New case
        return Icons.info_outline;
      default:
        return Icons.navigation;
    }
  }
}
