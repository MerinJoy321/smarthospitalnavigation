import 'package:flutter/foundation.dart';
import '../models/digital_twin_models.dart';

/// Service that manages the Digital Twin state of the hospital
class DigitalTwinService extends ChangeNotifier {
  // Node states (blocked/congested nodes)
  final Map<String, NodeState> _nodeStates = {};
  
  // Edge states (blocked/congested edges)
  final Map<String, EdgeState> _edgeStates = {};
  
  // Triage zones
  final Map<String, TriageZone> _triageZones = {};
  
  // Congestion schedules
  final Map<String, CongestionSchedule> _congestionSchedules = {};
  
  // Simulated current time (for demo purposes)
  DateTime _simulatedTime = DateTime.now();
  bool _useSimulatedTime = false;

  DigitalTwinService() {
    _initializeDefaultTriageZones();
    _initializeDefaultCongestionSchedules();
  }

  // ==================== GETTERS ====================

  Map<String, NodeState> get nodeStates => Map.unmodifiable(_nodeStates);
  Map<String, EdgeState> get edgeStates => Map.unmodifiable(_edgeStates);
  Map<String, TriageZone> get triageZones => Map.unmodifiable(_triageZones);
  Map<String, CongestionSchedule> get congestionSchedules => Map.unmodifiable(_congestionSchedules);
  
  DateTime get currentTime => _useSimulatedTime ? _simulatedTime : DateTime.now();
  bool get useSimulatedTime => _useSimulatedTime;

  /// Get all active triage zones
  List<TriageZone> get activeTriageZones =>
      _triageZones.values.where((z) => z.isActive).toList();

  /// Get all active congestion schedules at current time
  List<CongestionSchedule> get activeCongestionSchedules =>
      _congestionSchedules.values.where((s) => s.isActiveAt(currentTime)).toList();

  // ==================== NODE MANAGEMENT ====================

  /// Check if a node is blocked
  bool isNodeBlocked(String nodeId) {
    // Check direct node block
    if (_nodeStates[nodeId]?.isBlocked == true) return true;
    
    // Check if blocked by any active triage zone
    for (final zone in activeTriageZones) {
      if (zone.nodeIds.contains(nodeId)) return true;
    }
    
    return false;
  }

  /// Get congestion multiplier for a node
  double getNodeCongestionMultiplier(String nodeId) {
    double multiplier = _nodeStates[nodeId]?.congestionMultiplier ?? 1.0;
    
    // Apply congestion from schedules
    for (final schedule in activeCongestionSchedules) {
      if (schedule.affectedNodeIds.contains(nodeId)) {
        multiplier = multiplier * schedule.congestionMultiplier;
      }
    }
    
    return multiplier;
  }

  /// Set node blocked state
  void setNodeBlocked(String nodeId, bool blocked, {String? reason}) {
    _nodeStates[nodeId] = NodeState(
      nodeId: nodeId,
      isBlocked: blocked,
      congestionMultiplier: _nodeStates[nodeId]?.congestionMultiplier ?? 1.0,
      blockReason: blocked ? reason : null,
    );
    notifyListeners();
  }

  /// Set node congestion multiplier
  void setNodeCongestion(String nodeId, double multiplier) {
    _nodeStates[nodeId] = NodeState(
      nodeId: nodeId,
      isBlocked: _nodeStates[nodeId]?.isBlocked ?? false,
      congestionMultiplier: multiplier,
      blockReason: _nodeStates[nodeId]?.blockReason,
    );
    notifyListeners();
  }

  // ==================== EDGE MANAGEMENT ====================

  String _edgeKey(String fromId, String toId) => '${fromId}_$toId';

  /// Check if an edge is blocked
  bool isEdgeBlocked(String fromId, String toId) {
    final key = _edgeKey(fromId, toId);
    final reverseKey = _edgeKey(toId, fromId);
    
    // Check direct edge block
    if (_edgeStates[key]?.isBlocked == true) return true;
    if (_edgeStates[reverseKey]?.isBlocked == true) return true;
    
    // Check if blocked by any active triage zone
    for (final zone in activeTriageZones) {
      if (zone.edgeKeys.contains(key) || zone.edgeKeys.contains(reverseKey)) {
        return true;
      }
    }
    
    return false;
  }

