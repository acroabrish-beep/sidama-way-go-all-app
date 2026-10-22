import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sidama_way_go/models/taxi_models.dart';
import 'package:sidama_way_go/models/city_os_models.dart';

void main() {
  group('Fleet Engine Phase 5 Verification', () {
    test('FleetVehicle Advanced Profile', () {
      final vehicle = FleetVehicle(
        vehicleId: 'V-PRO-001',
        plateNumber: 'HW-77777',
        vehicleType: VehicleType.ambulance,
        fleetNumber: 'AMB-01',
        manufactureYear: 2023,
        fuelType: FuelType.electric,
        batteryType: BatteryType.lithiumIon,
        status: VehicleStatus.emergency,
        approvalStatus: ApprovalStatus.approved,
        lifecycleStatus: VehicleLifecycleStatus.active,
        insuranceExpiry: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(vehicle.fleetNumber, 'AMB-01');
      expect(vehicle.batteryType, BatteryType.lithiumIon);
      expect(vehicle.status, VehicleStatus.emergency);
      print('PASS: FleetVehicle advanced profile verified');
    });

    test('Lifecycle and Maintenance States', () {
      const status = VehicleLifecycleStatus.maintenance;
      const mStatus = MaintenanceStatus.urgentRepair;

      expect(status.name, 'maintenance');
      expect(mStatus.name, 'urgentRepair');
      print('PASS: Lifecycle and Maintenance enums verified');
    });

    test('Hub Counter Expansion (Mandatory Phase 5)', () {
      final hub = TransportHub(
        location: const GeoPoint(7.0504, 38.4955),
        stationName: 'Emergency Center',
        ambulanceVehicles: 10,
        fireVehicles: 5,
        policeVehicles: 8,
        governmentFleetVehicles: 12,
        logisticsVehicles: 4,
        maintenanceFleetVehicles: 2,
        inspectionVehicles: 1,
      );

      expect(hub.ambulanceVehicles, 10);
      expect(hub.fireVehicles, 5);
      expect(hub.policeVehicles, 8);
      expect(hub.governmentFleetVehicles, 12);
      expect(hub.logisticsVehicles, 4);
      expect(hub.maintenanceFleetVehicles, 2);
      expect(hub.inspectionVehicles, 1);
      print('PASS: Hub counter expansion verified for all required types');
    });

    test('Telemetry and GPS Health modeling', () {
      final vehicle = FleetVehicle(
        vehicleId: 'V-GPS-01',
        plateNumber: 'HW-001',
        vehicleType: VehicleType.taxi,
        status: VehicleStatus.moving,
        approvalStatus: ApprovalStatus.approved,
        gpsLocation: const GeoPoint(7.06, 38.48),
        speed: 45.5,
        heading: 180.0,
        gpsHealth: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(vehicle.speed, 45.5);
      expect(vehicle.gpsHealth, true);
      print('PASS: Telemetry and GPS health modeling confirmed');
    });
   group('Smart Assignment Engine Simulations', () {
      test('Assignment Validation Mock', () {
        // Logic simulation for the engine
        bool canAssign(WorkforceMember driver, FleetVehicle vehicle) {
          if (driver.governmentApproval != ApprovalStatus.approved) return false;
          if (vehicle.approvalStatus != ApprovalStatus.approved) return false;
          if (!driver.vehicleTypesAllowed.contains(vehicle.vehicleType)) return false;
          return true;
        }

        final driver = WorkforceMember(
          workerId: 'D1',
          fullName: 'Test Driver',
          role: WorkforceRole.taxiDriver,
          phone: '09',
          governmentApproval: ApprovalStatus.approved,
          vehicleTypesAllowed: [VehicleType.taxi],
        );

        final vehicle = FleetVehicle(
          vehicleId: 'V1',
          plateNumber: 'P1',
          vehicleType: VehicleType.taxi,
          status: VehicleStatus.available,
          approvalStatus: ApprovalStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(canAssign(driver, vehicle), true);
        print('PASS: Smart assignment logic simulation verified');
      });
    });
  });
}
