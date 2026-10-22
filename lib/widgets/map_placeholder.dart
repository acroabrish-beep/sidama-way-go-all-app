import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Hawassa Map Placeholder for Web/Offline support with Live Simulation
class HawassaMapPlaceholder extends StatelessWidget {
  final LatLng? userLocation;
  final List<dynamic> markers; // Using dynamic to avoid conflicts with different Marker types
  final LatLng? destination;

  const HawassaMapPlaceholder({
    super.key,
    this.userLocation,
    required this.markers,
    this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: Stack(
        children: [
          // Background - Stylized Map Grid/Pattern
          CustomPaint(
            painter: MapPatternPainter(),
            size: Size.infinite,
          ),

          // User Location Indicator
          if (userLocation != null)
            _PositionedMarker(
              location: userLocation!,
              color: Colors.blue,
              icon: Icons.person_pin_circle,
              label: 'You',
            ),

          // Route Simulation (Explicit Path Line)
          if (userLocation != null && destination != null)
            CustomPaint(
              painter: RoutePainter(
                start: userLocation!,
                end: destination!,
              ),
              size: Size.infinite,
            ),

          // Live Moving Vehicles & Landmarks
          ...markers.map((m) {
             // Basic heuristic for marker visualization in placeholder
             return _PositionedMarker(
                location: m.point, // Assuming flutter_map Marker
                color: Colors.orange,
                icon: Icons.location_on,
                label: 'Entity',
              );
          }),

          // Destination Marker (if navigating)
          if (destination != null)
            _PositionedMarker(
              location: destination!,
              color: Colors.red,
              icon: Icons.flag,
              label: 'Destination',
            ),

          const Positioned(
            top: 10,
            right: 10,
            child: Chip(
              label: Text('Live City Simulation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionedMarker extends StatelessWidget {
  final LatLng location;
  final Color color;
  final IconData icon;
  final String label;

  const _PositionedMarker({
    required this.location,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Coordinate mapping for placeholder visual (Hawassa focused)
    // Hawassa approx: 7.05, 38.48
    double x = (location.longitude - 38.45) * 5000 + 100;
    double y = (7.10 - location.latitude) * 5000 + 100;

    return Positioned(
      left: x % (MediaQuery.of(context).size.width - 40),
      top: y % (MediaQuery.of(context).size.height - 200),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty && label != 'You')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)]
              ),
              child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Simulate main roads
    final roadPaint = Paint()..color = Colors.grey.shade300..strokeWidth = 15;
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  final LatLng start;
  final LatLng end;

  RoutePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double x1 = (start.longitude - 38.45) * 5000 + 100;
    double y1 = (7.10 - start.latitude) * 5000 + 100;
    double x2 = (end.longitude - 38.45) * 5000 + 100;
    double y2 = (7.10 - end.latitude) * 5000 + 100;

    double sx = x1 % (size.width - 40) + 15;
    double sy = y1 % (size.height - 200) + 15;
    double ex = x2 % (size.width - 40) + 15;
    double ey = y2 % (size.height - 200) + 15;

    canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
