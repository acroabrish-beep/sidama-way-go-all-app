import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../core/config/env_config.dart';
import '../models/taxi_models.dart';
import '../models/city_os_models.dart' hide RideRequest;
import '../models/map_models.dart';
import 'notification_service.dart';

class TaxiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- WORKFORCE VALIDATION ENGINE ---

  Future<bool> validateWorkforceCompliance(String workerId) async {
    final workerDoc = await _db.collection('drivers').doc(workerId).get();
    if (!workerDoc.exists) return false;

    final worker = WorkforceMember.fromFirestore(workerDoc);
    final now = DateTime.now();

    // 1. Status Check
    if (worker.lifecycleStatus == WorkforceLifecycleStatus.suspended ||
        worker.lifecycleStatus == WorkforceLifecycleStatus.retired ||
        worker.lifecycleStatus == WorkforceLifecycleStatus.medicalHold) {
      return false;
    }

    // 2. Government Approval Check
    if (worker.governmentApproval != ApprovalStatus.approved) return false;

    // 3. License Expiry Check
    if (worker.licenseExpiry != null && worker.licenseExpiry!.isBefore(now)) return false;

    // 4. Medical Expiry Check
    if (worker.medicalExpiry != null && worker.medicalExpiry!.isBefore(now)) return false;

    return true;
  }

  // --- SHIFT & ATTENDANCE ENGINE ---

  Future<void> logAttendance(String workerId, ShiftType shiftType, {bool isClockIn = true}) async {
    final attendanceRef = _db.collection('attendance').doc();
    await _db.runTransaction((transaction) async {
      final workerRef = _db.collection('drivers').doc(workerId);
      final workerSnap = await transaction.get(workerRef);
      if (!workerSnap.exists) throw Exception('Worker not found');

      transaction.set(attendanceRef, {
        'workerId': workerId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': isClockIn ? 'CLOCK_IN' : 'CLOCK_OUT',
        'shiftType': shiftType.name,
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      transaction.update(workerRef, {
        'online': isClockIn,
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- WORKFORCE TRANSFER ENGINE ---

  Future<void> transferWorkforceMember(
    String workerId,
    String toHubId,
    {String? toPlatformId, String? toShiftId, required String reason}
  ) async {
    await _db.runTransaction((transaction) async {
      final workerRef = _db.collection('drivers').doc(workerId);
      final workerSnap = await transaction.get(workerRef);
      if (!workerSnap.exists) throw Exception('Worker not found');

      final worker = WorkforceMember.fromFirestore(workerSnap);
      final fromHubId = worker.assignedHubId;
      final fromPlatformId = worker.assignedPlatformId;

      // Admission Control for Target Hub
      final hubRef = _db.collection('taxi_stations').doc(toHubId);
      final hubSnap = await transaction.get(hubRef);
      if (!hubSnap.exists) throw Exception('Target Hub not found');

      final hub = TransportHub.fromFirestore(hubSnap);
      if (hub.currentVehicleCount >= hub.maximumVehicleCapacity) throw Exception('Target Hub is full');

      // Update Worker
      transaction.update(workerRef, {
        'assignedHubId': toHubId,
        'assignedPlatformId': toPlatformId ?? '',
        'assignedShiftId': toShiftId ?? worker.assignedShiftId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the transfer
      await _logOperation(
        transaction,
        action: 'WORKFORCE_TRANSFER',
        vehicleId: worker.assignedVehicleId,
        fromStationId: fromHubId,
        toStationId: toHubId,
        fromPlatformId: fromPlatformId,
        toPlatformId: toPlatformId,
        reason: reason
      );
    });
  }

  // --- FLEET MANAGEMENT ENGINE ---

  Future<void> registerVehicle(FleetVehicle vehicle) async {
    await _db.collection('vehicles').doc(vehicle.vehicleId).set(vehicle.toMap());
  }

  Future<void> approveVehicle(String vehicleId) async {
    await _db.collection('vehicles').doc(vehicleId).update({
      'approvalStatus': ApprovalStatus.approved.name,
      'lifecycleStatus': VehicleLifecycleStatus.governmentApproval.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Transactional Smart Assignment Engine
  Future<void> assignDriverToVehicle(String workerId, String vehicleId) async {
    await _db.runTransaction((transaction) async {
      final workerRef = _db.collection('drivers').doc(workerId);
      final vehicleRef = _db.collection('vehicles').doc(vehicleId);

      final workerSnap = await transaction.get(workerRef);
      final vehicleSnap = await transaction.get(vehicleRef);

      if (!workerSnap.exists || !vehicleSnap.exists) throw Exception('Workforce Member or Vehicle not found');

      final worker = WorkforceMember.fromFirestore(workerSnap);
      final vehicle = FleetVehicle.fromFirestore(vehicleSnap);

      // Validation Engine
      if (worker.governmentApproval != ApprovalStatus.approved) throw Exception('Driver not approved by Government');
      if (vehicle.approvalStatus != ApprovalStatus.approved) throw Exception('Vehicle not approved by Government');
      if (worker.lifecycleStatus == WorkforceLifecycleStatus.suspended) throw Exception('Driver is currently suspended');
      if (vehicle.status == VehicleStatus.suspended) throw Exception('Vehicle is currently suspended');

      // Compliance Check
      final now = DateTime.now();
      if (worker.licenseExpiry != null && worker.licenseExpiry!.isBefore(now)) throw Exception('Driver license expired');
      if (vehicle.insuranceExpiry != null && vehicle.insuranceExpiry!.isBefore(now)) throw Exception('Vehicle insurance expired');

      // Authorization Check
      if (!worker.vehicleTypesAllowed.contains(vehicle.vehicleType)) {
        throw Exception('Driver not authorized for ${vehicle.vehicleType.name}');
      }

      transaction.update(workerRef, {
        'assignedVehicleId': vehicleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(vehicleRef, {
        'assignedDriverId': workerId,
        'lifecycleStatus': VehicleLifecycleStatus.driverAssignment.name,
        'status': VehicleStatus.assigned.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logOperation(
        transaction,
        action: 'FLEET_ASSIGNMENT',
        vehicleId: vehicleId,
        reason: 'Driver ${worker.fullName} assigned to ${vehicle.plateNumber}'
      );
    });
  }

  // Maintenance Engine
  Future<void> scheduleMaintenance(String vehicleId, String type, DateTime date, double odometer) async {
    final reminderRef = _db.collection('maintenance_reminders').doc();
    final reminder = MaintenanceReminder(
      reminderId: reminderRef.id,
      vehicleId: vehicleId,
      title: 'Scheduled $type',
      description: 'Periodic maintenance check',
      dueDate: date,
      dueOdometer: odometer,
    );
    await reminderRef.set(reminder.toMap());

    await _db.collection('vehicles').doc(vehicleId).update({
      'maintenanceStatus': MaintenanceStatus.serviceDue.name,
      'status': VehicleStatus.maintenance.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeMaintenance(MaintenanceRecord record) async {
    await _db.runTransaction((transaction) async {
      final vehicleRef = _db.collection('vehicles').doc(record.vehicleId);
      final recordRef = _db.collection('maintenance_history').doc();

      transaction.set(recordRef, record.toMap());
      transaction.update(vehicleRef, {
        'maintenanceStatus': MaintenanceStatus.good.name,
        'lifecycleStatus': VehicleLifecycleStatus.active.name,
        'status': VehicleStatus.available.name,
        'odometer': record.odometerAtService,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- FLEET AI COMMAND CENTER ---

  Stream<List<FleetVehicle>> getAvailableFleet(VehicleType type) {
    return _db.collection('vehicles')
      .where('vehicleType', isEqualTo: type.name)
      .where('status', isEqualTo: VehicleStatus.available.name)
      .where('approvalStatus', isEqualTo: ApprovalStatus.approved.name)
      .snapshots()
      .map((s) => s.docs.map((d) => FleetVehicle.fromFirestore(d)).toList());
  }

  Stream<List<FleetVehicle>> getEmergencyFleet() {
    return _db.collection('vehicles')
      .where('vehicleType', whereIn: [
        VehicleType.ambulance.name,
        VehicleType.fireTruck.name,
        VehicleType.policeVehicle.name
      ])
      .snapshots()
      .map((s) => s.docs.map((d) => FleetVehicle.fromFirestore(d)).toList());
  }

  Stream<List<FleetVehicle>> getMaintenanceFleet() {
    return _db.collection('vehicles')
      .where('status', isEqualTo: VehicleStatus.maintenance.name)
      .snapshots()
      .map((s) => s.docs.map((d) => FleetVehicle.fromFirestore(d)).toList());
  }

  // --- CITY COMMAND CENTER (Aggregated Metrics) ---

  Stream<Map<String, dynamic>> getCityFleetSummary() {
    return _db.collection('vehicles').snapshots().map((snap) {
      final fleet = snap.docs.map((d) => FleetVehicle.fromFirestore(d)).toList();

      int total = fleet.length;
      int active = fleet.where((v) => v.status == VehicleStatus.moving || v.status == VehicleStatus.busy).length;
      int maintenance = fleet.where((v) => v.status == VehicleStatus.maintenance).length;
      int emergency = fleet.where((v) => v.status == VehicleStatus.emergency).length;

      double totalFuel = 0;
      double totalBattery = 0;
      int evCount = 0;
      int fuelCount = 0;

      for (var v in fleet) {
        if (v.fuelType == FuelType.electric) {
          totalBattery += v.batteryLevel;
          evCount++;
        } else {
          totalFuel += v.fuelLevel;
          fuelCount++;
        }
      }

      return {
        'totalFleet': total,
        'activeFleet': active,
        'maintenanceFleet': maintenance,
        'emergencyFleet': emergency,
        'avgFuelLevel': fuelCount > 0 ? totalFuel / fuelCount : 0.0,
        'avgBatteryLevel': evCount > 0 ? totalBattery / evCount : 0.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  // --- FLEET GPS & TELEMETRY ---

  Future<void> updateVehicleTelemetry(String vehicleId, GeoPoint loc, double speed, double heading, double fuel, double battery) async {
    final vehicleRef = _db.collection('vehicles').doc(vehicleId);

    // GPS Engine: Reject invalid updates (Basic sanity check)
    if (loc.latitude == 0 && loc.longitude == 0) return;
    if (speed < 0 || speed > 200) return; // 200 km/h sanity limit

    await vehicleRef.update({
      'gpsLocation': loc,
      'speed': speed,
      'heading': heading,
      'fuelLevel': fuel,
      'batteryLevel': battery,
      'lastUpdate': FieldValue.serverTimestamp(),
      'gpsHealth': true,
    });
  }

  // --- BACKWARD COMPATIBILITY ALIASES ---

  Future<void> moveTaxiBetweenStations(String driverId, String? oldStationId, String newStationId, String newStationName) async {
    await transferWorkforceMember(driverId, newStationId, reason: 'Manual Admin Move to $newStationName');
  }

  Future<void> removeTaxiFromStation(String driverId, String stationId) async {
    await transferWorkforceMember(driverId, 'general', reason: 'Admin Removal from Station');
  }

  // --- LIVE SMART CITY DIGITAL TWIN ENGINE ---

  Stream<List<FleetVehicle>> getLiveFleet() {
    return _db.collection('vehicles').snapshots().map((snap) {
      return snap.docs.map((d) => FleetVehicle.fromFirestore(d)).toList();
    });
  }

  Stream<List<WorkforceMember>> getLiveWorkforce() {
    return _db.collection('drivers').snapshots().map((snap) {
      return snap.docs.map((d) => WorkforceMember.fromFirestore(d)).toList();
    });
  }

  Stream<List<TransportHub>> getLiveHubs() {
    return _db.collection('taxi_stations').snapshots().map((snap) {
      return snap.docs.map((d) => TransportHub.fromFirestore(d)).toList();
    });
  }

  Stream<List<MapEvent>> getLiveEvents() {
    return _db.collection('city_events').where('isActive', isEqualTo: true).snapshots().map((snap) {
      return snap.docs.map((d) => MapEvent.fromFirestore(d)).toList();
    });
  }

  // --- SMART ROUTING & DISPATCH ---

  Future<Map<String, dynamic>> calculateRoute(GeoPoint start, GeoPoint end, VehicleType type) async {
    // Logic: In a real app, this calls OSRM or Google Routes.
    // Here we simulate the enterprise digital twin logic.
    double distance = Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude) / 1000;
    int eta = (distance * 3).toInt(); // 3 mins per km simulation
    double fare = distance * 25; // 25 ETB per km simulation

    return {
      'distanceKm': distance,
      'etaMinutes': eta,
      'estimatedFare': fare,
      'routePoints': [start, end], // Simulated straight line for digital twin visualization
    };
  }

  // --- CITY HEATMAP CALCULATOR ---

  Stream<List<CityHeatmapData>> getCityHeatmap(String layerType) {
    return _db.collection('taxi_stations').snapshots().map((snap) {
      final hubs = snap.docs.map((d) => TransportHub.fromFirestore(d)).toList();
      return hubs.map((h) {
        double intensity = 0.0;
        if (layerType == 'demand') intensity = h.queueLength / 50;
        else if (layerType == 'congestion') intensity = h.occupancyPercentage / 100;

        return CityHeatmapData(
          zoneId: h.stationId,
          intensity: intensity.clamp(0.0, 1.0),
          center: h.location,
        );
      }).toList();
    });
  }

  Stream<List<WorkforceMember>> getEmergencyWorkforce() {
    return _db.collection('drivers')
      .where('role', whereIn: [
        WorkforceRole.ambulanceDriver.name,
        WorkforceRole.fireServiceDriver.name,
        WorkforceRole.policeDriver.name
      ])
      .where('online', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => WorkforceMember.fromFirestore(d)).toList());
  }

  Future<void> registerDriver(TaxiDriver driver) async {
    await _db.collection('drivers').doc(driver.workerId).set(driver.toMap());
  }

  Future<void> seedStations() async {
    if (kReleaseMode || EnvConfig.isProduction) return;
    final snapshot = await _db.collection('taxi_stations').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final stations = [
        {'name': 'Menaharia', 'lat': 7.0621, 'lng': 38.4772, 'capacity': 50},
        {'name': 'Piassa', 'lat': 7.0504, 'lng': 38.4955, 'capacity': 40},
        {'name': 'Menbo', 'lat': 7.0550, 'lng': 38.4800, 'capacity': 30},
        {'name': 'University', 'lat': 7.0450, 'lng': 38.4900, 'capacity': 30},
        {'name': 'Tabor', 'lat': 7.0423, 'lng': 38.5085, 'capacity': 35},
        {'name': 'Hawela Tula', 'lat': 7.0315, 'lng': 38.5210, 'capacity': 25},
        {'name': 'Alamura', 'lat': 7.0150, 'lng': 38.4820, 'capacity': 20},
        {'name': 'Misrak', 'lat': 7.0600, 'lng': 38.5000, 'capacity': 30},
        {'name': 'Gudumale', 'lat': 7.0580, 'lng': 38.4850, 'capacity': 35},
        {'name': 'Haik Dar', 'lat': 7.0650, 'lng': 38.4750, 'capacity': 40},
        {'name': 'Addis Ketema', 'lat': 7.0700, 'lng': 38.4650, 'capacity': 30},
      ];
      for (var s in stations) {
        await _db.collection('taxi_stations').add({
          'name': s['name'],
          'location': GeoPoint(s['lat'] as double, s['lng'] as double),
          'capacity': s['capacity'],
          'totalTaxiCount': 0,
          'onlineTaxiCount': 0,
          'activeTaxiCount': 0,
          'waitingPassengers': 0,
          'status': 'Active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _updateStationCounters(
    Transaction transaction,
    String stationId,
    VehicleType vehicleType,
    Map<String, int> deltas, {
    String? platformId,
  }) async {
    final stationRef = _db.collection('taxi_stations').doc(stationId);
    final snapshot = await transaction.get(stationRef);
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final updates = <String, dynamic>{};

    if (deltas.containsKey('total')) {
      updates['currentVehicleCount'] = FieldValue.increment(deltas['total']!);
    }

    for (var entry in deltas.entries) {
      if (entry.key == 'total') continue;
      updates['${entry.key}Vehicles'] = FieldValue.increment(entry.value);
    }

    final typeCounts = Map<String, dynamic>.from(data['currentVehicleCountPerVehicleType'] ?? {});
    final currentTypeCount = typeCounts[vehicleType.name] ?? 0;
    typeCounts[vehicleType.name] = currentTypeCount + (deltas['total'] ?? 0);
    updates['currentVehicleCountPerVehicleType'] = typeCounts;

    final typeField = '${vehicleType.name}Vehicles';
    updates[typeField] = FieldValue.increment(deltas['total'] ?? 0);

    if (platformId != null) {
      final platforms = List<Map<String, dynamic>>.from(data['platforms'] ?? []);
      final platformIndex = platforms.indexWhere((p) => p['platformId'] == platformId);
      if (platformIndex != -1) {
        final platform = Map<String, dynamic>.from(platforms[platformIndex]);
        if (deltas.containsKey('total')) {
          platform['currentVehicles'] = (platform['currentVehicles'] ?? 0) + deltas['total']!;
        }
        final int currentCount = platform['currentVehicles'] ?? 0;
        final int capacity = platform['capacity'] ?? 10;
        final double occupancy = capacity > 0 ? (currentCount / capacity) * 100 : 0.0;
        if (occupancy >= 100) platform['health'] = 'full';
        else if (occupancy >= 91) platform['health'] = 'critical';
        else if (occupancy >= 76) platform['health'] = 'congested';
        else if (occupancy >= 51) platform['health'] = 'busy';
        else platform['health'] = 'normal';

        platform['dispatchRate'] = (currentCount * 0.5) + (data['dailyRides'] ?? 0) / 24;
        platform['arrivalRate'] = (currentCount * 0.4) + 2;
        platform['avgWaitTime'] = occupancy > 80 ? 25 : (occupancy > 50 ? 15 : 8);
        platform['rotationIndex'] = occupancy > 0 ? (platform['dispatchRate'] / currentCount).clamp(0.1, 5.0) : 1.0;
        platforms[platformIndex] = platform;
        updates['platforms'] = platforms;
      }
    }
    transaction.update(stationRef, { ...updates, 'updatedAt': FieldValue.serverTimestamp() });
  }

  Future<void> _logOperation(
    Transaction transaction, {
    required String action,
    required String vehicleId,
    String? fromStationId,
    String? toStationId,
    String? fromPlatformId,
    String? toPlatformId,
    required String reason,
    dynamic previousValue,
    dynamic newValue,
  }) async {
    final auditRef = _db.collection('transport_audit').doc();
    transaction.set(auditRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'action': action,
      'vehicleId': vehicleId,
      'fromStationId': fromStationId,
      'toStationId': toStationId,
      'fromPlatformId': fromPlatformId,
      'toPlatformId': toPlatformId,
      'reason': reason,
      'previousValue': previousValue,
      'newValue': newValue,
      'systemModule': 'TransportOS',
      'region': 'Sidama',
      'city': 'Hawassa',
    });
    if (fromStationId != null || toStationId != null) {
      final historyRef = _db.collection('transfer_history').doc();
      transaction.set(historyRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'vehicleId': vehicleId,
        'fromStationId': fromStationId,
        'toStationId': toStationId,
        'fromPlatformId': fromPlatformId,
        'toPlatformId': toPlatformId,
        'reason': reason,
      });
    }
  }

  Future<void> assignVehicleToStation(String vehicleId, String stationId, {String? platformId, String reason = 'Initial Assignment'}) async {
    await _db.runTransaction((transaction) async {
      final vehicleRef = _db.collection('taxis').doc(vehicleId);
      final stationRef = _db.collection('taxi_stations').doc(stationId);
      final vehicleSnap = await transaction.get(vehicleRef);
      final stationSnap = await transaction.get(stationRef);
      if (!vehicleSnap.exists || !stationSnap.exists) throw Exception('Vehicle or Station not found');
      final vehicle = FleetVehicle.fromFirestore(vehicleSnap);
      final hub = TransportHub.fromFirestore(stationSnap);
      if (!hub.isOperational || hub.isClosed) throw Exception('Station is not operational');
      if (hub.currentVehicleCount >= hub.maximumVehicleCapacity) {
        final rec = await recommendAlternativeHub(hub);
        throw Exception('Station ${hub.stationName} is full. Recommendation: ${rec.stationName} (${rec.city})');
      }
      final typeCap = hub.maximumCapacityPerVehicleType[vehicle.vehicleType] ?? 999;
      final typeCount = hub.currentVehicleCountPerVehicleType[vehicle.vehicleType] ?? 0;
      if (typeCount >= typeCap) throw Exception('Station capacity for ${vehicle.vehicleType.name} is full');
      if (platformId != null) {
        final platform = hub.platforms.firstWhere((p) => p.platformId == platformId, orElse: () => throw Exception('Platform $platformId not found in ${hub.stationName}'));
        if (platform.currentVehicles >= platform.capacity) throw Exception('Platform ${platform.platformName} is full');
      }
      transaction.update(vehicleRef, { 'assignedHubId': stationId, 'assignedPlatformId': platformId, 'updatedAt': FieldValue.serverTimestamp() });
      await _updateStationCounters(transaction, stationId, vehicle.vehicleType, {'total': 1, 'available': 1}, platformId: platformId);
      await _logOperation(transaction, action: 'ASSIGN', vehicleId: vehicleId, toStationId: stationId, toPlatformId: platformId, reason: reason);
    });
  }

  Future<TransportHub> recommendAlternativeHub(TransportHub currentHub, {VehicleType? preferredType}) async {
    final snap = await _db.collection('taxi_stations').get();
    final hubs = snap.docs.map((d) => TransportHub.fromFirestore(d)).toList();
    hubs.removeWhere((h) => h.stationId == currentHub.stationId || h.isClosed || !h.isOperational || h.currentVehicleCount >= h.maximumVehicleCapacity);
    if (preferredType != null) {
      hubs.removeWhere((h) {
        final typeCap = h.maximumCapacityPerVehicleType[preferredType] ?? 999;
        final typeCount = h.currentVehicleCountPerVehicleType[preferredType] ?? 0;
        return typeCount >= typeCap;
      });
    }
    if (hubs.isEmpty) return currentHub;
    hubs.sort((a, b) {
      final distA = Geolocator.distanceBetween(currentHub.location.latitude, currentHub.location.longitude, a.location.latitude, a.location.longitude);
      final distB = Geolocator.distanceBetween(currentHub.location.latitude, currentHub.location.longitude, b.location.latitude, b.location.longitude);
      final scoreA = distA + (a.averageWaitingTime * 100) + (a.occupancyPercentage * 10);
      final scoreB = distB + (b.averageWaitingTime * 100) + (b.occupancyPercentage * 10);
      return scoreA.compareTo(scoreB);
    });
    return hubs.first;
  }

  Future<void> transferVehicle(String vehicleId, String toStationId, {String? toPlatformId, String reason = 'Redistribution'}) async {
    await _db.runTransaction((transaction) async {
      final vehicleRef = _db.collection('taxis').doc(vehicleId);
      final vehicleSnap = await transaction.get(vehicleRef);
      if (!vehicleSnap.exists) throw Exception('Vehicle not found');
      final vehicle = FleetVehicle.fromFirestore(vehicleSnap);
      final fromStationId = vehicle.assignedHubId;
      final fromPlatformId = (vehicleSnap.data() as Map<String, dynamic>)['assignedPlatformId'] as String?;
      if (fromStationId == toStationId && fromPlatformId == toPlatformId) return;
      final toStationRef = _db.collection('taxi_stations').doc(toStationId);
      final toStationSnap = await transaction.get(toStationRef);
      if (!toStationSnap.exists) throw Exception('Target station not found');
      final toHub = TransportHub.fromFirestore(toStationSnap);
      if (toHub.currentVehicleCount >= toHub.maximumVehicleCapacity) {
        final rec = await recommendAlternativeHub(toHub, preferredType: vehicle.vehicleType);
        throw Exception('Target station ${toHub.stationName} is full. Recommendation: ${rec.stationName}');
      }
      if (toPlatformId != null) {
        final platform = toHub.platforms.firstWhere((p) => p.platformId == toPlatformId, orElse: () => throw Exception('Platform $toPlatformId not found in ${toHub.stationName}'));
        if (platform.currentVehicles >= platform.capacity) throw Exception('Target platform ${platform.platformName} is full');
      }
      transaction.update(vehicleRef, { 'assignedHubId': toStationId, 'assignedPlatformId': toPlatformId, 'updatedAt': FieldValue.serverTimestamp() });
      if (fromStationId.isNotEmpty) {
        await _updateStationCounters(transaction, fromStationId, vehicle.vehicleType, {'total': -1, 'available': -1}, platformId: fromPlatformId);
      }
      await _updateStationCounters(transaction, toStationId, vehicle.vehicleType, {'total': 1, 'available': 1}, platformId: toPlatformId);
      await _logOperation(transaction, action: 'TRANSFER', vehicleId: vehicleId, fromStationId: fromStationId, toStationId: toStationId, fromPlatformId: fromPlatformId, toPlatformId: toPlatformId, reason: reason);
    });
  }

  Stream<Map<String, dynamic>> getCityTransportHeatMap() {
    return _db.collection('taxi_stations').snapshots().map((snap) {
      final hubs = snap.docs.map((d) => TransportHub.fromFirestore(d)).toList();
      double totalDemand = 0, totalCongestion = 0, avgWaitTime = 0;
      int emergencyActive = 0, totalVehiclesOnline = 0;
      for (var hub in hubs) {
        totalDemand += hub.queueLength;
        totalCongestion += hub.occupancyPercentage;
        emergencyActive += hub.emergencyVehicles;
        totalVehiclesOnline += hub.availableVehicles;
        avgWaitTime += hub.averageWaitingTime;
      }
      final int count = hubs.isEmpty ? 1 : hubs.length;
      return {
        'demand': totalDemand,
        'congestion': totalCongestion / count,
        'emergencyActive': emergencyActive,
        'vehicleDensity': totalVehiclesOnline / count,
        'averageCityWaitTime': avgWaitTime / count,
        'hubCount': hubs.length,
        'status': totalCongestion / count > 80 ? 'Critical' : (totalCongestion / count > 50 ? 'Busy' : 'Normal'),
        'fuelConsumptionIndex': totalCongestion / count * 0.8,
        'batteryHealthIndex': 95.0 - (totalCongestion / count * 0.1),
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  Stream<WorkforceMember?> getDriver(String driverId) {
    return _db.collection('drivers').doc(driverId).snapshots().map((doc) {
      if (doc.exists) return WorkforceMember.fromFirestore(doc);
      return null;
    });
  }

  Future<WorkforceMember?> getDriverByUserId(String userId) async {
    final snap = await _db.collection('drivers').where('userId', isEqualTo: userId).limit(1).get();
    if (snap.docs.isNotEmpty) return WorkforceMember.fromFirestore(snap.docs.first);
    return null;
  }

  Future<void> updateDriver(WorkforceMember driver) async {
    await _db.collection('drivers').doc(driver.workerId).update(driver.toMap());
  }

  Future<void> approveDriver(String driverId) async {
    await _db.collection('drivers').doc(driverId).update({ 'governmentApproval': ApprovalStatus.approved.name, 'lifecycleStatus': WorkforceLifecycleStatus.governmentApproved.name });
  }

  Future<void> rejectDriver(String driverId) async {
    await _db.collection('drivers').doc(driverId).update({ 'governmentApproval': ApprovalStatus.rejected.name });
  }

  Stream<List<TransportHub>> getTaxiStations() {
    return _db.collection('taxi_stations').snapshots().map((snap) {
      return snap.docs.map((doc) => TransportHub.fromFirestore(doc)).toList();
    });
  }

  Stream<List<TransportHub>> getStations() => getTaxiStations();

  Stream<TransportHub?> getStation(String stationId) {
    return _db.collection('taxi_stations').doc(stationId).snapshots().map((doc) {
      if (doc.exists) return TransportHub.fromFirestore(doc);
      return null;
    });
  }

  Stream<int> getActiveDriverCount(String stationId) {
    return _db.collection('drivers').where('assignedHubId', isEqualTo: stationId).snapshots().map((snap) {
      return snap.docs.where((doc) {
        final data = doc.data();
        return data['governmentApproval'] == 'approved' && data['online'] == true;
      }).length;
    });
  }

  Stream<List<WorkforceMember>> getNearbyDrivers(GeoPoint userLoc) {
    return _db.collection('drivers').where('governmentApproval', isEqualTo: 'approved').snapshots().map((snap) {
      final drivers = snap.docs.map((doc) => WorkforceMember.fromFirestore(doc)).where((d) => d.online).toList();
      drivers.sort((a, b) {
        if (a.lastKnownLocation == null || b.lastKnownLocation == null) return 0;
        double distA = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, a.lastKnownLocation!.latitude, a.lastKnownLocation!.longitude);
        double distB = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, b.lastKnownLocation!.latitude, b.lastKnownLocation!.longitude);
        return distA.compareTo(distB);
      });
      return drivers;
    });
  }

  Future<String?> _assignNextDriverFromStation(RideRequest request) async {
    final queueSnap = await _db.collection('station_queue').where('stationId', isEqualTo: request.stationId).orderBy('joinedAt').limit(1).get();
    if (queueSnap.docs.isEmpty) return null;
    final queueEntry = queueSnap.docs.first;
    final driverId = queueEntry.data()['driverId'] as String? ?? '';
    if (driverId.isEmpty) return null;
    final driverDoc = await _db.collection('drivers').doc(driverId).get();
    if (!driverDoc.exists) { await _removeDriverFromQueue(driverId); return null; }
    final driverData = driverDoc.data() as Map<String, dynamic>;
    if (!(driverData['online'] ?? false)) { await _removeDriverFromQueue(driverId); return null; }
    final plateNumber = driverData['assignedVehicleId'] ?? '';
    final driverName = driverData['fullName'] ?? 'Driver';
    final requestRef = await _db.collection('ride_requests').add({
      ...request.toMap(),
      'status': 'Accepted',
      'driverId': driverId,
      'driverName': driverName,
      'plateNumber': plateNumber,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _removeDriverFromQueue(driverId);
    await updateDriverStatus(driverId, TaxiStatus.busy);
    await NotificationService.sendNotification(userId: driverId, title: 'Smart Taxi Assignment', message: 'You have been assigned a ride from ${request.stationName}.', type: 'ride_assigned', referenceId: requestRef.id);
    return requestRef.id;
  }

  Future<void> _addDriverToQueue(WorkforceMember driver) async {
    if (!driver.online || driver.assignedHubId.isEmpty) return;
    await _removeDriverFromQueue(driver.workerId);
    await _db.collection('station_queue').add({
      'stationId': driver.assignedHubId,
      'driverId': driver.workerId,
      'driverName': driver.fullName,
      'joinedAt': FieldValue.serverTimestamp(),
      'status': 'queued',
    });
    await _db.collection('taxi_stations').doc(driver.assignedHubId).update({ 'queueCount': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp() });
  }

  Future<void> _removeDriverFromQueue(String driverId) async {
    final queueSnap = await _db.collection('station_queue').where('driverId', isEqualTo: driverId).get();
    for (var doc in queueSnap.docs) {
      final stationId = doc.data()['stationId'] as String?;
      if (stationId != null) await _db.collection('taxi_stations').doc(stationId).update({ 'queueCount': FieldValue.increment(-1), 'updatedAt': FieldValue.serverTimestamp() });
      await doc.reference.delete();
    }
  }

  Stream<int> getDriverQueuePosition(String driverId, String stationId) {
    return _db.collection('station_queue').where('stationId', isEqualTo: stationId).orderBy('joinedAt').snapshots().map((snap) {
      final index = snap.docs.indexWhere((doc) => doc.data()['driverId'] == driverId);
      return index >= 0 ? index + 1 : 0;
    });
  }

  Stream<List<RideRequest>> getDriverActiveRides(String driverId) {
    return _db.collection('ride_requests').where('driverId', isEqualTo: driverId).snapshots().map((s) => s.docs.map((d) => RideRequest.fromFirestore(d)).where((r) => r.status == 'Accepted' || r.status == 'Ongoing' || r.status == 'OnTrip').toList());
  }

  Future<String> requestSmartTaxi(RideRequest request, String stationId) async {
    final assignedRideId = await _assignNextDriverFromStation(request);
    if (assignedRideId != null) return assignedRideId;
    final docRef = await _db.collection('ride_requests').add(request.toMap());
    await _db.collection('taxi_stations').doc(stationId).update({ 'waitingPassengers': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp() });
    return docRef.id;
  }

  Future<String> createRideRequest(RideRequest request) async {
    final docRef = await _db.collection('ride_requests').add(request.toMap());
    return docRef.id;
  }

  Future<void> toggleDriverOnline(String driverId, bool online) async {
    await updateDriverStatus(driverId, online ? TaxiStatus.waiting : TaxiStatus.offline);
  }

  Future<void> acceptRide(String requestId, String driverId, String driverName) async {
    final driverDoc = await _db.collection('drivers').doc(driverId).get();
    final plateNumber = driverDoc.exists ? (driverDoc.get('assignedVehicleId') ?? '') : '';
    final rideDoc = await _db.collection('ride_requests').doc(requestId).get();
    if (!rideDoc.exists) return;
    final userId = rideDoc.get('userId'), stationId = rideDoc.get('stationId') as String?;
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('ride_requests').doc(requestId), { 'status': 'Accepted', 'driverId': driverId, 'driverName': driverName, 'plateNumber': plateNumber });
      if (stationId != null) transaction.update(_db.collection('taxi_stations').doc(stationId), { 'waitingPassengers': FieldValue.increment(-1) });
      await _updateDriverStatusInTransaction(transaction, driverId, TaxiStatus.busy);
    });
    await _removeDriverFromQueue(driverId);
    await NotificationService.sendNotification(userId: userId, title: 'Taxi Arriving!', message: '$driverName has accepted your request.', type: 'taxi_accepted', referenceId: requestId);
  }

  Future<void> cancelRide(String requestId) async {
    final rideDoc = await _db.collection('ride_requests').doc(requestId).get();
    if (!rideDoc.exists) return;
    final stationId = rideDoc.get('stationId') as String?;
    await _db.collection('ride_requests').doc(requestId).update({ 'status': 'Cancelled' });
    if (stationId != null) await _db.collection('taxi_stations').doc(stationId).update({ 'waitingPassengers': FieldValue.increment(-1), 'updatedAt': FieldValue.serverTimestamp() });
  }

  Future<void> completeRide(String requestId, String driverId) async {
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('ride_requests').doc(requestId), { 'status': 'Completed' });
      await _updateDriverStatusInTransaction(transaction, driverId, TaxiStatus.waiting);
    });
  }

  Future<void> updateDriverStatus(String driverId, TaxiStatus status) async {
    await _db.runTransaction((transaction) async { await _updateDriverStatusInTransaction(transaction, driverId, status); });
    if (status == TaxiStatus.waiting) {
      final updatedDriverDoc = await _db.collection('drivers').doc(driverId).get();
      if (updatedDriverDoc.exists) await _addDriverToQueue(WorkforceMember.fromFirestore(updatedDriverDoc));
    } else { await _removeDriverFromQueue(driverId); }
  }

  Future<void> _updateDriverStatusInTransaction(Transaction transaction, String driverId, TaxiStatus status) async {
    bool isOnline = status != TaxiStatus.offline;
    DocumentReference driverRef = _db.collection('drivers').doc(driverId);
    DocumentSnapshot driverDoc = await transaction.get(driverRef);
    if (driverDoc.exists) {
      bool wasOnline = driverDoc.get('online') ?? false;
      String? oldStationId = driverDoc.get('assignedHubId');
      transaction.update(driverRef, { 'online': isOnline, 'lastUpdate': FieldValue.serverTimestamp() });
      if (oldStationId != null) {
        int delta = (wasOnline && !isOnline) ? -1 : (!wasOnline && isOnline ? 1 : 0);
        if (delta != 0) transaction.update(_db.collection('taxi_stations').doc(oldStationId), { 'activeTaxiCount': FieldValue.increment(delta), 'onlineTaxiCount': FieldValue.increment(delta), 'updatedAt': FieldValue.serverTimestamp() });
      }
    }
  }

  Future<void> updateDriverLocation(String driverId, Position position, String zone) async {
    final driverRef = _db.collection('drivers').doc(driverId);
    final driverDoc = await driverRef.get();
    String? currentStationId = driverDoc.exists ? driverDoc.get('assignedHubId') : null;
    final stationsSnap = await _db.collection('taxi_stations').where('isOperational', isEqualTo: true).get();
    String? detectedStationId;
    double minDistance = 500;
    for (var doc in stationsSnap.docs) {
      GeoPoint loc = doc.get('location');
      double distance = Geolocator.distanceBetween(position.latitude, position.longitude, loc.latitude, loc.longitude);
      if (distance < minDistance) { minDistance = distance; detectedStationId = doc.id; }
    }
    if (detectedStationId != null && detectedStationId != currentStationId) {
      await transferWorkforceMember(driverId, detectedStationId, reason: 'Auto GPS Proximity Move');
    }
    await driverRef.update({ 'lastKnownLocation': GeoPoint(position.latitude, position.longitude), 'heading': position.heading, 'speed': position.speed, 'currentZone': zone, 'lastUpdate': FieldValue.serverTimestamp() });
  }

  Future<void> registerTaxi(Taxi taxi) async {
    await _db.collection('taxis').doc(taxi.vehicleId).set(taxi.toMap());
  }

  Future<void> assignTaxiToStation(String driverId, String stationId) async {
    await transferWorkforceMember(driverId, stationId, reason: 'Admin Station Assignment');
  }

  Stream<List<WorkforceMember>> getAllDrivers() => _db.collection('drivers').snapshots().map((s) => s.docs.map((d) => WorkforceMember.fromFirestore(d)).toList());
  Stream<List<WorkforceMember>> getOnlineDrivers() => _db.collection('drivers').where('online', isEqualTo: true).snapshots().map((s) => s.docs.map((d) => WorkforceMember.fromFirestore(d)).toList());
  Stream<List<WorkforceMember>> getOfflineDrivers() => _db.collection('drivers').where('online', isEqualTo: false).snapshots().map((s) => s.docs.map((d) => WorkforceMember.fromFirestore(d)).toList());

  Stream<Map<String, int>> getAdminStats() => getAllDrivers().map((drivers) => {
    'online': drivers.where((d) => d.online).length,
    'offline': drivers.where((d) => !d.online).length,
    'busy': drivers.where((d) => !d.online).length, // simplified
  });
  Stream<Map<String, dynamic>> getDashboardStatistics() => getAdminStats().map((s) => s as Map<String, dynamic>);

  Future<void> saveStation(TransportHub station) async => station.stationId.isEmpty ? await _db.collection('taxi_stations').add(station.toMap()) : await _db.collection('taxi_stations').doc(station.stationId).set(station.toMap());
  Future<void> deleteStation(String id) async => await _db.collection('taxi_stations').doc(id).delete();
  Stream<RideRequest?> watchRide(String id) => _db.collection('ride_requests').doc(id).snapshots().map((d) => d.exists ? RideRequest.fromFirestore(d) : null);

  Stream<List<RideRequest>> getNearbyRideRequests(String zone) {
    return _db.collection('ride_requests').orderBy('timestamp', descending: true).limit(50).snapshots().map((s) => s.docs.map((d) => RideRequest.fromFirestore(d)).where((r) => r.status == 'Pending').toList());
  }

  Stream<List<RideRequest>> getStationRideRequests(String stationId) {
    return _db.collection('ride_requests').where('stationId', isEqualTo: stationId).where('status', isEqualTo: 'Pending').orderBy('timestamp', descending: false).snapshots().map((s) => s.docs.map((d) => RideRequest.fromFirestore(d)).toList());
  }

  Future<void> sendSOS(String id, String name, GeoPoint loc) async => await _db.collection('emergency_alerts').add({ 'type': 'Transport SOS', 'workerId': id, 'workerName': name, 'location': loc, 'timestamp': FieldValue.serverTimestamp(), 'status': 'Active' });

  // Fix null stationId for existing drivers (Maintenance Utility)
  Future<void> fixMissingStationIds() async {
    final snap = await _db.collection('drivers').where('assignedHubId', isEqualTo: '').get();
    for (var doc in snap.docs) {
      await doc.reference.update({ 'assignedHubId': 'general', 'updatedAt': FieldValue.serverTimestamp() });
    }
  }

  static const List<Map<String, dynamic>> hawassaZones = [
    {'name': 'Piassa', 'lat': 7.0504, 'lng': 38.4955},
    {'name': 'Menaharia', 'lat': 7.0621, 'lng': 38.4772},
    {'name': 'Tabor', 'lat': 7.0423, 'lng': 38.5085},
    {'name': 'Haik Dar', 'lat': 7.0588, 'lng': 38.4851},
    {'name': 'Addis Ketema', 'lat': 7.0712, 'lng': 38.4655},
    {'name': 'Hawela Tula', 'lat': 7.0315, 'lng': 38.5210},
    {'name': 'Alamura', 'lat': 7.0150, 'lng': 38.4820},
    {'name': 'Menbo', 'lat': 7.0550, 'lng': 38.4800},
    {'name': 'University', 'lat': 7.0450, 'lng': 38.4900},
  ];

  static String detectZone(double lat, double lng) {
    String closest = 'Hawassa';
    double min = double.infinity;
    for (var z in hawassaZones) {
      double d = Geolocator.distanceBetween(lat, lng, z['lat'], z['lng']);
      if (d < min) { min = d; closest = z['name']; }
    }
    return closest;
  }
}
