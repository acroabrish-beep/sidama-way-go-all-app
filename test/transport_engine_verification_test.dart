import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sidama_way_go/models/taxi_models.dart';

void main() {
  group('Transport OS Phase 3 Verification', () {
    test('Hierarchy Integrity Check', () {
      final hub = TransportHub(
        location: const GeoPoint(7.0504, 38.4955),
        country: 'Ethiopia',
        region: 'Sidama',
        city: 'Hawassa',
        zone: 'Central',
      );
      expect(hub.country, 'Ethiopia');
      expect(hub.region, 'Sidama');
      expect(hub.city, 'Hawassa');
      print('PASS: Hub Hierarchy confirmed');
    });

    test('Platform Isolation & Counters', () {
      final platform = TransportPlatform(
        platformId: 'BAY-1',
        platformName: 'Taxi Bay',
        vehicleType: VehicleType.taxi,
        capacity: 10,
        currentVehicles: 5,
        dispatchRate: 2.5,
      );

      expect(platform.health, StationHealth.normal);
      expect(platform.dispatchRate, 2.5);
      print('PASS: Platform isolation and counter model confirmed');
    });

    test('Legacy Getter Compatibility', () {
      final hub = TransportHub(
        location: const GeoPoint(7.0504, 38.4955),
        stationName: 'Piassa',
        maximumVehicleCapacity: 100,
        availableVehicles: 20,
      );

      // Verify legacy fields are accessible via getters
      expect(hub.name, 'Piassa');
      expect(hub.capacity, 100);
      expect(hub.onlineTaxiCount, 20);
      expect(hub.activeTaxiCount, 20);
      print('PASS: Legacy UI compatibility (Getters) confirmed');
    });

    test('Heat Map Data Structure', () {
      final hub = TransportHub(
        location: const GeoPoint(7.0504, 38.4955),
        queueLength: 15,
      );

      final metrics = {
        'demand': hub.queueLength.toDouble(),
        'congestion': hub.occupancyPercentage,
      };

      expect(metrics['demand'], 15.0);
      print('PASS: Heat Map metric structure confirmed');
    });
  });
}
