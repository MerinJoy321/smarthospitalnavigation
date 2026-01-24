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
  final VoidCallback? onLostPressed;

  const NavigationScreen({
    super.key,
    this.onNavigationComplete,
    this.onNavigationCancelled,
    this.onDonePressed,
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
                if (!_showMap) _buildInstructionCard(instruction),

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
    final distance = instruction?['distanceEstimate'] as double?;

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
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getInstructionIcon(instruction?['type'] as String?),
              color: Colors.indigo,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onLostPressed,
                  icon: const Icon(Icons.help_outline),
                  label: const Text("I'm Lost"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: widget.onDonePressed,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Done'),
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
      default:
        return Icons.navigation;
    }
  }
}
