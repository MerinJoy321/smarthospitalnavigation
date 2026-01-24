import '../state/navigation_state.dart';
import 'graph_data.dart';

/// Cost modifiers for accessibility and conditions
class CostModifiers {
  /// Cost multipliers for accessibility profiles
  static const Map<AccessibilityProfile, Map<EdgeType, double>> accessibilityMultipliers = {
    AccessibilityProfile.normal: {
      EdgeType.corridor: 1.0,
      EdgeType.stairs: 1.0,
      EdgeType.lift: 1.0,
    },
    AccessibilityProfile.wheelchair: {
      EdgeType.corridor: 1.0,
      EdgeType.stairs: double.infinity, // Stairs blocked
      EdgeType.lift: 0.8, // Prefer lifts
    },
    AccessibilityProfile.assisted: {
      EdgeType.corridor: 1.2,
      EdgeType.stairs: 2.5, // Stairs more costly
      EdgeType.lift: 0.8, // Prefer lifts
    },
  };

  /// Cost multipliers for active conditions
  static const Map<ActiveCondition, double> conditionMultipliers = {
    ActiveCondition.normal: 1.0,
    ActiveCondition.emergency: 1.5,
    ActiveCondition.maintenance: 2.0,
    ActiveCondition.congestion: 1.8,
    ActiveCondition.construction: 3.0,
  };

  /// Compute the effective cost of an edge given accessibility and conditions
  static double computeCost(
    GraphEdge edge,
    AccessibilityProfile accessibility,
    Set<ActiveCondition> conditions,
  ) {
    double cost = edge.baseCost;

    // Apply accessibility multiplier
    final accessMultiplier = accessibilityMultipliers[accessibility]?[edge.type] ?? 1.0;
    if (accessMultiplier == double.infinity) {
      return double.infinity; // Edge is blocked
    }
    cost *= accessMultiplier;

    // Apply condition multipliers (take the maximum if multiple)
    double maxConditionMultiplier = 1.0;
    for (final condition in conditions) {
      final mult = conditionMultipliers[condition] ?? 1.0;
      if (mult > maxConditionMultiplier) {
        maxConditionMultiplier = mult;
      }
    }
    cost *= maxConditionMultiplier;

    return cost;
  }

  /// Check if an edge is passable given accessibility
  static bool isPassable(
    GraphEdge edge,
    AccessibilityProfile accessibility,
  ) {
    final multiplier = accessibilityMultipliers[accessibility]?[edge.type] ?? 1.0;
    return multiplier != double.infinity;
  }

  /// Get a cost function for use with Dijkstra
  static double Function(GraphEdge) getCostFunction(
    AccessibilityProfile accessibility,
    Set<ActiveCondition> conditions,
  ) {
    return (edge) => computeCost(edge, accessibility, conditions);
  }
}
