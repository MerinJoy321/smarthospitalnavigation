import 'package:flutter/material.dart';

import '../models.dart';

class StreetViewScreen extends StatelessWidget {
  const StreetViewScreen({super.key, required this.navigationRoute});

  final NavigationRoute navigationRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = navigationRoute.steps;

    return Scaffold(
      appBar: AppBar(title: const Text('Visual corridor guide')),
      body: steps.isEmpty
          ? const Center(child: Text('No steps for this route.'))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      final isLast = index == steps.length - 1;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: _StreetViewCard(step: step, isLast: isLast),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Swipe horizontally to move along the route',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StreetViewCard extends StatelessWidget {
  const _StreetViewCard({required this.step, required this.isLast});

  final RouteStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Column(
        children: [
          // Simulated corridor visual.
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: CustomPaint(
                painter: _CorridorPainter(),
                child: Container(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '${step.order}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Step ${step.order}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(step.instruction, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  'From ${step.from.name} to ${step.to.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isLast ? Icons.flag : Icons.straighten,
                      color: isLast ? Colors.green : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLast
                            ? 'You have arrived at your destination.'
                            : 'Follow the corridor until you reach the next landmark.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CorridorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEFF3F8);
    canvas.drawRect(Offset.zero & size, background);

    final floor = Paint()..color = const Color(0xFFD0D9E8);
    final ceiling = Paint()..color = const Color(0xFFF5F7FB);
    final wall = Paint()..color = const Color(0xFFCAD4E4);

    final midY = size.height * 0.55;

    // Ceiling.
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, midY * 0.2), ceiling);

    // Floor (simple trapezoid effect).
    final floorPath = Path()
      ..moveTo(0, midY)
      ..lineTo(size.width, midY)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(floorPath, floor);

    // Left wall.
    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.25, midY * 0.2)
      ..lineTo(size.width * 0.25, midY)
      ..lineTo(0, midY)
      ..close();
    canvas.drawPath(leftWall, wall);

    // Right wall.
    final rightWall = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.75, midY * 0.2)
      ..lineTo(size.width * 0.75, midY)
      ..lineTo(size.width, midY)
      ..close();
    canvas.drawPath(rightWall, wall);

    // Door at the end.
    final doorWidth = size.width * 0.25;
    final doorHeight = size.height * 0.35;
    final doorRect = Rect.fromCenter(
      center: Offset(size.width / 2, midY * 0.65),
      width: doorWidth,
      height: doorHeight,
    );
    final doorPaint = Paint()..color = const Color(0xFF3F51B5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect, const Radius.circular(8)),
      doorPaint,
    );

    // Simple handle.
    final handlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(doorRect.center.dx + doorRect.width * 0.25, doorRect.center.dy),
      3,
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CorridorPainter oldDelegate) => false;
}
