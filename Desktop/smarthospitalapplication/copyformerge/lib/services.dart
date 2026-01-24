import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'services/digital_twin_service.dart';
import 'models/digital_twin_models.dart';

/// Provides a simple in-memory hospital map and routing logic.
class MapRepository {
  MapRepository() {
    _floors = _buildFloorMaps();
  }

  late final Map<int, HospitalMap> _floors;

  /// Get all available floors
  List<int> get availableFloors => _floors.keys.toList()..sort();

  /// Get map for a specific floor
  HospitalMap? getMapForFloor(int floor) => _floors[floor];

  /// Get the first available floor map (for backward compatibility)
  HospitalMap get defaultMap => _floors[1] ?? _floors.values.first;

  /// Build floor maps for 4 floors with example data
  Map<int, HospitalMap> _buildFloorMaps() {
    final floors = <int, HospitalMap>{};

    // Ground Floor (Floor 1)
    floors[1] = _buildGroundFloor();

    // First Floor (Floor 2)
    floors[2] = _buildFirstFloor();

    // Second Floor (Floor 3)
    floors[3] = _buildSecondFloor();

    // Third Floor (Floor 4)
    floors[4] = _buildThirdFloor();

    return floors;
  }

  HospitalMap _buildGroundFloor() {
    // Coordinates are percentage-based (0-100), (0,0) is top-left
    final nodes = <LocationNode>[
      LocationNode(
        id: 'consultation_rooms',
        name: 'Consultation Rooms',
        position: const Offset(20, 55), // (20, 55)
        level: 1,
        isDepartment: true,
      ),
      LocationNode(
        id: 'elevator_ground',
        name: 'Elevator',
        position: const Offset(50, 85), // (50, 85)
        level: 1,
        isLift: true,
      ),
      LocationNode(
        id: 'reception_ground',
        name: 'Reception',
        position: const Offset(30, 70),
        level: 1,
      ),
      LocationNode(
        id: 'pharmacy_ground',
        name: 'Pharmacy',
        position: const Offset(70, 60),
        level: 1,
        isDepartment: true,
      ),
      LocationNode(
        id: 'emergency_ground',
        name: 'Emergency Department',
        position: const Offset(80, 80),
        level: 1,
        isDepartment: true,
      ),
    ];

    final edges = <CorridorEdge>[
      // Direct path from Consultation Rooms to Elevator
      CorridorEdge(
        fromId: 'consultation_rooms',
        toId: 'elevator_ground',
        distance: 35,
      ),
      // Alternative paths
      CorridorEdge(
        fromId: 'consultation_rooms',
        toId: 'reception_ground',
        distance: 20,
      ),
      CorridorEdge(
        fromId: 'reception_ground',
        toId: 'elevator_ground',
        distance: 25,
      ),
      CorridorEdge(
        fromId: 'elevator_ground',
        toId: 'pharmacy_ground',
        distance: 30,
      ),
      CorridorEdge(
        fromId: 'pharmacy_ground',
        toId: 'emergency_ground',
        distance: 25,
      ),
    ];

    return HospitalMap(
      id: 'hospital_floor_1',
      name: 'Ground Floor',
      level: 1,
      nodes: nodes,
      edges: edges,
    );
  }

  HospitalMap _buildFirstFloor() {
    final nodes = <LocationNode>[
      LocationNode(
        id: 'elevator_first',
        name: 'Elevator',
        position: const Offset(50, 85), // (50, 85)
        level: 2,
        isLift: true,
      ),
      LocationNode(
        id: 'ward_a_first',
        name: 'Ward A',
        position: const Offset(30, 50),
        level: 2,
        isDepartment: true,
      ),
      LocationNode(
        id: 'ward_b_first',
        name: 'Ward B',
        position: const Offset(70, 50),
        level: 2,
        isDepartment: true,
      ),
    ];

    final edges = <CorridorEdge>[
      CorridorEdge(
        fromId: 'elevator_first',
        toId: 'ward_a_first',
        distance: 40,
      ),
      CorridorEdge(
        fromId: 'elevator_first',
        toId: 'ward_b_first',
        distance: 40,
      ),
    ];

    return HospitalMap(
      id: 'hospital_floor_2',
      name: 'First Floor',
      level: 2,
      nodes: nodes,
      edges: edges,
    );
  }

