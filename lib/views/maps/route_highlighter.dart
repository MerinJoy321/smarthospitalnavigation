import 'package:flutter/material.dart';
import '../../graph/graph_loader.dart';

/// Widget for highlighting route on a map
/// Used as an overlay on floor maps
class RouteHighlighter extends StatelessWidget {
  final List<String> route;
  final int floor;
  final Color routeColor;
  final double strokeWidth;

  const RouteHighlighter({
    super.key,
    required this.route,
    required this.floor,
    this.routeColor = Colors.blue,
    this.strokeWidth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RouteHighlightPainter(
        route: route,
        floor: floor,
        routeColor: routeColor,
        strokeWidth: strokeWidth,
      ),
      size: Size.infinite,
    );
  }
}

class _RouteHighlightPainter extends CustomPainter {
  final List<String> route;
  final int floor;
  final Color routeColor;
  final double strokeWidth;

  _RouteHighlightPainter({
    required this.route,
    required this.floor,
    required this.routeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!GraphLoader.isLoaded || route.isEmpty) return;

    final graph = GraphLoader.graph;
    final nodesOnFloor = graph.getNodesOnFloor(floor);

    if (nodesOnFloor.isEmpty) return;

    // Calculate bounds (same as FloorMapView)
    double minX = nodesOnFloor.first.x, maxX = nodesOnFloor.first.x;
    double minY = nodesOnFloor.first.y, maxY = nodesOnFloor.first.y;
    for (final node in nodesOnFloor) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
    }

    final padding = 40.0;
    final scaleX = (size.width - padding * 2) / (maxX - minX + 1);
    final scaleY = (size.height - padding * 2) / (maxY - minY + 1);
    final scale = scaleX < scaleY ? scaleX : scaleY;

    Offset toScreen(double x, double y) {
      return Offset(
        padding + (x - minX) * scale,
        padding + (y - minY) * scale,
      );
    }

    // Draw animated route
    final routePaint = Paint()
      ..color = routeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path();
    bool started = false;

    for (final nodeId in route) {
      final node = graph.getNode(nodeId);
      if (node != null && node.floor == floor) {
        final pos = toScreen(node.x, node.y);
        if (!started) {
          routePath.moveTo(pos.dx, pos.dy);
          started = true;
        } else {
          routePath.lineTo(pos.dx, pos.dy);
        }
      }
    }

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = strokeWidth + 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath.shift(const Offset(2, 2)), shadowPaint);

    // Draw route
    canvas.drawPath(routePath, routePaint);

    // Draw direction arrows along the route
    _drawDirectionArrows(canvas, route, toScreen, graph);
  }

  void _drawDirectionArrows(
    Canvas canvas,
    List<String> route,
    Offset Function(double, double) toScreen,
    dynamic graph,
  ) {
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < route.length - 1; i++) {
      final fromNode = graph.getNode(route[i]);
      final toNode = graph.getNode(route[i + 1]);

      if (fromNode == null || toNode == null) continue;
      if (fromNode.floor != floor || toNode.floor != floor) continue;

      final from = toScreen(fromNode.x, fromNode.y);
      final to = toScreen(toNode.x, toNode.y);

      // Calculate midpoint and direction
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final length = (dx * dx + dy * dy);
      if (length < 100) continue; // Skip short segments

      final angle = dx == 0 && dy == 0 ? 0.0 : (dy.sign * (dx.abs() / (dx.abs() + dy.abs())));
      
      // Draw small arrow
      canvas.save();
      canvas.translate(mid.dx, mid.dy);
      canvas.rotate(angle);
      
      final arrowPath = Path()
        ..moveTo(0, -6)
        ..lineTo(6, 6)
        ..lineTo(-6, 6)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RouteHighlightPainter oldDelegate) {
    return oldDelegate.route != route ||
        oldDelegate.floor != floor ||
        oldDelegate.routeColor != routeColor;
  }
}
