import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../services.dart';
import 'street_view_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.navigationRoute,
    required this.updatesService,
  });

  final NavigationRoute navigationRoute;
  final UpdatesService updatesService;

  @override
  Widget build(BuildContext context) {
    final route = navigationRoute;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Route to ${route.pathNodes.isNotEmpty ? route.pathNodes.last.name : ''}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Stack(
                    children: [
                      _RouteMapView(route: route),
                      Positioned(
                        left: 12,
                        top: 12,
                        right: 12,
                        child: StreamBuilder<List<Alert>>(
                          stream: updatesService.alertsStream,
                          initialData: updatesService.currentAlerts,
                          builder: (context, snapshot) {
                            final activeAlerts = (snapshot.data ?? [])
                                .where((a) => a.isActive)
                                .toList();
                            if (activeAlerts.isEmpty) return const SizedBox();
                            final alert = activeAlerts.first;
                            return _AlertBanner(alert: alert);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Turn‑by‑turn directions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${route.totalDistanceMeters.toStringAsFixed(0)} m',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: route.steps.length,
                      itemBuilder: (context, index) {
                        final step = route.steps[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              '${step.order}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(step.instruction),
                          subtitle: Text(
                            'From ${step.from.name} to ${step.to.name}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StreetViewScreen(
                              navigationRoute: route,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('Open visual guide'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMapView extends StatelessWidget {
  const _RouteMapView({required this.route});

  final NavigationRoute route;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(80),
          child: CustomPaint(
            size: Size(
              constraints.maxWidth,
              constraints.maxHeight,
            ),
            painter: _RouteMapPainter(route: route),
          ),
        );
      },
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({required this.route});

  final NavigationRoute route;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.map.nodes.isEmpty) return;

    // Compute bounds of all nodes.
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in route.map.nodes) {
      minX = math.min(minX, node.position.dx);
      maxX = math.max(maxX, node.position.dx);
      minY = math.min(minY, node.position.dy);
      maxY = math.max(maxY, node.position.dy);
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final scale = 0.8 *
        math.min(
          size.width / (width == 0 ? 1 : width),
          size.height / (height == 0 ? 1 : height),
        );
    final offset = Offset(
      size.width / 2 - (minX + width / 2) * scale,
      size.height / 2 - (minY + height / 2) * scale,
    );

    Offset project(Offset p) => Offset(
          p.dx * scale + offset.dx,
          p.dy * scale + offset.dy,
        );

    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw all corridors.
    final corridorPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    for (final edge in route.map.edges) {
      final from = route.map.findNodeById(edge.fromId);
      final to = route.map.findNodeById(edge.toId);
      if (from == null || to == null) continue;
      canvas.drawLine(project(from.position), project(to.position), corridorPaint);
    }

    // Highlight route path.
    final pathPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < route.pathNodes.length - 1; i++) {
      final from = route.pathNodes[i];
      final to = route.pathNodes[i + 1];
      canvas.drawLine(
        project(from.position),
        project(to.position),
        pathPaint,
      );
    }

    // Draw nodes.
    final nodePaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;
    final departmentPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;
    final entrancePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (final node in route.map.nodes) {
      final p = project(node.position);
      final radius = node.isDepartment ? 7.0 : 5.0;
      final paint = node.isEntrance
          ? entrancePaint
          : (node.isDepartment ? departmentPaint : nodePaint);
      canvas.drawCircle(p, radius, paint);
    }

    // Labels for start/destination.
    if (route.pathNodes.isNotEmpty) {
      final start = route.pathNodes.first;
      final dest = route.pathNodes.last;
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      textPainter.text = TextSpan(
        text: 'Start',
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final startOffset = project(start.position) +
          const Offset(8, -4);
      textPainter.paint(canvas, startOffset);

      textPainter.text = TextSpan(
        text: 'Destination',
        style: const TextStyle(
          color: Colors.deepOrange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final destOffset = project(dest.position) +
          const Offset(8, -4);
      textPainter.paint(canvas, destOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.route != route;
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer
                          .withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