  HospitalMap _buildSecondFloor() {
    final nodes = <LocationNode>[
      LocationNode(
        id: 'elevator_second',
        name: 'Elevator',
        position: const Offset(50, 85), // (50, 85)
        level: 3,
        isLift: true,
      ),
      LocationNode(
        id: 'surgery_second',
        name: 'Surgery Department',
        position: const Offset(40, 40),
        level: 3,
        isDepartment: true,
      ),
      LocationNode(
        id: 'icu_second',
        name: 'ICU',
        position: const Offset(60, 45),
        level: 3,
        isDepartment: true,
      ),
    ];

    final edges = <CorridorEdge>[
      CorridorEdge(
        fromId: 'elevator_second',
        toId: 'surgery_second',
        distance: 50,
      ),
      CorridorEdge(fromId: 'elevator_second', toId: 'icu_second', distance: 45),
    ];

    return HospitalMap(
      id: 'hospital_floor_3',
      name: 'Second Floor',
      level: 3,
      nodes: nodes,
      edges: edges,
    );
  }

  HospitalMap _buildThirdFloor() {
    final nodes = <LocationNode>[
      LocationNode(
        id: 'elevator_third',
        name: 'Elevator',
        position: const Offset(50, 85), // (50, 85)
        level: 4,
        isLift: true,
      ),
      LocationNode(
        id: 'neuro_icu',
        name: 'Neuro ICU',
        position: const Offset(75, 35), // (75, 35) - from example
        level: 4,
        isDepartment: true,
      ),
      LocationNode(
        id: 'cardiac_icu',
        name: 'Cardiac ICU',
        position: const Offset(25, 40),
        level: 4,
        isDepartment: true,
      ),
    ];

    final edges = <CorridorEdge>[
      CorridorEdge(fromId: 'elevator_third', toId: 'neuro_icu', distance: 55),
      CorridorEdge(fromId: 'elevator_third', toId: 'cardiac_icu', distance: 50),
    ];

    return HospitalMap(
      id: 'hospital_floor_4',
      name: 'Third Floor',
      level: 4,
      nodes: nodes,
      edges: edges,
    );
  }
}

/// Finds the shortest path between two locations using Dijkstra's algorithm.
/// Supports dynamic weights based on Digital Twin state.
class RoutingService {
  RoutingService({
    required this.mapRepository,
    this.digitalTwinService,
  });

  final MapRepository mapRepository;
  DigitalTwinService? digitalTwinService;

  /// Set or update the Digital Twin service
  void setDigitalTwinService(DigitalTwinService service) {
    digitalTwinService = service;
  }

  /// Find route with multi-floor support - always starts on Ground Floor (Floor 1)
  MultiFloorRoute? findMultiFloorRoute({
    required LocationNode start,
    required LocationNode destination,
  }) {
    // Always start navigation from Ground Floor (Floor 1)
    // If start is not on Ground Floor, find the start location on Ground Floor
    final groundFloor = mapRepository.getMapForFloor(1);
    if (groundFloor == null || groundFloor.nodes.isEmpty) {
      return null;
    }

    // If start is not on Ground Floor, use the provided start's name to find it on Ground Floor
    LocationNode groundStart;
    if (start.level != 1) {
      // Try to find a node with the same name on Ground Floor
      groundStart = groundFloor.nodes.firstWhere(
        (n) => n.name == start.name || n.id == start.id,
        orElse: () => groundFloor.nodes.firstWhere(
          (n) => n.isDepartment,
          orElse: () => groundFloor.nodes.first,
        ),
      );
    } else {
      groundStart = start;
    }

    // If destination is on Ground Floor, simple single-floor route
    if (destination.level == 1) {
      return _findSingleFloorRoute(groundStart, destination);
    }

    // Multi-floor route: Ground Floor -> Elevator -> Destination Floor
    return _findMultiFloorRoute(groundStart, destination);
  }

