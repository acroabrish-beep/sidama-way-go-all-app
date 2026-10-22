import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/intelligence_models.dart';
import '../models/taxi_models.dart';

class TransportIntelligenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- REAL-TIME KPI STREAMS ---

  Stream<CityKPI> getCityKPIs() {
    return _db.collection('city_kpis').doc('current').snapshots().map((doc) {
      if (doc.exists) return CityKPI.fromFirestore(doc);
      // Return default if not initialized
      return CityKPI(
        cityHealthScore: 100,
        fleetHealthScore: 100,
        stationHealthScore: 100,
        workforceHealthScore: 100,
        totalTrips: 0,
        completedTrips: 0,
        cancelledTrips: 0,
        totalRevenue: 0.0,
        activePassengers: 0,
        updatedAt: DateTime.now(),
      );
    });
  }

  Stream<List<OperationalAlert>> getActiveAlerts() {
    return _db.collection('operational_alerts')
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => OperationalAlert.fromFirestore(d)).toList());
  }

  Stream<List<SmartRecommendation>> getTopRecommendations() {
    return _db.collection('system_recommendations')
        .orderBy('impactScore', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SmartRecommendation.fromFirestore(d)).toList());
  }

  // --- AUTOMATED AGGREGATION ENGINE ---

  Future<void> updateCityIntelligence() async {
    // Logic: Aggregates from all core transport collections
    final hubsSnap = await _db.collection('taxi_stations').get();
    final fleetSnap = await _db.collection('vehicles').get();

    final hubs = hubsSnap.docs.map((d) => TransportHub.fromFirestore(d)).toList();
    final fleet = fleetSnap.docs.map((d) => FleetVehicle.fromFirestore(d)).toList();
    // workforce data retrieved but not yet used for calculations

    // 1. Calculate Scores
    double fleetHealth = 100.0;
    if (fleet.isNotEmpty) {
      final maintenanceCount = fleet.where((v) => v.status == VehicleStatus.maintenance).length;
      final suspendedCount = fleet.where((v) => v.status == VehicleStatus.suspended).length;
      fleetHealth = 100.0 - ((maintenanceCount + suspendedCount * 2) / fleet.length * 100);
    }

    double stationHealth = 100.0;
    if (hubs.isNotEmpty) {
       final criticalCount = hubs.where((h) => h.healthStatus == StationHealth.critical || h.healthStatus == StationHealth.full).length;
       stationHealth = 100.0 - (criticalCount / hubs.length * 100);
    }

    // 2. Aggregate Totals
    int totalTrips = 0; // In a real app, count from ride_requests
    double revenue = 0.0;

    // 3. Update KPI Document
    final kpi = CityKPI(
      cityHealthScore: (fleetHealth + stationHealth) / 2,
      fleetHealthScore: fleetHealth,
      stationHealthScore: stationHealth,
      workforceHealthScore: 95.0, // mock
      totalTrips: totalTrips,
      completedTrips: 0,
      cancelledTrips: 0,
      totalRevenue: revenue,
      activePassengers: hubs.fold(0, (sumVal, h) => sumVal + h.queueLength),
      updatedAt: DateTime.now(),
    );

    await _db.collection('city_kpis').doc('current').set(kpi.toMap());

    // 4. Generate Auto-Alerts if needed
    if (stationHealth < 70) {
      await _db.collection('operational_alerts').add({
        'type': AlertType.emergencyOverload.name,
        'severity': AlertSeverity.high.name,
        'title': 'City Hub Overload',
        'description': 'Multiple transport hubs are reporting critical occupancy levels.',
        'timestamp': FieldValue.serverTimestamp(),
        'isResolved': false,
      });
    }
  }

  // --- PREDICTIVE FORECASTING ---

  Future<Map<String, dynamic>> getDemandForecast() async {
    // Logic: In a real app, this would use a cloud function calling Gemini or a ML model.
    // Here we simulate the enterprise predictive response.
    return {
      'peakHourForecast': '16:30 - 18:30',
      'expectedPassengerSpike': 45.0, // percentage
      'shortageRiskStations': ['Menaharia', 'Piassa'],
      'revenueProjection': 250000.0,
      'confidence': 0.92,
    };
  }
}
