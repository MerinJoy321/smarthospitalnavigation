import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Provides a simple in-memory hospital map and routing logic.
class MapRepository {
  MapRepository() {
    _map = _buildSampleMap();
  }

  late final HospitalMap _map;

  HospitalMap get defaultMap => _map;

  /// In a real app this would parse JSON or a backend payload.
  HospitalMap _buildSampleMap() {
    // Simple single-floor demo map with approximate coordinates (0-1000).
    final nodes = <LocationNode>[
      LocationNode(
        id: 'entrance_main',
        name: 'Main Entrance',
        position: const Offset(100, 500),
        isEntrance: true,
      ),
      LocationNode(
        id: 'lobby',
        name: 'Lobby',
        position: const Offset(250, 500),
      ),
      LocationNode(
        id: 'lift_a',
        name: 'Lift A',
        position: const Offset(400, 500),
        isLift: true,
      ),
      LocationNode(
        id: 'corridor_mid',
        name: 'Main Corridor',
        position: const Offset(600, 500),
      ),
      LocationNode(
        id: 'xray',
        name: 'X-Ray Department',
        position: const Offset(800, 450),
        isDepartment: true,
      ),
      LocationNode(
        id: 'lab',
        name: 'Laboratory',
        position: const Offset(800, 550),
        isDepartment: true,
      ),
      LocationNode(
        id: 'ward_a',
        name: 'Ward A',
        position: const Offset(950, 500),
        isDepartment: true,
      ),
    ];

    final edges = <CorridorEdge>[
      CorridorEdge(fromId: 'entrance_main', toId: 'lobby', distance: 30),
      CorridorEdge(fromId: 'lobby', toId: 'lift_a', distance: 30),
      CorridorEdge(fromId: 'lift_a', toId: 'corridor_mid', distance: 40),
      CorridorEdge(fromId: 'corridor_mid', toId: 'xray', distance: 40),
      CorridorEdge(fromId: 'corridor_mid', toId: 'lab', distance: 40),
      CorridorEdge(fromId: 'xray', toId: 'ward_a', distance: 40),
      CorridorEdge(fromId: 'lab', toId: 'ward_a', distance: 40),
    ];

    return HospitalMap(
      id: 'demo_hospital',
      name: 'Demo General Hospital',
      level: 1,
      nodes: nodes,
      edges: edges,
    );
  }
}

/// Finds the shortest path between two locations using Dijkstra's algorithm.
class RoutingService {
  NavigationRoute? findRoute({
    required HospitalMap map,
    required LocationNode start,
    required LocationNode destination,
  }) {
    if (start.id == destination.id) {
      return NavigationRoute(
        map: map,
        pathNodes: [start],
        steps: [],
        totalDistanceMeters: 0,
      );
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final node in map.nodes) {
      distances[node.id] = double.infinity;
      previous[node.id] = null;
      unvisited.add(node.id);
    }
    distances[start.id] = 0;

    // Build adjacency list.
    final adjacency = <String, List<CorridorEdge>>{};
    for (final edge in map.edges) {
      adjacency.putIfAbsent(edge.fromId, () => []).add(edge);
      if (edge.bidirectional) {
        adjacency
            .putIfAbsent(edge.toId, () => [])
            .add(CorridorEdge(fromId: edge.toId, toId: edge.fromId, distance: edge.distance));
      }
    }

    while (unvisited.isNotEmpty) {
      // Pick the unvisited node with the smallest distance.
      String? currentId;
      double smallestDistance = double.infinity;
      for (final id in unvisited) {
        final d = distances[id] ?? double.infinity;
        if (d < smallestDistance) {
          smallestDistance = d;
          currentId = id;
        }
      }

      if (currentId == null) break;
      if (currentId == destination.id) break;

      unvisited.remove(currentId);

      final neighbors = adjacency[currentId] ?? [];
      for (final edge in neighbors) {
        final alt = (distances[currentId] ?? double.infinity) + edge.distance;
        if (alt < (distances[edge.toId] ?? double.infinity)) {
          distances[edge.toId] = alt;
          previous[edge.toId] = currentId;
        }
      }
    }

    if ((previous[destination.id] == null) && destination.id != start.id) {
      return null; // No path.
    }

    // Reconstruct path.
    final pathIds = <String>[];
    String? current = destination.id;
    while (current != null) {
      pathIds.insert(0, current);
      current = previous[current];
    }

    final pathNodes = <LocationNode>[];
    for (final id in pathIds) {
      final node = map.findNodeById(id);
      if (node == null) continue;
      pathNodes.add(node);
    }

    final steps = <RouteStep>[];
    for (var i = 0; i < pathNodes.length - 1; i++) {
      final from = pathNodes[i];
      final to = pathNodes[i + 1];
      steps.add(
        RouteStep(
          order: i + 1,
          from: from,
          to: to,
          instruction: _buildInstruction(from, to),
        ),
      );
    }

    final totalDistance = distances[destination.id] ?? 0;
    return NavigationRoute(
      map: map,
      pathNodes: pathNodes,
      steps: steps,
      totalDistanceMeters: totalDistance,
    );
  }

  String _buildInstruction(LocationNode from, LocationNode to) {
    // For the demo we keep this simple; could use angle math here.
    if (to.isLift) {
      return 'Walk straight to ${to.name} (lift).';
    }
    if (to.isDepartment) {
      return 'Continue to ${to.name}. You have almost arrived.';
    }
    return 'Walk towards ${to.name}.';
  }
}

/// Simple in-memory "real-time" alerts stream.
class UpdatesService {
  final _controller = StreamController<List<Alert>>.broadcast();

  List<Alert> _alerts = [];

  Stream<List<Alert>> get alertsStream => _controller.stream;

  List<Alert> get currentAlerts => List.unmodifiable(_alerts);

  UpdatesService() {
    // Seed with a sample construction alert.
    _alerts = [
      Alert(
        id: 'construction_corridor_mid',
        title: 'Construction near Main Corridor',
        description:
            'Follow temporary signage around the main corridor. Extra 2–3 minutes expected.',
        affectedNodeIds: const ['corridor_mid'],
        validUntil: DateTime.now().add(const Duration(hours: 8)),
      ),
    ];

    // Emit initial value.
    _controller.add(_alerts);
  }

  void addOrUpdateAlert(Alert alert) {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index == -1) {
      _alerts = [..._alerts, alert];
    } else {
      _alerts = [
        ..._alerts.sublist(0, index),
        alert,
        ..._alerts.sublist(index + 1),
      ];
    }
    _controller.add(_alerts);
  }

  void removeAlert(String id) {
    _alerts = _alerts.where((a) => a.id != id).toList();
    _controller.add(_alerts);
  }

  @mustCallSuper
  void dispose() {
    _controller.close();
  }
}