  /// Find route on a single floor using weighted Dijkstra's algorithm.
  /// Considers blocked nodes/edges and congestion multipliers from Digital Twin.
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

    // Check if start or destination is blocked
    if (digitalTwinService != null) {
      if (digitalTwinService!.isNodeBlocked(start.id)) {
        return null; // Start is blocked
      }
      if (digitalTwinService!.isNodeBlocked(destination.id)) {
        return null; // Destination is blocked
      }
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final node in map.nodes) {
      // Skip blocked nodes
      if (digitalTwinService != null && digitalTwinService!.isNodeBlocked(node.id)) {
        continue;
      }
      distances[node.id] = double.infinity;
      previous[node.id] = null;
      unvisited.add(node.id);
    }
    distances[start.id] = 0;

    // Build adjacency list with weighted edges
    final adjacency = <String, List<_WeightedEdge>>{};
    for (final edge in map.edges) {
      // Skip blocked edges
      if (digitalTwinService != null && 
          digitalTwinService!.isEdgeBlocked(edge.fromId, edge.toId)) {
        continue;
      }

      // Calculate weighted distance
      double weight = edge.distance;
      if (digitalTwinService != null) {
        // Apply edge congestion multiplier
        final edgeCongestion = digitalTwinService!.getEdgeCongestionMultiplier(
          edge.fromId, edge.toId,
        );
        // Apply destination node congestion multiplier
        final nodeCongestion = digitalTwinService!.getNodeCongestionMultiplier(edge.toId);
        weight = edge.distance * edgeCongestion * nodeCongestion;
      }

      adjacency.putIfAbsent(edge.fromId, () => []).add(
        _WeightedEdge(fromId: edge.fromId, toId: edge.toId, weight: weight, baseDistance: edge.distance),
      );
      
      if (edge.bidirectional) {
        // Recalculate for reverse direction
        double reverseWeight = edge.distance;
        if (digitalTwinService != null) {
          final edgeCongestion = digitalTwinService!.getEdgeCongestionMultiplier(
            edge.toId, edge.fromId,
          );
          final nodeCongestion = digitalTwinService!.getNodeCongestionMultiplier(edge.fromId);
          reverseWeight = edge.distance * edgeCongestion * nodeCongestion;
        }
        
        adjacency.putIfAbsent(edge.toId, () => []).add(
          _WeightedEdge(fromId: edge.toId, toId: edge.fromId, weight: reverseWeight, baseDistance: edge.distance),
        );
      }
    }

    while (unvisited.isNotEmpty) {
      // Pick the unvisited node with the smallest distance (weighted)
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
        // Skip if target node is blocked
        if (digitalTwinService != null && digitalTwinService!.isNodeBlocked(edge.toId)) {
          continue;
        }
        
        final alt = (distances[currentId] ?? double.infinity) + edge.weight;
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

    // Calculate actual distance (using base distances, not weighted)
    double totalDistance = 0;
    for (var i = 0; i < pathIds.length - 1; i++) {
      final fromId = pathIds[i];
      final toId = pathIds[i + 1];
      final edges = adjacency[fromId] ?? [];
      for (final edge in edges) {
        if (edge.toId == toId) {
          totalDistance += edge.baseDistance;
          break;
        }
      }
    }

    return NavigationRoute(
      map: map,
      pathNodes: pathNodes,
      steps: steps,
      totalDistanceMeters: totalDistance,
    );
  }

  /// Get route context for user feedback
  RouteResult? getRouteContext() {
    return digitalTwinService?.getRouteContext();
  }

  String _buildInstruction(LocationNode from, LocationNode to) {
    // For the demo we keep this simple; could use angle math here.
    if (to.isLift) {
      return 'Walk straight to ${to.name} (lift).';
    }
    if (to.isStairs) {
      return 'Walk straight to ${to.name} (stairs).';
    }
    if (to.isDepartment) {
      return 'Continue to ${to.name}. You have almost arrived.';
    }
    return 'Walk towards ${to.name}.';
  }

