// Digital Twin models for hospital state management

/// Represents the state of a node (room, corridor, etc.)
class NodeState {
  final String nodeId;
  final bool isBlocked;
  final double congestionMultiplier;
  final String? blockReason;

  const NodeState({
    required this.nodeId,
    this.isBlocked = false,
    this.congestionMultiplier = 1.0,
    this.blockReason,
  });

  NodeState copyWith({
    bool? isBlocked,
    double? congestionMultiplier,
    String? blockReason,
  }) {
    return NodeState(
      nodeId: nodeId,
      isBlocked: isBlocked ?? this.isBlocked,
      congestionMultiplier: congestionMultiplier ?? this.congestionMultiplier,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}

/// Represents the state of an edge (corridor connection)
class EdgeState {
  final String fromId;
  final String toId;
  final bool isBlocked;
  final double congestionMultiplier;
  final String? blockReason;

  const EdgeState({
    required this.fromId,
    required this.toId,
    this.isBlocked = false,
    this.congestionMultiplier = 1.0,
    this.blockReason,
  });

  String get edgeKey => '${fromId}_$toId';

  EdgeState copyWith({
    bool? isBlocked,
    double? congestionMultiplier,
    String? blockReason,
  }) {
    return EdgeState(
      fromId: fromId,
      toId: toId,
      isBlocked: isBlocked ?? this.isBlocked,
      congestionMultiplier: congestionMultiplier ?? this.congestionMultiplier,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}

/// Represents a triage zone (group of nodes/edges for emergency mode)
class TriageZone {
  final String id;
  final String name;
  final String description;
  final List<String> nodeIds;
  final List<String> edgeKeys; // format: "fromId_toId"
  final bool isActive;
  final TriageZoneType type;

  const TriageZone({
    required this.id,
    required this.name,
    required this.description,
    required this.nodeIds,
    required this.edgeKeys,
    this.isActive = false,
    this.type = TriageZoneType.general,
  });

  TriageZone copyWith({
    bool? isActive,
  }) {
    return TriageZone(
      id: id,
      name: name,
      description: description,
      nodeIds: nodeIds,
      edgeKeys: edgeKeys,
      isActive: isActive ?? this.isActive,
      type: type,
    );
  }
}

enum TriageZoneType {
  emergencySurge,
  traumaResponse,
  icuIsolation,
  quarantine,
  general,
}

/// Time-based congestion schedule
class CongestionSchedule {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double congestionMultiplier;
  final List<String> affectedNodeIds;
  final List<String> affectedEdgeKeys;
  final bool isEnabled;

  const CongestionSchedule({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.congestionMultiplier,
    required this.affectedNodeIds,
    required this.affectedEdgeKeys,
    this.isEnabled = true,
  });

  /// Check if this schedule is active at a given time
  bool isActiveAt(DateTime time) {
    if (!isEnabled) return false;
    
    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Handles overnight schedules (e.g., 22:00 - 06:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  String get timeRangeString {
    final start = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final end = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  CongestionSchedule copyWith({
    bool? isEnabled,
    double? congestionMultiplier,
  }) {
    return CongestionSchedule(
      id: id,
      name: name,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      congestionMultiplier: congestionMultiplier ?? this.congestionMultiplier,
      affectedNodeIds: affectedNodeIds,
      affectedEdgeKeys: affectedEdgeKeys,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Route adjustment reason for user feedback
enum RouteAdjustmentReason {
  none,
  construction,
  emergency,
  congestion,
  maintenance,
  noRouteAvailable,
}

/// Route calculation result with transparency info
class RouteResult {
  final bool success;
  final RouteAdjustmentReason adjustmentReason;
  final String? adjustmentMessage;
  final List<String> blockedAreas;
  final List<String> congestedAreas;

  const RouteResult({
    required this.success,
    this.adjustmentReason = RouteAdjustmentReason.none,
    this.adjustmentMessage,
    this.blockedAreas = const [],
    this.congestedAreas = const [],
  });

  String? get userFriendlyMessage {
    switch (adjustmentReason) {
      case RouteAdjustmentReason.construction:
        return 'Route adjusted due to construction';
      case RouteAdjustmentReason.emergency:
        return 'Route adjusted due to emergency operations';
      case RouteAdjustmentReason.congestion:
        return 'Route avoids busy areas and may take slightly longer';
      case RouteAdjustmentReason.maintenance:
        return 'Route adjusted due to maintenance';
      case RouteAdjustmentReason.noRouteAvailable:
        return 'No safe route available at this time';
      case RouteAdjustmentReason.none:
        return null;
    }
  }
}
