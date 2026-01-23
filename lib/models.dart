import 'dart:ui';

/// Core data models for the hospital navigator app.

class LocationNode {
  LocationNode({
    required this.id,
    required this.name,
    required this.position,
    this.level = 1,
    this.isEntrance = false,
    this.isLift = false,
    this.isStairs = false,
    this.isDepartment = false,
  });

  final String id;
  final String name;
  final Offset position;
  final int level;
  final bool isEntrance;
  final bool isLift;
  final bool isStairs;
  final bool isDepartment;
}

class CorridorEdge {
  CorridorEdge({
    required this.fromId,
    required this.toId,
    required this.distance,
    this.bidirectional = true,
  });

  final String fromId;
  final String toId;
  final double distance;
  final bool bidirectional;
}

class HospitalMap {
  HospitalMap({
    required this.id,
    required this.name,
    required this.level,
    required this.nodes,
    required this.edges,
  });

  final String id;
  final String name;
  final int level;
  final List<LocationNode> nodes;
  final List<CorridorEdge> edges;

  LocationNode? findNodeById(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  LocationNode? findNodeByName(String name) {
    try {
      return nodes.firstWhere(
        (n) => n.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<LocationNode> get departmentNodes =>
      nodes.where((n) => n.isDepartment).toList();
}

class RouteStep {
  RouteStep({
    required this.order,
    required this.from,
    required this.to,
    required this.instruction,
  });

  final int order;
  final LocationNode from;
  final LocationNode to;
  final String instruction;
}

class NavigationRoute {
  NavigationRoute({
    required this.map,
    required this.pathNodes,
    required this.steps,
    required this.totalDistanceMeters,
  });

  final HospitalMap map;
  final List<LocationNode> pathNodes;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
}

class Alert {
  Alert({
    required this.id,
    required this.title,
    required this.description,
    this.affectedNodeIds = const [],
    this.validUntil,
  });

  final String id;
  final String title;
  final String description;
  final List<String> affectedNodeIds;
  final DateTime? validUntil;

  bool get isActive {
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }
}

