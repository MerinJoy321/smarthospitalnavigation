import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../graph/graph_loader.dart';
import '../../graph/graph_data.dart';
import '../../state/navigation_state.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

class FloorMapView extends StatelessWidget {
  final int floor;
  final double width;
  final double height;

  const FloorMapView({
    super.key,
    required this.floor,
    this.width = 400,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationState>(
      builder: (context, state, child) {
        // Determine map asset based on floor
        String assetName;
        switch (floor) {
          case 0:
            assetName = 'assets/maps/floor_0.svg';
            break;
          case 1:
            assetName = 'assets/maps/floor_1.svg';
            break;
          case 2:
            assetName = 'assets/maps/floor_2.svg';
            break;
          default:
            assetName = 'assets/maps/floor_0.svg';
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Map Background SVG
                Positioned.fill(
                  child: SvgPicture.asset(
                    assetName,
                    fit: BoxFit.contain, // Respect aspect ratio
                    placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
                
                // 2. Graph/Route Overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FloorMapPainter(
                      floor: floor,
                      currentNode: state.currentNode,
                      destinationNodeId: state.destinationNode,
                      route: state.currentRoute,
                      width: width,
                      height: height,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloorMapPainter extends CustomPainter {
  final int floor;
  final String? currentNode;
  final String? destinationNodeId;
  final List<String> route;
  final double width;
  final double height;

  _FloorMapPainter({
    required this.floor,
    this.currentNode,
    this.destinationNodeId,
    required this.route,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!GraphLoader.isLoaded) return;

    final graph = GraphLoader.graph;
    final nodes = graph.getNodesOnFloor(floor);

    if (nodes.isEmpty) return;

    // SVG viewBox dimensions (from floor SVG files)
    // All floor maps use viewBox="0 0 1000 600"
    const double svgWidth = 1000.0;
    const double svgHeight = 600.0;

    // Calculate scale to fit SVG viewBox into widget size (BoxFit.contain)
    // This matches how SvgPicture.asset renders with fit: BoxFit.contain
    final double scale = math.min(
      size.width / svgWidth,
      size.height / svgHeight
    );
    
    // Calculate offsets to center the scaled content
    final double dx = (size.width - svgWidth * scale) / 2;
    final double dy = (size.height - svgHeight * scale) / 2;

    // Transform from SVG coordinates to screen coordinates
    Offset toScreen(double x, double y) {
      return Offset(x * scale + dx, y * scale + dy);
    }

    // Draw floor label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Floor $floor',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));

    // Draw edges (very subtle to avoid visual clutter)
    final edgePaint = Paint()
      ..color = Colors.grey.shade300.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      final edges = graph.getEdgesFrom(node.id);
      for (final edge in edges) {
        final toNode = graph.getNode(edge.to);
        if (toNode != null && toNode.floor == floor) {
          canvas.drawLine(
            toScreen(node.x, node.y),
            toScreen(toNode.x, toNode.y),
            edgePaint,
          );
        }
      }
    }

    // Draw route (G3: Route Rendering Correction)
    if (route.isNotEmpty) {
      final routePaint = Paint()
        ..color = Colors.blue.shade600
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round; // Smooth corners

      final routePath = Path();
      bool started = false;

      for (int i = 0; i < route.length - 1; i++) {
        final fromId = route[i];
        final toId = route[i+1];
        
        final fromNode = graph.getNode(fromId);
        final toNode = graph.getNode(toId);

        if (fromNode == null || toNode == null || fromNode.floor != floor || toNode.floor != floor) {
          // If nodes are on different floors, we don't draw connection here 
          // (assuming lift/stairs are handled logic-wise, visual break is fine)
          if (fromNode != null && fromNode.floor == floor) {
             // Just ensure we start the path if we have a point on this floor
             final pos = toScreen(fromNode.x, fromNode.y);
             if (!started) {
                routePath.moveTo(pos.dx, pos.dy);
                started = true;
             }
          }
          continue;
        }

        // Try to find edge with polyline
        List<Offset>? polylinePoints;
        final edges = graph.getEdgesFrom(fromId);
        try {
          final edge = edges.firstWhere((e) => e.to == toId);
          if (edge.polyline != null) {
            polylinePoints = edge.polyline!.map((p) => toScreen(p['x']!, p['y']!)).toList();
          }
        } catch (_) {}

        if (polylinePoints != null && polylinePoints.isNotEmpty) {
           // Draw polyline segments
           if (!started) {
             routePath.moveTo(polylinePoints.first.dx, polylinePoints.first.dy);
             started = true;
           }
           for (final point in polylinePoints) {
             routePath.lineTo(point.dx, point.dy);
           }
        } else {
           // Fallback: Straight line
           final fromPos = toScreen(fromNode.x, fromNode.y);
           final toPos = toScreen(toNode.x, toNode.y);
           
           if (!started) {
             routePath.moveTo(fromPos.dx, fromPos.dy);
             started = true;
           }
           routePath.lineTo(toPos.dx, toPos.dy);
        }
      }
      
      // Handle single point case (start node only)
      if (route.length == 1 && !started) {
          final node = graph.getNode(route.first);
          if (node != null && node.floor == floor) {
              // Just move to start, nothing to draw line-wise
          }
      }

      canvas.drawPath(routePath, routePaint);
    }

    // INTERNAL NODES ARE HIDDEN (Per Final Lock Contract)
    // We do NOT draw the node circles anymore. 
    // The underlying SVG map provides the visual context.


    // Draw current position indicator with animation halo
    if (currentNode != null) {
      final node = graph.getNode(currentNode!);
      if (node != null && node.floor == floor) {
        final pos = toScreen(node.x, node.y);
        
        // Halo (reduced size)
        final haloPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.green.withOpacity(0.6);
        canvas.drawCircle(pos, 20, haloPaint);
        
        // Dot (reduced size)
        final dotPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.green.shade700;
        canvas.drawCircle(pos, 8, dotPaint);
      }
    }

    // Draw Destination Pin (F2: UX Refinement)
    if (destinationNodeId != null) {
      final destNode = graph.getNode(destinationNodeId!);
      if (destNode != null && destNode.floor == floor) {
        // Use anchor if available, else fallback to node position
        double destX = destNode.anchor?['x'] ?? destNode.x;
        double destY = destNode.anchor?['y'] ?? destNode.y;
        
        final destPos = toScreen(destX, destY);
        _drawDestinationPin(canvas, destPos);
      }
    }
  }

  void _drawDestinationPin(Canvas canvas, Offset pos) {
    // Draw a Google Maps style pin (reduced size)
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    // Pin head (reduced size)
    canvas.drawCircle(Offset(pos.dx, pos.dy - 20), 12, paint);
    
    // Pin point (adjusted for smaller size)
    final path = Path();
    path.moveTo(pos.dx - 12, pos.dy - 20);
    path.lineTo(pos.dx + 12, pos.dy - 20);
    path.lineTo(pos.dx, pos.dy); // Point tip
    path.close();
    canvas.drawPath(path, paint);
    
    // White dot in center (adjusted for smaller size)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(pos.dx, pos.dy - 20), 4, paint);
  }

  @override
  bool shouldRepaint(covariant _FloorMapPainter oldDelegate) {
    return oldDelegate.floor != floor ||
        oldDelegate.currentNode != currentNode ||
        oldDelegate.destinationNodeId != destinationNodeId ||
        oldDelegate.route != route;
  }
}
