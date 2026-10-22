import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sidama_way_go/models/taxi_models.dart';
import 'package:sidama_way_go/models/city_os_models.dart';

void main() {
  group('Fleet Management Engine Phase 5 Verification', () {
    test('FleetVehicle Model Mapping', () {
      final vehicle = FleetVehicle(
        vehicleId: 'V-001',
        plateNumber: 'HW-12345',
        vehicleType: VehicleType.ambulance,
        brand: 'Toyota',
        model: 'Land Cruiser',
        status: VehicleStatus.available,
        approvalStatus: ApprovalStatus.approved,
        lifecycleStatus: VehicleLifecycleStatus.active,
        fuelLevel: 85.0,
        batteryLevel: 90.0,
        odometer: 15000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(vehicle.vehicleType, VehicleType.ambulance);
      expect(vehicle.fuelLevel, 85.0);
      expect(vehicle.brand, 'Toyota');
      print('PASS: FleetVehicle model mapping verified');
    });

    test('Maintenance Engine Data Modeling', () {
      final record = MaintenanceRecord(
        recordId: 'REC-001',
        vehicleId: 'V-001',
        serviceType: 'Oil Change',
        description: 'Synthetic oil replacement',
        cost: 2500.0,
        odometerAtService: 12000.0,
        technicianId: 'TECH-77',
        serviceDate: DateTime.now(),
      );

      expect(record.cost, 2500.0);
      expect(record.serviceType, 'Oil Change');
      print('PASS: Maintenance record modeling confirmed');
    });

    test('Hub Counter Expansion Verification', () {
      final hub = TransportHub(
        location: const GeoPoint(7.0504, 38.4955),
        stationName: 'Piassa Hub',
        ambulanceVehicles: 5,
        policeVehicles: 3,
        taxiVehicles: 20,
      );

      expect(hub.ambulanceVehicles, 5);
      expect(hub.policeVehicles, 3);
      expect(hub.taxiVehicles, 20);
      print('PASS: Hub multi-modal counters verified');
    });

    test('Backward Compatibility (typedef)', () {
      final TransportVehicle legacyRef = FleetVehicle(
        vehicleId: 'V-002',
        plateNumber: 'HW-555',
        vehicleType: VehicleType.taxi,
        status: VehicleStatus.waiting,
        approvalStatus: ApprovalStatus.approved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(legacyRef.plateNumber, 'HW-555');
      print('PASS: Legacy TransportVehicle alias confirmed');
    });
  });
}