  /// Find single-floor route (when both start and destination are on same floor)
  MultiFloorRoute? _findSingleFloorRoute(
    LocationNode start,
    LocationNode destination,
  ) {
    final floor = mapRepository.getMapForFloor(start.level);
    if (floor == null) return null;

    // Ensure start and destination are in the floor's nodes
    final floorStart = floor.findNodeById(start.id) ?? start;
    final floorDest = floor.findNodeById(destination.id) ?? destination;

    final route = findRoute(
      map: floor,
      start: floorStart,
      destination: floorDest,
    );
    if (route == null) return null;

    return MultiFloorRoute(
      floorRoutes: {start.level: route},
      transitions: [],
      totalDistanceMeters: route.totalDistanceMeters,
    );
  }

  /// Find multi-floor route (Ground Floor -> Elevator -> Destination Floor)
  MultiFloorRoute? _findMultiFloorRoute(
    LocationNode start,
    LocationNode destination,
  ) {
    final groundFloor = mapRepository.getMapForFloor(1);
    final destFloor = mapRepository.getMapForFloor(destination.level);
    if (groundFloor == null || destFloor == null) return null;

    // Find nearest elevator or stairs on Ground Floor
    final groundElevators = groundFloor.nodes
        .where((n) => n.isLift || n.isStairs)
        .toList();
    if (groundElevators.isEmpty) return null;

    // Find nearest elevator to start point
    LocationNode? nearestElevator;
    double minDistance = double.infinity;
    for (final elevator in groundElevators) {
      final routeToElevator = findRoute(
        map: groundFloor,
        start: start,
        destination: elevator,
      );
      if (routeToElevator != null &&
          routeToElevator.totalDistanceMeters < minDistance) {
        minDistance = routeToElevator.totalDistanceMeters;
        nearestElevator = elevator;
      }
    }

    if (nearestElevator == null) return null;

    // Find elevator on destination floor (same coordinates, different floor)
    // Elevators are at (50, 85) on all floors
    final destElevator = destFloor.nodes.firstWhere(
      (n) => (n.isLift || n.isStairs),
      orElse: () => destFloor.nodes.first,
    );

    // Route 1: Start -> Elevator on Ground Floor
    final routeToElevator = findRoute(
      map: groundFloor,
      start: start,
      destination: nearestElevator,
    );
    if (routeToElevator == null) return null;

    // Route 2: Elevator -> Destination on Destination Floor
    final routeFromElevator = findRoute(
      map: destFloor,
      start: destElevator,
      destination: destination,
    );
    if (routeFromElevator == null) return null;

    // Create transition
    final transition = FloorTransition(
      fromFloor: 1,
      toFloor: destination.level,
      transitionNode: nearestElevator,
      transitionType: nearestElevator.isLift ? 'elevator' : 'stairs',
    );

    // Create combined route for destination floor (for display)
    final combinedDestRoute = NavigationRoute(
      map: destFloor,
      pathNodes: [destElevator, ...routeFromElevator.pathNodes.skip(1)],
      steps: routeFromElevator.steps,
      totalDistanceMeters: routeFromElevator.totalDistanceMeters,
    );

    return MultiFloorRoute(
      floorRoutes: {1: routeToElevator, destination.level: combinedDestRoute},
      transitions: [transition],
      totalDistanceMeters:
          routeToElevator.totalDistanceMeters +
          routeFromElevator.totalDistanceMeters,
    );
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
            'Follow temporary signage around the main corridor. Extra 2ΓÇô3 minutes expected.',
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

/// Internal class for weighted edge in Dijkstra's algorithm
class _WeightedEdge {
  final String fromId;
  final String toId;
  final double weight; // Weighted distance (includes congestion)
  final double baseDistance; // Original physical distance

  _WeightedEdge({
    required this.fromId,
    required this.toId,
    required this.weight,
    required this.baseDistance,
  });
}
