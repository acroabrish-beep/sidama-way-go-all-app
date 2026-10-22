import 'package:cloud_firestore/cloud_firestore.dart';
import 'taxi_service.dart';
import 'transport_intelligence_service.dart';
import 'emergency_dispatch_service.dart';
import 'financial_service.dart';

class CityOSService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TaxiService fleet = TaxiService();
  final TransportIntelligenceService intelligence = TransportIntelligenceService();
  final EmergencyDispatchService emergency = EmergencyDispatchService();
  final FinancialService finance = FinancialService();

  // --- SYSTEM HEALTH MONITOR ---

  Stream<double> getSystemHealthScore() {
    return intelligence.getCityKPIs().map((kpi) => kpi.cityHealthScore);
  }

  // --- EXPO 2026 DEMO MODE ---

  static bool isDemoMode = false;

  Future<void> toggleDemoMode(bool active) async {
    isDemoMode = active;
    if (active) {
      await _db.collection('settings').doc('system').set({
        'mode': 'EXPO_DEMO',
        'simulationActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // --- UNIFIED CITY DISPATCH ---

  Future<void> executeCityAction(String action, Map<String, dynamic> params) async {
    // Logic: Unified entry point for all high-level admin operations
    switch (action) {
      case 'DISPATCH_EMERGENCY':
        await emergency.dispatchUnits(params['incidentId'], params['vehicleIds'], params['commanderId']);
        break;
      case 'RE分配_FLEET':
        await fleet.transferVehicle(params['vehicleId'], params['toHubId'], reason: 'AI Optimization');
        break;
      case 'CLOSE_HUB':
        await _db.collection('taxi_stations').doc(params['hubId']).update({'isOperational': false});
        break;
    }
  }

  // --- BACKGROUND AUTOMATION TRIGGERS ---

  Future<void> runMaintenanceCycle() async {
    // This would typically be a Cloud Function, but we expose it for manual city maintenance
    await fleet.fixMissingStationIds();
    await intelligence.updateCityIntelligence();
  }
}
