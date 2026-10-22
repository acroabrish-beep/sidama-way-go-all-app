import 'package:cloud_firestore/cloud_firestore.dart';

enum MapEventType {
  trafficCongestion,
  roadClosure,
  accident,
  emergencyAlert,
  citizenRequest,
  stationOverloaded,
  weatherAlert
}

enum MapEventSeverity { low, medium, high, critical }

class MapEvent {
  final String eventId;
  final MapEventType type;
  final MapEventSeverity severity;
  final String title;
  final String description;
  final GeoPoint location;
  final DateTime timestamp;
  final bool isActive;

  MapEvent({
    required this.eventId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.location,
    required this.timestamp,
    this.isActive = true,
  });

  factory MapEvent.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MapEvent(
      eventId: doc.id,
      type: MapEventType.values.firstWhere((e) => e.name == data['type'], orElse: () => MapEventType.trafficCongestion),
      severity: MapEventSeverity.values.firstWhere((e) => e.name == data['severity'], orElse: () => MapEventSeverity.low),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] as GeoPoint? ?? const GeoPoint(7.0504, 38.4955),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

class CityHeatmapData {
  final String zoneId;
  final double intensity; // 0.0 to 1.0
  final GeoPoint center;
  final Map<String, dynamic> metadata;

  CityHeatmapData({
    required this.zoneId,
    required this.intensity,
    required this.center,
    this.metadata = const {},
  });
}
