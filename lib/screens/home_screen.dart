import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/navigation_state.dart';
import '../graph/graph_loader.dart';
import '../graph/graph_data.dart';

/// Home screen for destination selection
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigationStarted;

  const HomeScreen({super.key, this.onNavigationStarted});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedDestination;
  String? _selectedStartNode;


  @override
  void initState() {
    super.initState();
    // Initialize selected start with current node if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<NavigationState>();
      if (state.currentNode != null) {
        setState(() {
          _selectedStartNode = state.currentNode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NavigationState>();
    
    // Sync external changes (like beacon overrides)
    if (_selectedStartNode != state.currentNode && state.currentNode != null && _selectedStartNode == null) {
       _selectedStartNode = state.currentNode;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Indoor Navigation'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Location Selection
              const Text(
                'Start from',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _buildLocationSelector(
                label: 'Current Location',
                selectedId: _selectedStartNode,
                onTap: () => _showLocationPicker(
                  title: 'Select Start Location',
                  onSelected: (id) {
                    setState(() => _selectedStartNode = id);
                    state.setCurrentNode(id); // Update global state immediately
                  },
                ),
                icon: Icons.my_location,
                accentColor: Colors.indigo,
              ),
              
              const SizedBox(height: 24),

              // Destination Selection
              const Text(
                'To Destination',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildDestinationList(),
              ),

              // Start navigation button
              if (_selectedDestination != null && _selectedStartNode != null)
                _buildStartButton(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required String? selectedId,
    required VoidCallback onTap,
    required IconData icon,
    required Color accentColor,
  }) {
    String displayText = 'Select Location...';
    if (selectedId != null && GraphLoader.isLoaded) {
      final node = GraphLoader.graph.getNode(selectedId);
      displayText = node?.name ?? selectedId;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker({
    required String title,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildNodeList(onSelected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList(Function(String) onSelected) {
    if (!GraphLoader.isLoaded) return const Center(child: CircularProgressIndicator());
    
    // Sort destinations alphabetically
    final nodes = GraphLoader.graph.nodes.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return ListTile(
          leading: Icon(_getNodeIcon(node.type), color: _getNodeColor(node.type)),
          title: Text(node.name),
          subtitle: Text('Floor ${node.floor}'),
          onTap: () {
            onSelected(node.id);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Refactored Destination List to match style, or keep reusable
  // (Assuming _buildDestinationList adapts to this new structure logic if needed, 
  // but for now I'm replacing the whole body logic, so I'll preserve it roughly)
  
  Widget _buildDestinationList() {
    if (!GraphLoader.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final graph = GraphLoader.graph;
    // Show rooms as main destinations
    final destinations = graph.nodes
        .where((n) => n.type == NodeType.room || n.type == NodeType.entrance)
        .toList();

    return ListView.builder(
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final node = destinations[index];
        final isSelected = _selectedDestination == node.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected ? Colors.indigo.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _selectedDestination = node.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                         _getNodeIcon(node.type),
                         color: _getNodeColor(node.type),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Floor ${node.floor}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.indigo),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildStartButton(NavigationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedDestination != null) {
            state.setDestinationNode(_selectedDestination);
            widget.onNavigationStarted?.call();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(NodeType type) {
    switch (type) {
      case NodeType.entrance:
        return Colors.orange;
      case NodeType.room:
        return Colors.teal;
      default:
        return Colors.grey;
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
