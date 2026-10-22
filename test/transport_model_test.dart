// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/taxi_models.dart';
import 'package:sidama_way_go/models/city_os_models.dart';

class MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  bool get exists => _data != null;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();

  @override
  dynamic get(Object field) => _data?[field];
}

void main() {
  group('TransportVehicle Model Tests', () {
    test('Legacy Taxi Document Deserialization', () {
      final legacyData = {
        'taxiNumber': 'TX-1234',
        'plateNumber': 'AA-B12345',
        'driverId': 'driver_001',
        'status': 'waiting',
        'online': true,
        'approved': true,
        'location': const GeoPoint(7.0504, 38.4955),
        'createdAt': Timestamp.now(),
        'registrationDate': Timestamp.now(),
      };

      final mockDoc = MockDocumentSnapshot('TX-1234', legacyData);

      final vehicle = TransportVehicle.fromFirestore(mockDoc);

      expect(vehicle.vehicleId, 'TX-1234');
      expect(vehicle.vehicleType, VehicleType.taxi);
      expect(vehicle.plateNumber, 'AA-B12345');
      expect(vehicle.status, VehicleStatus.waiting);
      expect(vehicle.availability, true);
      expect(vehicle.approvalStatus, ApprovalStatus.approved);
      print('PASS: Legacy Taxi deserialized correctly');
    });

    test('Full Generic Transport Vehicle Serialization', () {
      final now = DateTime.now();
      final vehicle = TransportVehicle(
        vehicleId: 'BUS-001',
        vehicleType: VehicleType.cityBus,
        plateNumber: 'BUS-112233',
        assignedDriverId: 'driver_bus_1',
        assignedHubId: 'main_terminal',
        status: VehicleStatus.moving,
        approvalStatus: ApprovalStatus.approved,
        createdAt: now,
        updatedAt: now,
      );

      final map = vehicle.toMap();

      expect(map['vehicleType'], 'cityBus');
      expect(map['status'], 'moving');
      expect(map['plateNumber'], 'BUS-112233');
      expect(map['approvalStatus'], 'approved');
      print('PASS: Generic Transport Vehicle serialized correctly');
    });

    test('Legacy TaxiStation Deserialization', () {
      final legacyStationData = {
        'name': 'Menaharia',
        'capacity': 100,
        'totalTaxiCount': 10,
        'onlineTaxiCount': 5,
        'waitingPassengers': 2,
        'status': 'Active',
        'location': const GeoPoint(7.0621, 38.4772),
      };

      final mockDoc = MockDocumentSnapshot('ST-999', legacyStationData);
      final hub = TransportHub.fromFirestore(mockDoc);

      expect(hub.stationName, 'Menaharia');
      expect(hub.maximumVehicleCapacity, 100);
      expect(hub.currentVehicleCount, 10);
      expect(hub.availableVehicles, 5);
      expect(hub.healthStatus, StationHealth.normal);
      expect(hub.country, 'Ethiopia'); // Default value
      print('PASS: Legacy TaxiStation deserialized correctly');
    });

    test('Hierarchy and Platform Support', () {
      final stationData = {
        'stationName': 'Piassa Central Hub',
        'country': 'Ethiopia',
        'city': 'Hawassa',
        'zone': 'Central',
        'maximumVehicleCapacity': 500,
        'platforms': [
          {
            'platformId': 'P1',
            'platformName': 'Taxi Bay A',
            'vehicleType': 'taxi',
            'capacity': 50,
            'currentVehicles': 25,
            'health': 'busy',
          },
          {
            'platformId': 'P2',
            'platformName': 'Bus Platform 1',
            'vehicleType': 'cityBus',
            'capacity': 10,
            'currentVehicles': 0,
            'health': 'normal',
          },
        ],
      };

      final mockDoc = MockDocumentSnapshot('HUB-001', stationData);
      final hub = TransportHub.fromFirestore(mockDoc);

      expect(hub.city, 'Hawassa');
      expect(hub.platforms.length, 2);
      expect(hub.platforms[0].platformName, 'Taxi Bay A');
      expect(hub.platforms[0].health, StationHealth.busy);
      print('PASS: Hierarchy and Platform data verified');
    });
    group('Validation Logic Simulations', () {
      test('GPS Validity Check', () {
        const validPoint = GeoPoint(7.0622, 38.4763);
        const invalidPoint = GeoPoint(0.0, 0.0);

        bool isValid(GeoPoint gp) => gp.latitude != 0 && gp.longitude != 0;

        expect(isValid(validPoint), true);
        expect(isValid(invalidPoint), false);
        print('PASS: GPS validity logic verified');
      });
    });
  });
}