  /// Get congestion multiplier for an edge
  double getEdgeCongestionMultiplier(String fromId, String toId) {
    final key = _edgeKey(fromId, toId);
    final reverseKey = _edgeKey(toId, fromId);
    
    double multiplier = _edgeStates[key]?.congestionMultiplier ?? 
                        _edgeStates[reverseKey]?.congestionMultiplier ?? 1.0;
    
    // Apply congestion from schedules
    for (final schedule in activeCongestionSchedules) {
      if (schedule.affectedEdgeKeys.contains(key) || 
          schedule.affectedEdgeKeys.contains(reverseKey)) {
        multiplier = multiplier * schedule.congestionMultiplier;
      }
    }
    
    return multiplier;
  }

  /// Set edge blocked state
  void setEdgeBlocked(String fromId, String toId, bool blocked, {String? reason}) {
    final key = _edgeKey(fromId, toId);
    _edgeStates[key] = EdgeState(
      fromId: fromId,
      toId: toId,
      isBlocked: blocked,
      congestionMultiplier: _edgeStates[key]?.congestionMultiplier ?? 1.0,
      blockReason: blocked ? reason : null,
    );
    notifyListeners();
  }

  // ==================== TRIAGE ZONE MANAGEMENT ====================

  /// Toggle a triage zone
  void toggleTriageZone(String zoneId, bool active) {
    final zone = _triageZones[zoneId];
    if (zone != null) {
      _triageZones[zoneId] = zone.copyWith(isActive: active);
      notifyListeners();
    }
  }

  /// Clear all active triage zones
  void clearAllTriageZones() {
    for (final id in _triageZones.keys) {
      _triageZones[id] = _triageZones[id]!.copyWith(isActive: false);
    }
    notifyListeners();
  }

  // ==================== CONGESTION SCHEDULE MANAGEMENT ====================

  /// Toggle a congestion schedule
  void toggleCongestionSchedule(String scheduleId, bool enabled) {
    final schedule = _congestionSchedules[scheduleId];
    if (schedule != null) {
      _congestionSchedules[scheduleId] = schedule.copyWith(isEnabled: enabled);
      notifyListeners();
    }
  }

  /// Update congestion multiplier for a schedule
  void updateCongestionMultiplier(String scheduleId, double multiplier) {
    final schedule = _congestionSchedules[scheduleId];
    if (schedule != null) {
      _congestionSchedules[scheduleId] = schedule.copyWith(
        congestionMultiplier: multiplier,
      );
      notifyListeners();
    }
  }

  /// Clear all congestion schedules
  void clearAllCongestionSchedules() {
    for (final id in _congestionSchedules.keys) {
      _congestionSchedules[id] = _congestionSchedules[id]!.copyWith(isEnabled: false);
    }
    notifyListeners();
  }

  // ==================== TIME SIMULATION ====================

  /// Set simulated time for demo purposes
  void setSimulatedTime(DateTime time) {
    _simulatedTime = time;
    _useSimulatedTime = true;
    notifyListeners();
  }

  /// Toggle simulated time mode
  void toggleSimulatedTime(bool enabled) {
    _useSimulatedTime = enabled;
    if (!enabled) {
      _simulatedTime = DateTime.now();
    }
    notifyListeners();
  }

  // ==================== RESET FUNCTIONS ====================

  /// Reset all hospital state to default
  void resetHospitalState() {
    _nodeStates.clear();
    _edgeStates.clear();
    clearAllTriageZones();
    clearAllCongestionSchedules();
    _useSimulatedTime = false;
    _simulatedTime = DateTime.now();
    notifyListeners();
  }

  /// Reset only node/edge blocks (keep triage zones and schedules)
  void resetNodeEdgeBlocks() {
    _nodeStates.clear();
    _edgeStates.clear();
    notifyListeners();
  }

  // ==================== ROUTE CONTEXT ====================

