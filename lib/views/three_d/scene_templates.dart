import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Scene types for 3D visualization
enum SceneType {
  corridor,
  junction,
  stairs,
  lift,
  entrance,
  room,
}

/// A simple 3D scene template using CustomPainter
/// This is a lightweight alternative to full 3D rendering
class SceneTemplate {
  final SceneType type;
  final String name;

  SceneTemplate({required this.type, required this.name});
}

/// Scene templates for different navigation contexts
class SceneTemplates {
  static final corridor = SceneTemplate(type: SceneType.corridor, name: 'Corridor');
  static final junction = SceneTemplate(type: SceneType.junction, name: 'Junction');
  static final stairs = SceneTemplate(type: SceneType.stairs, name: 'Stairs');
  static final lift = SceneTemplate(type: SceneType.lift, name: 'Lift');
  static final entrance = SceneTemplate(type: SceneType.entrance, name: 'Entrance');
  static final room = SceneTemplate(type: SceneType.room, name: 'Room');

  static SceneTemplate getForType(SceneType type) {
    switch (type) {
      case SceneType.corridor:
        return corridor;
      case SceneType.junction:
        return junction;
      case SceneType.stairs:
        return stairs;
      case SceneType.lift:
        return lift;
      case SceneType.entrance:
        return entrance;
      case SceneType.room:
        return room;
    }
  }
}

/// 3D scene widget using CustomPainter for lightweight rendering
class Scene3DWidget extends StatefulWidget {
  final SceneType sceneType;
  final double? arrowDirection; // Angle in radians, null for no arrow
  final String? distanceText;

  const Scene3DWidget({
    super.key,
    required this.sceneType,
    this.arrowDirection,
    this.distanceText,
  });

  @override
  State<Scene3DWidget> createState() => _Scene3DWidgetState();
}

