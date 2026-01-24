import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/navigation_state.dart';
import 'scene_templates.dart';
import 'dart:math' as math;

class NavigationVisualizer extends StatefulWidget {
  const NavigationVisualizer({super.key});

  @override
  State<NavigationVisualizer> createState() => _NavigationVisualizerState();
}

class _NavigationVisualizerState extends State<NavigationVisualizer> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _turnController;
  
  // Local state to track transitions
  int _lastInstructionIndex = -1;
  SceneType _currentSceneType = SceneType.corridor;
  bool _isTurning = false;
  double _turnTarget = 0.0; // Target rotation

  @override
  void initState() {
    super.initState();
    // Movement loop (walking)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Turn animation (once)
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _turnController.dispose();
    super.dispose();
  }

  void _updateAnimationState(NavigationState state) {
    if (state.currentInstructionIndex != _lastInstructionIndex) {
      _lastInstructionIndex = state.currentInstructionIndex;
      
      final instruction = state.currentInstruction;
      if (instruction == null) {
        _moveController.stop();
        return;
      }

      final typeStr = instruction['type'] as String?;
      _updateSceneConfig(typeStr);
    }
  }

  void _updateSceneConfig(String? typeStr) {
    // Reset controllers
    _moveController.stop();
    _turnController.stop();
    _turnController.value = 0;
    
    switch (typeStr) {
      case 'walk':
        _currentSceneType = SceneType.corridor;
        _isTurning = false;
        _moveController.repeat(); // Loop walking
        break;
        
      case 'turnLeft':
        _currentSceneType = SceneType.junction;
        _isTurning = true;
        _turnTarget = -math.pi / 2;
        _turnController.forward();
        break;
        
      case 'turnRight':
        _currentSceneType = SceneType.junction;
        _isTurning = true;
        _turnTarget = math.pi / 2;
        _turnController.forward();
        break;
        
      case 'turnAround':
        _currentSceneType = SceneType.junction;
        _isTurning = true;
        _turnTarget = math.pi;
        _turnController.forward();
        break;
        
      case 'takeStairs':
        _currentSceneType = SceneType.stairs;
        _isTurning = false;
        // Stairs might be static or custom animation
        break;
        
      case 'takeLift':
        _currentSceneType = SceneType.lift;
        _isTurning = false;
        _moveController.repeat(reverse: true); // Pulse door
        break;
        
      case 'arriveDestination':
        _currentSceneType = SceneType.room;
        _moveController.value = 1.0; // Stop at end
        break;
        
      default:
        _currentSceneType = SceneType.corridor;
        _moveController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, state, child) {
        _updateAnimationState(state);
        
        return AnimatedBuilder(
          animation: Listenable.merge([_moveController, _turnController]),
          builder: (context, child) {
            double arrowDir = 0;
            if (_isTurning) {
              // Interpolate arrow direction
              arrowDir = _turnTarget * _turnController.value;
            } else if (_currentSceneType == SceneType.stairs) {
              arrowDir = -math.pi / 4;
            }

            final distance = state.currentInstruction?['distanceEstimate'] as double?;
            final distText = distance != null ? '${distance.toInt()} m' : null;

            return CustomPaint(
              painter: _VisualizerPainter(
                sceneType: _currentSceneType,
                movementProgress: _moveController.value,
                turnProgress: _turnController.value,
                arrowDirection: arrowDir,
                distanceText: distText,
                isTurning: _isTurning,
              ),
              size: Size.infinite,
            );
          },
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final SceneType sceneType;
  final double movementProgress;
  final double turnProgress;
  final double arrowDirection;
  final String? distanceText;
  final bool isTurning;

  _VisualizerPainter({
    required this.sceneType,
    required this.movementProgress,
    required this.turnProgress,
    required this.arrowDirection,
    this.distanceText,
    required this.isTurning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawBackground(canvas, size, cy);
    _drawWalls(canvas, size, cx, cy);

    // Overlays
    if (isTurning || sceneType == SceneType.stairs) {
      _drawArrow(canvas, size, cx, cy);
    } else if (sceneType == SceneType.corridor && !isTurning) {
       // Only show forward arrow if walking straight
       _drawForwardArrow(canvas, size, cx, cy);
    }

    if (distanceText != null) {
      _drawDistanceText(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Ceiling
    paint.color = const Color(0xFFF5F5F5); 
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cy), paint);

    // Floor
    paint.color = const Color(0xFFE0E0E0);
    canvas.drawRect(Rect.fromLTWH(0, cy, size.width, size.height/2), paint);
    
    // Floor grid feel
    paint.color = const Color(0xFFCCCCCC);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    // Vanishing point lines for perspective
    canvas.drawLine(Offset(size.width/2, cy), Offset(0, size.height), paint);
    canvas.drawLine(Offset(size.width/2, cy), Offset(size.width, size.height), paint);
  }

  void _drawWalls(Canvas canvas, Size size, double cx, double cy) {
     final paint = Paint()..style = PaintingStyle.fill;
     
     // Animation logic:
     double loopProgress = movementProgress % 1.0; 
     double scale = 0.3 * (1 - loopProgress * 0.5); // Subtle zoom effect
     
     // Turning Logic: Shift Vanishing Point
     double vanishingPointX = cx;
     if (isTurning) {
       scale = 0.25; // Static perspective depth
       
       // Calculate vanish shift
       // Left turn (angle < 0) -> Vanish point moves RIGHT
       // Right turn (angle > 0) -> Vanish point moves LEFT
       double shiftAmount = size.width * 1.5; // How far off-screen it goes
       
       if (arrowDirection < 0) { // LEFT TURN
         vanishingPointX = cx + (shiftAmount * turnProgress);
       } else { // RIGHT TURN
         vanishingPointX = cx - (shiftAmount * turnProgress);
       }
     }

     // Vanishing Point
     Offset vp = Offset(vanishingPointX, cy);

     // Wall Colors
     final leftWallColor = const Color(0xFFB0BEC5);
     final rightWallColor = const Color(0xFF90A4AE);
     final endWallColor = const Color(0xFFCFD8DC);

     // End Wall (Distance) across the vanishing point
     paint.color = endWallColor;
     double endRectW = size.width * scale * 2;
     double endRectH = size.height * scale * 2;
     Rect endRect = Rect.fromCenter(center: vp, width: endRectW, height: endRectH);
     
     // Only draw end wall if it's somewhat on screen
     if (endRect.left < size.width && endRect.right > 0) {
       canvas.drawRect(endRect, paint);
     }

     // Left Wall
     paint.color = leftWallColor;
     final leftPath = Path();
     leftPath.moveTo(0, 0); // Top Left Screen
     leftPath.lineTo(endRect.left, endRect.top); // Top Left End Wall
     leftPath.lineTo(endRect.left, endRect.bottom); // Bottom Left End Wall
     leftPath.lineTo(0, size.height); // Bottom Left Screen
     leftPath.close();
     canvas.drawPath(leftPath, paint);

     // Right Wall
     paint.color = rightWallColor;
     final rightPath = Path();
     rightPath.moveTo(size.width, 0);
     rightPath.lineTo(endRect.right, endRect.top);
     rightPath.lineTo(endRect.right, endRect.bottom);
     rightPath.lineTo(size.width, size.height);
     rightPath.close();
     canvas.drawPath(rightPath, paint);
     
     // Junction logic (openings)
     if (sceneType == SceneType.junction) {
        paint.color = const Color(0xFFE0E0E0); // Floor color extend
        // If turning left, show opening on left
        if (arrowDirection < 0) {
           canvas.drawRect(Rect.fromLTWH(0, size.height*0.3, size.width*0.15, size.height*0.4), paint);
        }
        // If turning right, show opening on right
        if (arrowDirection > 0) {
           canvas.drawRect(Rect.fromLTWH(size.width*0.85, size.height*0.3, size.width*0.15, size.height*0.4), paint);
        }
     }

     // Landmarks (anchored to vanishing point rectangle)
     if (sceneType == SceneType.lift) {
       _drawLiftDoors(canvas, endRect);
     } else if (sceneType == SceneType.room) {
       _drawRoomDoor(canvas, endRect);
     }
  }

  void _drawLiftDoors(Canvas canvas, Rect endRect) {
     final paint = Paint()..color = const Color(0xFF546E7A);
     double doorW = endRect.width * 0.4;
     double doorH = endRect.height * 0.8;
     double cx = endRect.center.dx;
     double cy = endRect.center.dy;
     double gap = movementProgress * 20;
     
     canvas.drawRect(Rect.fromLTWH(cx - doorW - gap/2, cy - doorH/2, doorW, doorH), paint);
     canvas.drawRect(Rect.fromLTWH(cx + gap/2, cy - doorH/2, doorW, doorH), paint);
     
     // Frame
     paint.style = PaintingStyle.stroke;
     paint.strokeWidth = 3;
     paint.color = Colors.black54;
     canvas.drawRect(Rect.fromLTWH(cx - doorW*2.1/2, cy - doorH/2 - 5, doorW*2.1, doorH + 10), paint);
  }

  void _drawRoomDoor(Canvas canvas, Rect endRect) {
      final paint = Paint()..color = const Color(0xFF8D6E63);
      paint.style = PaintingStyle.fill;
      double w = endRect.width * 0.5;
      double h = endRect.height * 0.7;
      canvas.drawRect(Rect.fromCenter(center: endRect.center, width: w, height: h), paint);
      
      // Knob
      paint.color = Colors.amber;
      canvas.drawCircle(Offset(endRect.center.dx + w*0.3, endRect.center.dy), w*0.1, paint);
  }
  
  void _drawArrow(Canvas canvas, Size size, double cx, double cy) {
    if (arrowDirection.abs() < 0.1) return; // Don't draw generic arrow if straight

    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, size.height * 0.8); // Position lower on screen
    canvas.rotate(arrowDirection);

    final arrowPath = Path()
      ..moveTo(0, -30)
      ..lineTo(20, 10)
      ..lineTo(8, 10)
      ..lineTo(8, 30)
      ..lineTo(-8, 30)
      ..lineTo(-8, 10)
      ..lineTo(-20, 10)
      ..close();

    canvas.drawPath(arrowPath, paint);
    canvas.restore();
  }

  void _drawForwardArrow(Canvas canvas, Size size, double cx, double cy) {
     final paint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.6 + math.sin(movementProgress * math.pi) * 0.2)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, size.height * 0.8);
    
    // Simple chevron pointing up
    final path = Path()
      ..moveTo(0, -20)
      ..lineTo(20, 10)
      ..lineTo(0, 0) // Notch
      ..lineTo(-20, 10)
      ..close();
      
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawDistanceText(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.15), // Move to top
    );
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.movementProgress != movementProgress ||
           oldDelegate.turnProgress != turnProgress ||
           oldDelegate.sceneType != sceneType ||
           oldDelegate.arrowDirection != arrowDirection;
  }
}