  /// Get route result context (for user feedback)
  RouteResult getRouteContext() {
    final blockedAreas = <String>[];
    final congestedAreas = <String>[];
    
    // Collect blocked nodes
    for (final state in _nodeStates.values) {
      if (state.isBlocked) {
        blockedAreas.add(state.blockReason ?? state.nodeId);
      }
    }
    
    // Collect from active triage zones
    for (final zone in activeTriageZones) {
      blockedAreas.add(zone.name);
    }
    
    // Collect congested areas
    for (final schedule in activeCongestionSchedules) {
      congestedAreas.add(schedule.name);
    }
    
    RouteAdjustmentReason reason = RouteAdjustmentReason.none;
    if (activeTriageZones.isNotEmpty) {
      reason = RouteAdjustmentReason.emergency;
    } else if (blockedAreas.isNotEmpty) {
      reason = RouteAdjustmentReason.construction;
    } else if (congestedAreas.isNotEmpty) {
      reason = RouteAdjustmentReason.congestion;
    }
    
    return RouteResult(
      success: true,
      adjustmentReason: reason,
      blockedAreas: blockedAreas,
      congestedAreas: congestedAreas,
    );
  }

  // ==================== INITIALIZATION ====================

  void _initializeDefaultTriageZones() {
    _triageZones['emergency_surge'] = const TriageZone(
      id: 'emergency_surge',
      name: 'Emergency Surge Zone',
      description: 'Activates when ER is at capacity. Blocks direct access to emergency area.',
      nodeIds: ['emergency_ground'],
      edgeKeys: ['pharmacy_ground_emergency_ground'],
      type: TriageZoneType.emergencySurge,
    );
    
    _triageZones['trauma_response'] = const TriageZone(
      id: 'trauma_response',
      name: 'Trauma Response Zone',
      description: 'Activated during major trauma events. Restricts elevator access.',
      nodeIds: ['elevator_ground', 'elevator_first'],
      edgeKeys: ['reception_ground_elevator_ground', 'consultation_rooms_elevator_ground'],
      type: TriageZoneType.traumaResponse,
    );
    
    _triageZones['icu_isolation'] = const TriageZone(
      id: 'icu_isolation',
      name: 'ICU Isolation Zone',
      description: 'Isolates ICU areas during critical care situations.',
      nodeIds: ['icu_second', 'neuro_icu', 'cardiac_icu'],
      edgeKeys: ['elevator_second_icu_second', 'elevator_third_neuro_icu', 'elevator_third_cardiac_icu'],
      type: TriageZoneType.icuIsolation,
    );
    
    _triageZones['ward_quarantine'] = const TriageZone(
      id: 'ward_quarantine',
      name: 'Ward Quarantine',
      description: 'Quarantine zone for infectious disease control.',
      nodeIds: ['ward_a_first', 'ward_b_first'],
      edgeKeys: ['elevator_first_ward_a_first', 'elevator_first_ward_b_first'],
      type: TriageZoneType.quarantine,
    );
  }

  void _initializeDefaultCongestionSchedules() {
    _congestionSchedules['morning_rush'] = const CongestionSchedule(
      id: 'morning_rush',
      name: 'Morning Rush Hours',
      startHour: 9,
      startMinute: 0,
      endHour: 11,
      endMinute: 0,
      congestionMultiplier: 1.5,
      affectedNodeIds: ['reception_ground', 'consultation_rooms', 'pharmacy_ground'],
      affectedEdgeKeys: ['consultation_rooms_reception_ground', 'reception_ground_elevator_ground'],
    );
    
    _congestionSchedules['evening_rush'] = const CongestionSchedule(
      id: 'evening_rush',
      name: 'Evening Rush Hours',
      startHour: 17,
      startMinute: 0,
      endHour: 19,
      endMinute: 0,
      congestionMultiplier: 1.5,
      affectedNodeIds: ['reception_ground', 'pharmacy_ground'],
      affectedEdgeKeys: ['elevator_ground_pharmacy_ground'],
    );
    
    _congestionSchedules['lunch_peak'] = const CongestionSchedule(
      id: 'lunch_peak',
      name: 'Lunch Peak',
      startHour: 12,
      startMinute: 0,
      endHour: 14,
      endMinute: 0,
      congestionMultiplier: 1.3,
      affectedNodeIds: ['reception_ground'],
      affectedEdgeKeys: [],
      isEnabled: false,
    );
    
    _congestionSchedules['visiting_hours'] = const CongestionSchedule(
      id: 'visiting_hours',
      name: 'Visiting Hours',
      startHour: 14,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
      congestionMultiplier: 2.0,
      affectedNodeIds: ['ward_a_first', 'ward_b_first'],
      affectedEdgeKeys: ['elevator_first_ward_a_first', 'elevator_first_ward_b_first'],
      isEnabled: false,
    );
  }
}
