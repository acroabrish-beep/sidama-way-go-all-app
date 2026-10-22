import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

class CityKPI {
  final double cityHealthScore;
  final double fleetHealthScore;
  final double stationHealthScore;
  final double workforceHealthScore;
  final double passengerSatisfaction;
  final double trafficEfficiency;
  final double emergencyReadiness;

  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double totalRevenue;
  final int activePassengers;

  final DateTime updatedAt;

  CityKPI({
    required this.cityHealthScore,
    required this.fleetHealthScore,
    required this.stationHealthScore,
    required this.workforceHealthScore,
    this.passengerSatisfaction = 4.8,
    this.trafficEfficiency = 0.85,
    this.emergencyReadiness = 0.98,
    required this.totalTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.totalRevenue,
    required this.activePassengers,
    required this.updatedAt,
  });

  factory CityKPI.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CityKPI(
      cityHealthScore: (data['cityHealthScore'] ?? 100.0).toDouble(),
      fleetHealthScore: (data['fleetHealthScore'] ?? 100.0).toDouble(),
      stationHealthScore: (data['stationHealthScore'] ?? 100.0).toDouble(),
      workforceHealthScore: (data['workforceHealthScore'] ?? 100.0).toDouble(),
      passengerSatisfaction: (data['passengerSatisfaction'] ?? 4.8).toDouble(),
      trafficEfficiency: (data['trafficEfficiency'] ?? 0.85).toDouble(),
      emergencyReadiness: (data['emergencyReadiness'] ?? 0.98).toDouble(),
      totalTrips: (data['totalTrips'] ?? 0) as int,
      completedTrips: (data['completedTrips'] ?? 0) as int,
      cancelledTrips: (data['cancelledTrips'] ?? 0) as int,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      activePassengers: (data['activePassengers'] ?? 0) as int,
      updatedAt: FirestoreUtils.parseDateTimeOrDefault(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cityHealthScore': cityHealthScore,
      'fleetHealthScore': fleetHealthScore,
      'stationHealthScore': stationHealthScore,
      'workforceHealthScore': workforceHealthScore,
      'passengerSatisfaction': passengerSatisfaction,
      'trafficEfficiency': trafficEfficiency,
      'emergencyReadiness': emergencyReadiness,
      'totalTrips': totalTrips,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'totalRevenue': totalRevenue,
      'activePassengers': activePassengers,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

enum AlertType {
  stationFull,
  fleetShortage,
  driverMissing,
  vehicleOffline,
  maintenanceDue,
  emergencyOverload,
  trafficCongestion,
  fuelCritical,
  batteryCritical
}

enum AlertSeverity { low, medium, high, critical }

class OperationalAlert {
  final String alertId;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String referenceId;
  final DateTime timestamp;
  final bool isResolved;

  OperationalAlert({
    required this.alertId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.referenceId,
    required this.timestamp,
    this.isResolved = false,
  });

  factory OperationalAlert.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return OperationalAlert(
      alertId: doc.id,
      type: AlertType.values.firstWhere((e) => e.name == data['type'], orElse: () => AlertType.trafficCongestion),
      severity: AlertSeverity.values.firstWhere((e) => e.name == data['severity'], orElse: () => AlertSeverity.medium),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      referenceId: data['referenceId'] ?? '',
      timestamp: FirestoreUtils.parseDateTimeOrDefault(data['timestamp']),
      isResolved: data['isResolved'] ?? false,
    );
  }
}

class SmartRecommendation {
  final String recId;
  final String title;
  final String action;
  final String reason;
  final double impactScore;
  final String type; // DISPATCH, TRANSFER, SHIFT, MAINTENANCE
  final DateTime timestamp;

  SmartRecommendation({
    required this.recId,
    required this.title,
    required this.action,
    required this.reason,
    required this.impactScore,
    required this.type,
    required this.timestamp,
  });

  factory SmartRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SmartRecommendation(
      recId: doc.id,
      title: data['title'] ?? '',
      action: data['action'] ?? '',
      reason: data['reason'] ?? '',
      impactScore: (data['impactScore'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'DISPATCH',
      timestamp: FirestoreUtils.parseDateTimeOrDefault(data['timestamp']),
    );
  }
}
