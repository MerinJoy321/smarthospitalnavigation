import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/navigation_state.dart';
import 'scene_templates.dart';
import '../../graph/graph_loader.dart';
import 'dart:math' as math;

class NavigationVisualizer extends StatefulWidget {
  const NavigationVisualizer({super.key});

  @override
  State<NavigationVisualizer> createState() => _NavigationVisualizerState();
}

class _NavigationVisualizerState extends State<NavigationVisualizer> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _turnController;
  late AnimationController _verticalController; // New for floor changes
  
  // Local state to track transitions
  int _lastInstructionIndex = -1;
  SceneType _currentSceneType = SceneType.corridor;
  bool _isTurning = false;
  bool _isVertical = false; // New
  double _turnTarget = 0.0; // Target rotation
  int _floorDiff = 0; // New: -1 for down, 1 for up

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

    _verticalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _turnController.dispose();
    _verticalController.dispose();
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
      final fromId = instruction['fromNode'] as String?;
      final toId = instruction['toNode'] as String?;
      
      _updateSceneConfig(typeStr, fromId, toId);
    }
  }

  void _updateSceneConfig(String? typeStr, String? fromId, String? toId) {
    // Reset controllers
    _moveController.stop();
    _turnController.stop();
    _verticalController.stop();
    _turnController.value = 0;
    _verticalController.value = 0;
    _isVertical = false;
    _floorDiff = 0;

    // Detect floor difference for vertical movement
    if (fromId != null && toId != null && GraphLoader.isLoaded) {
      final f = GraphLoader.graph.getNode(fromId)?.floor ?? 0;
      final t = GraphLoader.graph.getNode(toId)?.floor ?? 0;
      _floorDiff = t - f;
    }
    
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
        _isVertical = true;
        _verticalController.repeat(); // Loop vertical scroll
        break;
        
      case 'takeLift':
        _currentSceneType = SceneType.lift;
        _isTurning = false;
        _isVertical = true;
        _moveController.repeat(reverse: true); // Pulse door
        _verticalController.repeat(); // Loop vertical scroll
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
          animation: Listenable.merge([_moveController, _turnController, _verticalController]),
          builder: (context, child) {
            double arrowRot = 0;

            if (_isTurning) {
              arrowRot = _turnTarget * _turnController.value;
            } else if (_isVertical) {
               // Vertical arrow logic: 0 is up, pi/2 is right, pi is down...
               // Wait, my _drawArrow takes rotation. 0 is up.
               arrowRot = _floorDiff > 0 ? 0 : math.pi;
            }

            final distance = state.currentInstruction?['distanceEstimate'] as double?;
            final distText = distance != null && distance > 0 ? '${distance.toInt()} m' : null;

            return CustomPaint(
              painter: _VisualizerPainter(
                sceneType: _currentSceneType,
                movementProgress: _moveController.value,
                turnProgress: _turnController.value,
                verticalProgress: _verticalController.value,
                arrowDirection: arrowRot,
                distanceText: distText,
                isTurning: _isTurning,
                isVertical: _isVertical,
                floorDiff: _floorDiff,
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
  final double verticalProgress;
  final double arrowDirection;
  final String? distanceText;
  final bool isTurning;
  final bool isVertical;
  final int floorDiff;

  _VisualizerPainter({
    required this.sceneType,
    required this.movementProgress,
    required this.turnProgress,
    required this.verticalProgress,
    required this.arrowDirection,
    this.distanceText,
    required this.isTurning,
    required this.isVertical,
    required this.floorDiff,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawPremiumScene(canvas, size, cx, cy);

    if (distanceText != null) {
      _drawDistanceHeader(canvas, size);
    }

    if (isVertical) {
      _drawVerticalCues(canvas, size, cx, cy);
    } else {
      _drawNavigationCues(canvas, size, cx, cy);
    }
  }

  void _drawPremiumScene(Canvas canvas, Size size, double cx, double cy) {
    // 1. Perspective Setup
    double vanishX = cx;
    if (isTurning) {
      double shift = size.width * 1.8;
      vanishX = arrowDirection < 0 ? cx + (shift * turnProgress) : cx - (shift * turnProgress);
    }
    Offset vp = Offset(vanishX, cy);

    // 2. Continuous Motion Surfaces
    _drawDeepGrid(canvas, size, vp, isFloor: true);
    _drawDeepGrid(canvas, size, vp, isFloor: false); // Ceiling
    
    // 3. Side Walls with Scrolling Panels
    _drawTexturedWalls(canvas, size, vp);

    // 4. Scene Assets
    if (sceneType == SceneType.lift) {
       _drawPremiumLiftCabin(canvas, size, vp);
    } else if (sceneType == SceneType.room) {
       _drawPremiumDoor(canvas, size, vp);
    } else if (sceneType == SceneType.junction) {
       _drawPremiumJunction(canvas, size, vp);
    }
  }

  void _drawDeepGrid(Canvas canvas, Size size, Offset vp, {required bool isFloor}) {
    final paint = Paint()
      ..color = isFloor ? const Color(0xFFD0D0D0) : const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;
    
    final yBound = isFloor ? vp.dy : 0.0;
    final h = isFloor ? size.height - vp.dy : vp.dy;
    canvas.drawRect(Rect.fromLTWH(0, yBound, size.width, h), paint);

    final gridPaint = Paint()
      ..color = Colors.black.withAlpha(isFloor ? 40 : 20)
      ..strokeWidth = 1.5;

    // Longitudinal (Radial)
    for (double i = -3; i <= 4; i += 0.5) {
       canvas.drawLine(vp, Offset(size.width * (0.5 + i), isFloor ? size.height : 0), gridPaint);
    }

    // Transverse (Scrolling)
    double progress = movementProgress % 1.0;
    for (int i = 0; i < 15; i++) {
        double density = (i.toDouble() - progress) / 15.0;
        if (density < 0 || density > 1.0) continue;
        
        // Logarithmic spacing for depth
        double expZ = math.pow(density, 1.5).toDouble();
        double yPos = isFloor ? vp.dy + (size.height - vp.dy) * expZ : vp.dy - vp.dy * expZ;
        double w = size.width * density * 2;
        canvas.drawLine(Offset(vp.dx - w, yPos), Offset(vp.dx + w, yPos), gridPaint);
    }
  }

  void _drawTexturedWalls(Canvas canvas, Size size, Offset vp) {
    final paint = Paint()..style = PaintingStyle.fill;
    const scale = 0.15; // Deeper perspective
    Rect endRect = Rect.fromCenter(center: vp, width: size.width * scale, height: size.height * scale);

    // Main Wall Base
    paint.color = const Color(0xFFB0BEC5);
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(endRect.left, endRect.top)..lineTo(endRect.left, endRect.bottom)..lineTo(0, size.height)..close(), paint);
    paint.color = const Color(0xFF90A4AE);
    canvas.drawPath(Path()..moveTo(size.width, 0)..lineTo(endRect.right, endRect.top)..lineTo(endRect.right, endRect.bottom)..lineTo(size.width, size.height)..close(), paint);

    // Wall Panels (Motion)
    final panelPaint = Paint()..color = Colors.black.withAlpha(15)..strokeWidth = 2;
    double progress = movementProgress % 1.0;
    for (int i = 0; i < 10; i++) {
       double density = (i.toDouble() - progress) / 10.0;
       if (density < 0) continue;
       
       double xL = vp.dx - (vp.dx * (1 - density));
       double xR = vp.dx + ((size.width - vp.dx) * (1 - density));
       double wallH = size.height * density;
       
       // Vertical panel lines
       canvas.drawLine(Offset(xL, vp.dy - wallH/2), Offset(xL, vp.dy + wallH/2), panelPaint);
       canvas.drawLine(Offset(xR, vp.dy - wallH/2), Offset(xR, vp.dy + wallH/2), panelPaint);
    }
  }

  void _drawPremiumLiftCabin(Canvas canvas, Size size, Offset vp) {
     final paint = Paint()..color = const Color(0xFF455A64);
     double w = size.width * 0.4;
     double h = size.height * 0.5;
     Rect cabin = Rect.fromCenter(center: vp, width: w, height: h);
     canvas.drawRect(cabin, paint);
     
     // Sliding Door Effect
     paint.color = const Color(0xFF37474F);
     double doorW = cabin.width * 0.45;
     double gap = movementProgress * 25;
     canvas.drawRect(Rect.fromLTWH(vp.dx - doorW - gap, cabin.top + 5, doorW, cabin.height - 10), paint);
     canvas.drawRect(Rect.fromLTWH(vp.dx + gap, cabin.top + 5, doorW, cabin.height - 10), paint);
  }

  void _drawPremiumDoor(Canvas canvas, Size size, Offset vp) {
     double w = size.width * 0.25;
     double h = size.height * 0.4;
     Rect door = Rect.fromCenter(center: vp, width: w, height: h);
     canvas.drawRect(door, Paint()..color = const Color(0xFF795548));
     canvas.drawCircle(Offset(door.right - 15, vp.dy), 6, Paint()..color = Colors.amber);
  }

  void _drawPremiumJunction(Canvas canvas, Size size, Offset vp) {
     final paint = Paint()..color = const Color(0xFFD0D0D0);
     if (isTurning || arrowDirection.abs() > 0.1) {
       if (arrowDirection < 0 || isTurning) { // Left
         canvas.drawRect(Rect.fromLTWH(0, size.height*0.25, size.width*0.12, size.height*0.5), paint);
       }
       if (arrowDirection > 0 || isTurning) { // Right
         canvas.drawRect(Rect.fromLTWH(size.width*0.88, size.height*0.25, size.width*0.12, size.height*0.5), paint);
       }
     }
  }

  void _drawNavigationCues(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()
      ..color = Colors.teal.shade700.withAlpha(220)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, size.height * 0.82);
    if (isTurning) canvas.rotate(arrowDirection);

    final path = Path()
      ..moveTo(0, -45)..lineTo(25, 5)..lineTo(12, 5)..lineTo(12, 35)
      ..lineTo(-12, 35)..lineTo(-12, 5)..lineTo(-25, 5)..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawVerticalCues(Canvas canvas, Size size, double cx, double cy) {
     // Motion Lines
     final linePaint = Paint()..color = Colors.white.withAlpha(120)..strokeWidth = 3;
     double offset = (verticalProgress * 60) * (floorDiff > 0 ? 1 : -1);
     for (int i = -1; i < 12; i++) {
        double y = (i * 60 + offset) % size.height;
        canvas.drawLine(Offset(0, y), Offset(size.width * 0.15, y), linePaint);
        canvas.drawLine(Offset(size.width * 0.85, y), Offset(size.width, y), linePaint);
     }

     // Giant Arrow
     final paint = Paint()..color = Colors.blue.shade800.withAlpha(240)..style = PaintingStyle.fill;
     canvas.save();
     canvas.translate(cx, size.height * 0.75);
     canvas.rotate(floorDiff > 0 ? 0 : math.pi);
     canvas.drawPath(Path()..moveTo(0, -60)..lineTo(35, 10)..lineTo(15, 10)..lineTo(15, 50)..lineTo(-15, 50)..lineTo(-15, 10)..lineTo(-35, 10)..close(), paint);
     canvas.restore();

     final label = floorDiff > 0 ? "GO UP" : "GO DOWN";
     final tp = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.black)])), textDirection: TextDirection.ltr)..layout();
     tp.paint(canvas, Offset(cx - tp.width/2, size.height * 0.85 + 20));
  }

  void _drawDistanceHeader(Canvas canvas, Size size) {
    final tp = TextPainter(text: TextSpan(text: distanceText, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 4))])), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.08));
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.movementProgress != movementProgress ||
           oldDelegate.turnProgress != turnProgress ||
           oldDelegate.verticalProgress != verticalProgress ||
           oldDelegate.sceneType != sceneType ||
           oldDelegate.arrowDirection != arrowDirection ||
           oldDelegate.isVertical != isVertical ||
           oldDelegate.isTurning != isTurning ||
           oldDelegate.floorDiff != floorDiff;
  }
}
