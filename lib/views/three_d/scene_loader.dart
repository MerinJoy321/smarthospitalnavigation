import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../instructions/instruction_builder.dart';
import 'scene_templates.dart';

/// Loads appropriate 3D scene based on instruction type
class SceneLoader extends StatelessWidget {
  final InstructionType instructionType;
  final double? distanceEstimate;

  const SceneLoader({
    super.key,
    required this.instructionType,
    this.distanceEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final sceneType = _getSceneType();
    final arrowDirection = _getArrowDirection();
    final distanceText = distanceEstimate != null 
        ? '${distanceEstimate!.toInt()} meters'
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blueGrey.shade800,
            Colors.blueGrey.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scene3DWidget(
          sceneType: sceneType,
          arrowDirection: arrowDirection,
          distanceText: distanceText,
        ),
      ),
    );
  }

  SceneType _getSceneType() {
    switch (instructionType) {
      case InstructionType.walk:
        return SceneType.corridor;
      case InstructionType.turnLeft:
      case InstructionType.turnRight:
      case InstructionType.turnAround:
        return SceneType.junction;
      case InstructionType.takeStairs:
        return SceneType.stairs;
      case InstructionType.takeLift:
        return SceneType.lift;
      case InstructionType.arriveDestination:
        return SceneType.room;
    }
  }

  double? _getArrowDirection() {
    switch (instructionType) {
      case InstructionType.walk:
        return 0; // Straight ahead
      case InstructionType.turnLeft:
        return -math.pi / 2; // Left
      case InstructionType.turnRight:
        return math.pi / 2; // Right
      case InstructionType.turnAround:
        return math.pi; // Behind
      case InstructionType.takeStairs:
        return -math.pi / 4; // Up
      case InstructionType.takeLift:
        return null; // No arrow for lift
      case InstructionType.arriveDestination:
        return null; // No arrow at destination
    }
  }
}

/// Creates a scene loader from instruction map data
class SceneLoaderFactory {
  static Widget fromInstruction(Map<String, dynamic>? instruction) {
    if (instruction == null) {
      return const SizedBox.shrink();
    }

    final typeStr = instruction['type'] as String?;
    final distance = instruction['distanceEstimate'] as double?;

    InstructionType type;
    switch (typeStr) {
      case 'walk':
        type = InstructionType.walk;
        break;
      case 'turnLeft':
        type = InstructionType.turnLeft;
        break;
      case 'turnRight':
        type = InstructionType.turnRight;
        break;
      case 'turnAround':
        type = InstructionType.turnAround;
        break;
      case 'takeStairs':
        type = InstructionType.takeStairs;
        break;
      case 'takeLift':
        type = InstructionType.takeLift;
        break;
      case 'arriveDestination':
        type = InstructionType.arriveDestination;
        break;
      default:
        type = InstructionType.walk;
    }

    return SceneLoader(
      instructionType: type,
      distanceEstimate: distance,
    );
  }
}
