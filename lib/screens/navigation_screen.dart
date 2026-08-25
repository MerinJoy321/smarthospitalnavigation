import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/navigation_state.dart';
import '../views/three_d/navigation_visualizer.dart';
import '../views/maps/floor_map_view.dart';
import '../graph/graph_loader.dart';
import '../graph/graph_data.dart';

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
    this.onNodeReconfirmed, // New callback
  });

  final Function(String)? onNodeReconfirmed;

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
            title: Text(_getNavigationTitle(state)),
            backgroundColor: Colors.teal,
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
                icon: Icon(_showMap ? Icons.explore : Icons.map, color: Colors.white, size: 28),
                label: Text(
                  _showMap ? 'View Path' : 'View Map',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

  String _getNavigationTitle(NavigationState state) {
    if (!GraphLoader.isLoaded) return 'Navigation';
    final instruction = state.currentInstruction;
    if (instruction == null) return 'Navigation';

    final fromId = instruction['fromNode'] as String?;
    final toId = instruction['toNode'] as String?;
    if (fromId != null && toId != null) {
      final fromFloor = GraphLoader.graph.getNode(fromId)?.floor ?? 0;
      final toFloor = GraphLoader.graph.getNode(toId)?.floor ?? 0;
      if (fromFloor != toFloor) {
        return 'Floor $fromFloor ➔ Floor $toFloor';
      }
      return 'Floor $fromFloor';
    }
    return 'Navigation';
  }

  void _showLocationPicker(BuildContext context, NavigationState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where are you now?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildNodeList(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList(BuildContext context, NavigationState state) {
    if (!GraphLoader.isLoaded) return const Center(child: CircularProgressIndicator());
    
    final nodes = GraphLoader.graph.nodes.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Icon(_getNodeIcon(node.type), color: _getNodeColor(node.type), size: 32),
          title: Text(node.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          subtitle: Text('Floor ${node.floor}', style: const TextStyle(fontSize: 16)),
          onTap: () {
            widget.onNodeReconfirmed?.call(node.id);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Position updated to ${node.name}'),
                backgroundColor: Colors.teal,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  Color _getNodeColor(NodeType type) {
    switch (type) {
      case NodeType.entrance: return Colors.orange;
      case NodeType.room: return Colors.teal;
      default: return Colors.grey;
    }
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
              color: isInfo ? Colors.orange : Colors.teal,
              size: 48,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (distance != null)
                  Text(
                    '~${distance.toInt()} meters away',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
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
                  
                  icon: Icon(isHint ? Icons.help : Icons.close, size: 32),
                  label: Text(isHint ? "STILL LOST" : 'NO', style: const TextStyle(fontSize: 22)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(width: 20),
               // Yes Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: widget.onDonePressed,
                  icon: const Icon(Icons.check_circle, size: 36),
                  label: const Text('I AM HERE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ),
          if (helperText.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 12.0),
               child: Text(
                 helperText,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   color: Colors.teal.shade800,
                   fontWeight: FontWeight.bold,
                   fontSize: 18,
                 ),
               ),
             ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showLocationPicker(context, state), 
            icon: const Icon(Icons.refresh, size: 28),
            label: const Text(
              "I AM LOST - RE-CENTER", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
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

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.entrance:
        return Icons.door_front_door;
      case NodeType.room:
        return Icons.meeting_room;
      case NodeType.lift:
        return Icons.elevator;
      case NodeType.stairs:
        return Icons.stairs;
      default:
        return Icons.place;
    }
  }
}
