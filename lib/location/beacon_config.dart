import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Beacon configuration model
class BeaconConfig {
  final String beaconId;
  final String nodeId;
  final int floor;
  final String type;

  BeaconConfig({
    required this.beaconId,
    required this.nodeId,
    required this.floor,
    required this.type,
  });

  factory BeaconConfig.fromJson(Map<String, dynamic> json) {
    return BeaconConfig(
      beaconId: json['beaconId'] as String,
      nodeId: json['nodeId'] as String,
      floor: json['floor'] as int,
      type: json['type'] as String,
    );
  }
}

/// Beacon configuration loader
class BeaconConfigLoader {
  static List<BeaconConfig>? _cachedBeacons;
  static Map<String, BeaconConfig>? _beaconIdMap;
  static Map<String, BeaconConfig>? _nodeIdMap;

  /// Load all beacon configurations from JSON
  static Future<List<BeaconConfig>> loadBeacons() async {
    if (_cachedBeacons != null) return _cachedBeacons!;

    final String jsonString = await rootBundle.loadString('assets/data/beacons.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> beaconList = data['beacons'];

    _cachedBeacons = beaconList.map((b) => BeaconConfig.fromJson(b)).toList();
    
    // Build lookup maps
    _beaconIdMap = {for (var b in _cachedBeacons!) b.beaconId: b};
    _nodeIdMap = {for (var b in _cachedBeacons!) b.nodeId: b};

    return _cachedBeacons!;
  }

  /// Get beacon by beacon ID
  static BeaconConfig? getByBeaconId(String beaconId) {
    return _beaconIdMap?[beaconId];
  }

  /// Get beacon by node ID
  static BeaconConfig? getByNodeId(String nodeId) {
    return _nodeIdMap?[nodeId];
  }

  /// Get all beacons for a specific floor
  static List<BeaconConfig> getBeaconsForFloor(int floor) {
    return _cachedBeacons?.where((b) => b.floor == floor).toList() ?? [];
  }

  /// Clear cache (useful for testing)
  static void clearCache() {
    _cachedBeacons = null;
    _beaconIdMap = null;
    _nodeIdMap = null;
  }
}
