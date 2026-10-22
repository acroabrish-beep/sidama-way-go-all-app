import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/emergency_models.dart';
import '../models/taxi_models.dart';
import 'notification_service.dart';

class EmergencyDispatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- INCIDENT LIFECYCLE ---

  Future<String> reportIncident(EmergencyIncident incident) async {
    final docRef = await _db.collection('emergency_incidents').add(incident.toMap());

    // Auto-Alert dispatchers
    await NotificationService.sendNotification(
      userId: 'emergency_dispatcher_group',
      title: 'NEW INCIDENT: ${incident.type.name.toUpperCase()}',
      message: '${incident.priority.name.toUpperCase()} priority incident at ${incident.address}',
      type: 'emergency_incident',
      referenceId: docRef.id,
    );

    return docRef.id;
  }

  Stream<List<EmergencyIncident>> getActiveIncidents() {
    return _db.collection('emergency_incidents')
        .where('status', whereIn: [
          IncidentStatus.reported.name,
          IncidentStatus.aiClassified.name,
          IncidentStatus.dispatcherReviewed.name,
          IncidentStatus.unitAssigned.name,
          IncidentStatus.enRoute.name,
          IncidentStatus.onScene.name,
          IncidentStatus.resolving.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EmergencyIncident.fromFirestore(d)).toList());
  }

  // --- SMART DISPATCH ENGINE ---

  Future<List<FleetVehicle>> findNearestUnits(GeoPoint location, VehicleType type, {int limit = 3}) async {
    final snap = await _db.collection('vehicles')
        .where('vehicleType', isEqualTo: type.name)
        .where('status', isEqualTo: VehicleStatus.available.name)
        .where('approvalStatus', isEqualTo: 'approved')
        .get();

    final units = snap.docs.map((d) => FleetVehicle.fromFirestore(d)).toList();

    units.sort((a, b) {
      if (a.gpsLocation == null || b.gpsLocation == null) return 0;
      double distA = Geolocator.distanceBetween(location.latitude, location.longitude, a.gpsLocation!.latitude, a.gpsLocation!.longitude);
      double distB = Geolocator.distanceBetween(location.latitude, location.longitude, b.gpsLocation!.latitude, b.gpsLocation!.longitude);
      return distA.compareTo(distB);
    });

    return units.take(limit).toList();
  }

  Future<void> dispatchUnits(String incidentId, List<String> vehicleIds, String commanderId) async {
    await _db.runTransaction((transaction) async {
      final incidentRef = _db.collection('emergency_incidents').doc(incidentId);

      transaction.update(incidentRef, {
        'status': IncidentStatus.unitAssigned.name,
        'assignedVehicleIds': vehicleIds,
        'assignedCommanderId': commanderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var vid in vehicleIds) {
        final vRef = _db.collection('vehicles').doc(vid);
        transaction.update(vRef, {
          'status': VehicleStatus.emergency.name,
          'currentTripId': incidentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // --- HOSPITAL INTELLIGENCE ---

  Stream<List<HospitalCapacity>> getHospitalStatus() {
    return _db.collection('hospital_capacity')
        .snapshots()
        .map((snap) => snap.docs.map((d) => HospitalCapacity.fromFirestore(d)).toList());
  }

  Future<HospitalCapacity> findBestHospital(GeoPoint incidentLoc) async {
    final snap = await _db.collection('hospital_capacity').get();
    final hospitals = snap.docs.map((d) => HospitalCapacity.fromFirestore(d)).toList();

    // Sort by: availableBeds (desc) + proximity
    hospitals.sort((a, b) {
      if (a.availableBeds > 0 && b.availableBeds == 0) return -1;
      if (a.availableBeds == 0 && b.availableBeds > 0) return 1;
      return a.erQueueLength.compareTo(b.erQueueLength);
    });

    return hospitals.first;
  }

  // --- KPI ENGINE ---

  Stream<Map<String, dynamic>> getEmergencyKPIs() {
    return _db.collection('emergency_incidents').snapshots().map((snap) {
      final incidents = snap.docs.map((d) => EmergencyIncident.fromFirestore(d)).toList();

      final active = incidents.where((i) => i.status != IncidentStatus.resolved && i.status != IncidentStatus.cancelled).length;
      final critical = incidents.where((i) => i.priority == IncidentPriority.critical && i.status != IncidentStatus.resolved).length;

      // Calculate avg response time for resolved incidents
      final resolved = incidents.where((i) => i.status == IncidentStatus.resolved && i.arrivalTime != null).toList();
      double avgResponse = 0;
      if (resolved.isNotEmpty) {
        final totalSeconds = resolved.fold<int>(0, (sumVal, i) => sumVal + i.arrivalTime!.difference(i.createdAt).inSeconds);
        avgResponse = totalSeconds / resolved.length / 60; // mins
      }

      return {
        'activeIncidents': active,
        'criticalIncidents': critical,
        'avgResponseTime': avgResponse,
        'emergencyReadiness': 0.98, // Mock
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }
}