class _Scene3DWidgetState extends State<Scene3DWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _Scene3DPainter(
            sceneType: widget.sceneType,
            arrowDirection: widget.arrowDirection,
            distanceText: widget.distanceText,
            animationValue: _animController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Scene3DPainter extends CustomPainter {
  final SceneType sceneType;
  final double? arrowDirection;
  final String? distanceText;
  final double animationValue;

  _Scene3DPainter({
    required this.sceneType,
    this.arrowDirection,
    this.distanceText,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw scene based on type
    switch (sceneType) {
      case SceneType.corridor:
        _drawCorridor(canvas, size, centerX, centerY);
        break;
      case SceneType.junction:
        _drawJunction(canvas, size, centerX, centerY);
        break;
      case SceneType.stairs:
        _drawStairs(canvas, size, centerX, centerY);
        break;
      case SceneType.lift:
        _drawLift(canvas, size, centerX, centerY);
        break;
      case SceneType.entrance:
        _drawEntrance(canvas, size, centerX, centerY);
        break;
      case SceneType.room:
        _drawRoom(canvas, size, centerX, centerY);
        break;
    }

    // Draw arrow overlay if direction is set
    if (arrowDirection != null) {
      _drawArrow(canvas, size, centerX, centerY);
    }

    // Draw distance text
    if (distanceText != null) {
      _drawDistanceText(canvas, size);
    }
  }

  void _drawCorridor(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    // Floor
    final floorPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.2, cy)
      ..lineTo(size.width * 0.8, cy)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.grey.shade400;
    canvas.drawPath(floorPath, paint);

    // Left wall
    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.2, cy)
      ..lineTo(0, size.height * 0.7)
      ..close();
    paint.color = Colors.blueGrey.shade200;
    canvas.drawPath(leftWall, paint);

    // Right wall
    final rightWall = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.8, cy)
      ..lineTo(size.width, size.height * 0.7)
      ..close();
    paint.color = Colors.blueGrey.shade300;
    canvas.drawPath(rightWall, paint);

    // Ceiling
    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width, 0)
      ..close();
    paint.color = Colors.grey.shade100;
    canvas.drawPath(ceiling, paint);
  }

  void _drawJunction(Canvas canvas, Size size, double cx, double cy) {
    _drawCorridor(canvas, size, cx, cy);

    // Add side openings
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // Left opening
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width * 0.15, cy * 0.8), width: 40, height: 60),
      paint,
    );

    // Right opening
    canvas.drawRect(
      Rect.fromCenter(center: Offset(size.width * 0.85, cy * 0.8), width: 40, height: 60),
      paint,
    );
  }

  void _drawStairs(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background
    paint.color = Colors.grey.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw steps
    paint.color = Colors.grey.shade400;
    final stepCount = 6;
    final stepHeight = size.height * 0.6 / stepCount;
    final stepWidth = size.width * 0.6;

    for (int i = 0; i < stepCount; i++) {
      final y = size.height * 0.3 + i * stepHeight;
      final stepRect = Rect.fromLTWH(
        (size.width - stepWidth) / 2,
        y,
        stepWidth - i * 20,
        stepHeight * 0.8,
      );
      canvas.drawRect(stepRect, paint);
      
      // Step edge
      paint.color = Colors.grey.shade300;
      canvas.drawRect(
        Rect.fromLTWH(stepRect.left, stepRect.top, stepRect.width, 4),
        paint,
      );
      paint.color = Colors.grey.shade400;
    }

    // Handrail
    final railPaint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.25, size.height * 0.9),
      railPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.9),
      railPaint,
    );
  }

  void _drawLift(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background wall
    paint.color = Colors.grey.shade300;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Lift doors
    final doorWidth = size.width * 0.35;
    final doorHeight = size.height * 0.65;
    final doorTop = size.height * 0.2;

    // Left door
    paint.color = Colors.blueGrey.shade400;
    canvas.drawRect(
      Rect.fromLTWH(cx - doorWidth - 2, doorTop, doorWidth, doorHeight),
      paint,
    );

    // Right door
    canvas.drawRect(
      Rect.fromLTWH(cx + 2, doorTop, doorWidth, doorHeight),
      paint,
    );

    // Door gap (opening animation)
    paint.color = Colors.grey.shade800;
    final gapWidth = animationValue * 20;
    canvas.drawRect(
      Rect.fromLTWH(cx - gapWidth / 2, doorTop, gapWidth, doorHeight),
      paint,
    );

    // Floor indicator
    paint.color = Colors.green;
    final indicatorRect = Rect.fromCenter(
      center: Offset(cx, doorTop - 20),
      width: 40,
      height: 20,
    );
    canvas.drawRect(indicatorRect, paint);
  }

  void _drawEntrance(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Exterior view
    paint.color = Colors.lightBlue.shade100;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.4), paint);

    // Building facade
    paint.color = Colors.grey.shade400;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6),
      paint,
    );

    // Door frame
    paint.color = Colors.brown.shade600;
    final doorWidth = size.width * 0.4;
    final doorHeight = size.height * 0.5;
    canvas.drawRect(
      Rect.fromLTWH(cx - doorWidth / 2 - 8, size.height * 0.45, doorWidth + 16, doorHeight + 8),
      paint,
    );

    // Glass door
    paint.color = Colors.lightBlue.shade200.withOpacity(0.7);
    canvas.drawRect(
      Rect.fromLTWH(cx - doorWidth / 2, size.height * 0.48, doorWidth, doorHeight),
      paint,
    );
  }

  void _drawRoom(Canvas canvas, Size size, double cx, double cy) {
    _drawCorridor(canvas, size, cx, cy);

    // Door at the end
    final paint = Paint()
      ..color = Colors.brown.shade400
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 60, height: 80),
      paint,
    );

    // Door handle
    paint.color = Colors.yellow.shade700;
    canvas.drawCircle(Offset(cx + 20, cy - 20), 5, paint);
  }

  void _drawArrow(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8 + 0.2 * math.sin(animationValue * 2 * math.pi))
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, size.height * 0.75);
    canvas.rotate(arrowDirection!);

    final arrowPath = Path()
      ..moveTo(0, -40)
      ..lineTo(25, 20)
      ..lineTo(10, 20)
      ..lineTo(10, 40)
      ..lineTo(-10, 40)
      ..lineTo(-10, 20)
      ..lineTo(-25, 20)
      ..close();

    canvas.drawPath(arrowPath, paint);
    canvas.restore();
  }

  void _drawDistanceText(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: distanceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _Scene3DPainter oldDelegate) {
    return oldDelegate.sceneType != sceneType ||
        oldDelegate.arrowDirection != arrowDirection ||
        oldDelegate.distanceText != distanceText ||
        oldDelegate.animationValue != animationValue;
  }
}
