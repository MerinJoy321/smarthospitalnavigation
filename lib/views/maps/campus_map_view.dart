import 'package:flutter/material.dart';

/// Campus level map showing building overview
class CampusMapView extends StatelessWidget {
  final String? selectedBuilding;
  final ValueChanged<String>? onBuildingSelected;

  const CampusMapView({
    super.key,
    this.selectedBuilding,
    this.onBuildingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _CampusMapPainter(
                selectedBuilding: selectedBuilding,
              ),
              child: GestureDetector(
                onTapUp: (details) {
                  // Simple hit testing for buildings
                  final building = _hitTestBuilding(details.localPosition);
                  if (building != null) {
                    onBuildingSelected?.call(building);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _hitTestBuilding(Offset position) {
    // Simple hit testing for demo buildings
    final buildings = {
      'Main Building': Rect.fromLTWH(50, 50, 100, 80),
      'Annex A': Rect.fromLTWH(200, 50, 80, 60),
      'Lab Building': Rect.fromLTWH(50, 180, 120, 70),
    };

    for (final entry in buildings.entries) {
      if (entry.value.contains(position)) {
        return entry.key;
      }
    }
    return null;
  }
}

class _CampusMapPainter extends CustomPainter {
  final String? selectedBuilding;

  _CampusMapPainter({this.selectedBuilding});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ground
    final groundPaint = Paint()
      ..color = Colors.green.shade200;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // Draw paths
    final pathPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(100, 130),
      const Offset(100, 180),
      pathPaint,
    );
    canvas.drawLine(
      const Offset(100, 130),
      const Offset(240, 80),
      pathPaint,
    );

    // Draw buildings
    _drawBuilding(canvas, 'Main Building', Rect.fromLTWH(50, 50, 100, 80));
    _drawBuilding(canvas, 'Annex A', Rect.fromLTWH(200, 50, 80, 60));
    _drawBuilding(canvas, 'Lab Building', Rect.fromLTWH(50, 180, 120, 70));

    // Draw entry points
    final entryPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(100, 130), 8, entryPaint);
    canvas.drawCircle(const Offset(240, 80), 8, entryPaint);
    canvas.drawCircle(const Offset(110, 180), 8, entryPaint);
  }

  void _drawBuilding(Canvas canvas, String name, Rect rect) {
    final isSelected = name == selectedBuilding;
    
    // Building shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(4, 4)), const Radius.circular(8)),
      shadowPaint,
    );

    // Building
    final buildingPaint = Paint()
      ..color = isSelected ? Colors.blue.shade300 : Colors.grey.shade300
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      buildingPaint,
    );

    // Building border
    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue.shade700 : Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      borderPaint,
    );

    // Building label
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: rect.width - 8);
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _CampusMapPainter oldDelegate) {
    return oldDelegate.selectedBuilding != selectedBuilding;
  }
}
