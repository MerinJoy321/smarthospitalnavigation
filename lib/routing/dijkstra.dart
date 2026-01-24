import 'dart:collection';
import '../graph/graph_data.dart';

/// Dijkstra's shortest path algorithm implementation
class Dijkstra {
  /// Find the shortest path between two nodes
  /// 
  /// Parameters:
  /// - [start]: Starting node ID
  /// - [end]: Destination node ID  
  /// - [graph]: Navigation graph
  /// - [costFunction]: Function to compute edge cost (default uses base cost)
  /// 
  /// Returns: Ordered list of node IDs from start to end, or empty list if no path
  static List<String> findShortestPath(
    String start,
    String end,
    NavigationGraph graph, {
    double Function(GraphEdge)? costFunction,
  }) {
    costFunction ??= (edge) => edge.baseCost;

    // Priority queue: (cost, nodeId)
    final pq = SplayTreeMap<double, List<String>>();
    void addToPQ(double cost, String nodeId) {
      pq.putIfAbsent(cost, () => []).add(nodeId);
    }
    String? popFromPQ() {
      if (pq.isEmpty) return null;
      final firstKey = pq.firstKey()!;
      final list = pq[firstKey]!;
      final node = list.removeLast();
      if (list.isEmpty) pq.remove(firstKey);
      return node;
    }

    // Distance and predecessor tracking
    final distances = <String, double>{};
    final predecessors = <String, String>{};
    final visited = <String>{};

    // Initialize
    for (final nodeId in graph.nodeIds) {
      distances[nodeId] = double.infinity;
    }
    distances[start] = 0;
    addToPQ(0, start);

    // Main loop
    while (pq.isNotEmpty) {
      final current = popFromPQ();
      if (current == null) break;

      if (visited.contains(current)) continue;
      visited.add(current);

      // Found destination
      if (current == end) break;

      // Explore neighbors
      for (final edge in graph.getEdgesFrom(current)) {
        if (visited.contains(edge.to)) continue;

        final edgeCost = costFunction!(edge);
        if (edgeCost == double.infinity) continue; // Blocked edge

        final newDist = distances[current]! + edgeCost;
        if (newDist < distances[edge.to]!) {
          distances[edge.to] = newDist;
          predecessors[edge.to] = current;
          addToPQ(newDist, edge.to);
        }
      }
    }

    // Reconstruct path
    if (!predecessors.containsKey(end) && start != end) {
      return []; // No path found
    }

    final path = <String>[];
    String? current = end;
    while (current != null) {
      path.add(current);
      current = predecessors[current];
    }

    return path.reversed.toList();
  }

  /// Check if a path exists between two nodes
  static bool hasPath(
    String start,
    String end,
    NavigationGraph graph, {
    double Function(GraphEdge)? costFunction,
  }) {
    final path = findShortestPath(start, end, graph, costFunction: costFunction);
    return path.isNotEmpty;
  }

  /// Get total path cost
  static double getPathCost(
    List<String> path,
    NavigationGraph graph, {
    double Function(GraphEdge)? costFunction,
  }) {
    costFunction ??= (edge) => edge.baseCost;
    
    if (path.length < 2) return 0;

    double totalCost = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final edges = graph.getEdgesFrom(path[i]);
      final edge = edges.firstWhere(
        (e) => e.to == path[i + 1],
        orElse: () => throw StateError('No edge between ${path[i]} and ${path[i + 1]}'),
      );
      totalCost += costFunction!(edge);
    }
    return totalCost;
  }
}
