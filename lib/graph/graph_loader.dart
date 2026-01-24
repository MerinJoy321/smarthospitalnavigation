import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'graph_data.dart';

/// Loader for navigation graph from JSON assets
class GraphLoader {
  static NavigationGraph? _cachedGraph;

  /// Load navigation graph from JSON asset
  static Future<NavigationGraph> loadGraph({String path = 'assets/data/graph.json'}) async {
    if (_cachedGraph != null) return _cachedGraph!;

    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> data = json.decode(jsonString);

    final nodes = (data['nodes'] as List)
        .map((n) => GraphNode.fromJson(n))
        .toList();
        
    final edges = (data['edges'] as List)
        .map((e) => GraphEdge.fromJson(e))
        .toList();

    final labels = data['labels'] != null
        ? (data['labels'] as List).map((l) => MapLabel.fromJson(l)).toList()
        : <MapLabel>[];

    _cachedGraph = NavigationGraph.fromNodesAndEdges(nodes, edges, labels: labels);
    return _cachedGraph!;
  }

  /// Get cached graph (throws if not loaded)
  static NavigationGraph get graph {
    if (_cachedGraph == null) {
      throw StateError('Graph not loaded. Call loadGraph() first.');
    }
    return _cachedGraph!;
  }

  /// Check if graph is loaded
  static bool get isLoaded => _cachedGraph != null;

  /// Clear cache (useful for testing)
  static void clearCache() {
    _cachedGraph = null;
  }
}
