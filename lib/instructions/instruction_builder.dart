import 'dart:math';
import '../graph/graph_data.dart';
import '../graph/graph_loader.dart';

/// Types of navigation instructions
enum InstructionType {
  walk,
  turnLeft,
  turnRight,
  turnAround,
  takeStairs,
  takeLift,
  arriveDestination,
}

/// A single navigation instruction
class Instruction {
  final InstructionType type;
  final String text;
  final String fromNode;
  final String toNode;
  final double distanceEstimate;
  final String? landmark;

  Instruction({
    required this.type,
    required this.text,
    required this.fromNode,
    required this.toNode,
    required this.distanceEstimate,
    this.landmark,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'text': text,
      'fromNode': fromNode,
      'toNode': toNode,
      'distanceEstimate': distanceEstimate,
      'landmark': landmark,
    };
  }
}

/// Builds human-readable navigation instructions from a route
class InstructionBuilder {
  /// Build instructions from a route
  static List<Instruction> buildInstructions(List<String> route) {
    if (route.isEmpty) return [];
    if (route.length == 1) {
      return [
        Instruction(
          type: InstructionType.arriveDestination,
          text: 'You have arrived at your destination.',
          fromNode: route[0],
          toNode: route[0],
          distanceEstimate: 0,
        ),
      ];
    }

    final instructions = <Instruction>[];
    final graph = GraphLoader.graph;

    for (int i = 0; i < route.length - 1; i++) {
      final fromNode = graph.getNode(route[i]);
      final toNode = graph.getNode(route[i + 1]);

      if (fromNode == null || toNode == null) continue;

      // Find edge to get type and cost
      final edges = graph.getEdgesFrom(route[i]);
      final edge = edges.firstWhere(
        (e) => e.to == route[i + 1],
        orElse: () => GraphEdge(
          from: route[i],
          to: route[i + 1],
          baseCost: 10,
          type: EdgeType.corridor,
        ),
      );

      final instruction = _buildInstruction(
        fromNode: fromNode,
        toNode: toNode,
        edge: edge,
        previousNode: i > 0 ? graph.getNode(route[i - 1]) : null,
        isLastStep: i == route.length - 2,
      );
      instructions.add(instruction);
    }

    // Add arrival instruction
    instructions.add(Instruction(
      type: InstructionType.arriveDestination,
      text: 'You have arrived at ${graph.getNode(route.last)?.name ?? "your destination"}.',
      fromNode: route[route.length - 2],
      toNode: route.last,
      distanceEstimate: 0,
    ));

    return instructions;
  }

  static Instruction _buildInstruction({
    required GraphNode fromNode,
    required GraphNode toNode,
    required GraphEdge edge,
    GraphNode? previousNode,
    required bool isLastStep,
  }) {
    InstructionType type;
    String text;

    switch (edge.type) {
      case EdgeType.stairs:
        type = InstructionType.takeStairs;
        final direction = toNode.floor > fromNode.floor ? 'up' : 'down';
        // Explicit Floor Change Requirement
        text = 'Go $direction to Floor ${toNode.floor} using the stairs.';
        break;

      case EdgeType.lift:
        type = InstructionType.takeLift;
        final direction = toNode.floor > fromNode.floor ? 'up' : 'down';
        // Explicit Floor Change Requirement
        text = 'Go $direction to Floor ${toNode.floor} using the lift.';
        break;

      case EdgeType.corridor:
      default:
        // Determine turn direction based on position change
        final turnType = _determineTurnType(previousNode, fromNode, toNode);
        type = turnType;

        switch (turnType) {
          case InstructionType.turnLeft:
            text = 'Turn left and walk towards ${toNode.name}.';
            break;
          case InstructionType.turnRight:
            text = 'Turn right and walk towards ${toNode.name}.';
            break;
          case InstructionType.turnAround:
            text = 'Turn around and walk towards ${toNode.name}.';
            break;
          default:
            text = 'Continue straight to ${toNode.name}.';
            type = InstructionType.walk;
        }
    }

    return Instruction(
      type: type,
      text: text,
      fromNode: fromNode.id,
      toNode: toNode.id,
      distanceEstimate: edge.baseCost,
      landmark: toNode.type == NodeType.room || toNode.type == NodeType.entrance
          ? toNode.name
          : null,
    );
  }

  static InstructionType _determineTurnType(
    GraphNode? previousNode,
    GraphNode fromNode,
    GraphNode toNode,
  ) {
    if (previousNode == null) {
      return InstructionType.walk;
    }

    // Calculate direction vectors
    final inVector = Point(
      fromNode.x - previousNode.x,
      fromNode.y - previousNode.y,
    );
    final outVector = Point(
      toNode.x - fromNode.x,
      toNode.y - fromNode.y,
    );

    // Cross product to determine turn direction
    final cross = inVector.x * outVector.y - inVector.y * outVector.x;
    final dot = inVector.x * outVector.x + inVector.y * outVector.y;

    // Calculate angle
    final angle = atan2(cross.toDouble(), dot.toDouble());
    final angleDegrees = angle * 180 / pi;

    if (angleDegrees.abs() < 30) {
      return InstructionType.walk; // Straight
    } else if (angleDegrees > 30 && angleDegrees < 150) {
      return InstructionType.turnRight;
    } else if (angleDegrees < -30 && angleDegrees > -150) {
      return InstructionType.turnLeft;
    } else {
      return InstructionType.turnAround;
    }
  }

  /// Convert instructions to map list for state storage
  static List<Map<String, dynamic>> toMapList(List<Instruction> instructions) {
    return instructions.map((i) => i.toMap()).toList();
  }
}
