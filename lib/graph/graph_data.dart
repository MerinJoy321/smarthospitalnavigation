/// Node types in the navigation graph
enum NodeType {
  entrance,
  junction,
  corridor,
  room,
  lift,
  stairs,
}

/// Edge types for cost calculation
enum EdgeType {
  corridor,
  stairs,
  lift,
}

/// A node in the navigation graph
class GraphNode {
  final String id;
  final int floor;
  final double x;
  final double y;
  final NodeType type;
  final String name;
  final Map<String, double>? anchor; // {x, y} for precise map pin

  GraphNode({
    required this.id,
    required this.floor,
    required this.x,
    required this.y,
    required this.type,
    required this.name,
    this.anchor,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'],
      floor: json['floor'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      type: NodeType.values.firstWhere((e) => e.toString() == 'NodeType.${json['type']}'),
      name: json['name'],
      anchor: json['anchor'] != null 
          ? {'x': json['anchor']['x'].toDouble(), 'y': json['anchor']['y'].toDouble()}
          : null,
    );
  }

  static NodeType _parseNodeType(String type) {
    switch (type) {
      case 'entrance':
        return NodeType.entrance;
      case 'junction':
        return NodeType.junction;
      case 'corridor':
        return NodeType.corridor;
      case 'room':
        return NodeType.room;
      case 'lift':
        return NodeType.lift;
      case 'stairs':
        return NodeType.stairs;
      default:
        return NodeType.corridor;
    }
  }
}

/// An edge connecting two nodes
class GraphEdge {
  final String from;
  final String to;
  final double baseCost;
  final EdgeType type;
  final List<Map<String, double>>? polyline; // Custom visual path

  GraphEdge({
    required this.from,
    required this.to,
    required this.baseCost,
    required this.type,
    this.polyline,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      from: json['from'],
      to: json['to'],
      baseCost: (json['cost'] as num).toDouble(),
      type: EdgeType.values.firstWhere(
        (e) => e.toString() == 'EdgeType.${json['type']}',
        orElse: () => EdgeType.corridor,
      ),
      polyline: json['polyline'] != null
          ? (json['polyline'] as List).map((p) => {
              'x': (p['x'] as num).toDouble(),
              'y': (p['y'] as num).toDouble(),
            }).toList()
          : null,
    );
  }
}

/// A visual text label on the map
class MapLabel {
  final String text;
  final int floor;
  final double x;
  final double y;

  MapLabel({
    required this.text,
    required this.floor,
    required this.x,
    required this.y,
  });

  factory MapLabel.fromJson(Map<String, dynamic> json) {
    return MapLabel(
      text: json['text'],
      floor: json['floor'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}

/// Complete navigation graph
class NavigationGraph {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<MapLabel> labels; // New: Map Labels
  
  // Quick lookup maps
  final Map<String, GraphNode> _nodeMap;
  final Map<String, List<GraphEdge>> _adjacencyList;

  NavigationGraph._({
    required this.nodes,
    required this.edges,
    this.labels = const [],
    required Map<String, GraphNode> nodeMap,
    required Map<String, List<GraphEdge>> adjacencyList,
  })  : _nodeMap = nodeMap,
        _adjacencyList = adjacencyList;

  factory NavigationGraph.fromNodesAndEdges(
    List<GraphNode> nodes, 
    List<GraphEdge> edges,
    {List<MapLabel> labels = const []}
  ) {
    // Build node lookup map
    final nodeMap = {for (var n in nodes) n.id: n};

    // Build adjacency list (bidirectional)
    final adjacencyList = <String, List<GraphEdge>>{};
    for (final node in nodes) {
      adjacencyList[node.id] = [];
    }
    for (final edge in edges) {
      adjacencyList[edge.from]?.add(edge);
      // Add reverse edge for bidirectional traversal
      adjacencyList[edge.to]?.add(GraphEdge(
        from: edge.to,
        to: edge.from,
        baseCost: edge.baseCost,
        type: edge.type,
        polyline: edge.polyline?.reversed.toList(), // Reverse visual path too
      ));
    }

    return NavigationGraph._(
      nodes: nodes,
      edges: edges,
      labels: labels,
      nodeMap: nodeMap,
      adjacencyList: adjacencyList,
    );
  }

  /// Get node by ID
  GraphNode? getNode(String id) => _nodeMap[id];

  /// Get all edges from a node
  List<GraphEdge> getEdgesFrom(String nodeId) => _adjacencyList[nodeId] ?? [];

  /// Get all node IDs
  List<String> get nodeIds => _nodeMap.keys.toList();

  /// Get nodes on a specific floor
  List<GraphNode> getNodesOnFloor(int floor) => 
      nodes.where((n) => n.floor == floor).toList();

  /// Get labels on a specific floor
  List<MapLabel> getLabelsOnFloor(int floor) =>
      labels.where((l) => l.floor == floor).toList();

  /// Check if edge exists between two nodes
  bool hasEdge(String from, String to) {
    return _adjacencyList[from]?.any((e) => e.to == to) ?? false;
  }
}
