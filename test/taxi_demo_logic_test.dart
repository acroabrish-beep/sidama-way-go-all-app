import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/demo_ride_model.dart';
import 'package:sidama_way_go/providers/taxi_demo_provider.dart';
import 'package:sidama_way_go/services/taxi_demo_service.dart';

void main() {
  group('Taxi Demo Logic Tests', () {
    late TaxiDemoProvider provider;

    setUp(() {
      provider = TaxiDemoProvider();
    });

    test('Initial state should be idle', () {
      expect(provider.status, DemoRideStatus.idle);
      expect(provider.fleet.length, 6);
    });

    test('Setting pickup and destination should calculate estimates', () {
      final pickup = TaxiDemoService.hawassaLocations[0]; // University
      final destination = TaxiDemoService.hawassaLocations[1]; // Piazza

      provider.setPickup(pickup);
      provider.setDestination(destination);

      expect(provider.pickup, pickup);
      expect(provider.destination, destination);
      expect(provider.estimatedFare, greaterThan(0));
      expect(provider.etaMinutes, greaterThan(0));
    });

    test('Finding a taxi should transition to matched state', () async {
      final pickup = TaxiDemoService.hawassaLocations[0];
      final destination = TaxiDemoService.hawassaLocations[1];

      provider.setPickup(pickup);
      provider.setDestination(destination);

      await provider.findTaxi();

      expect(provider.status, DemoRideStatus.matched);
      expect(provider.selectedTaxi, isNotNull);
      expect(provider.currentTaxiLocation, isNotNull);
    });

    test('Reset should clear all states', () {
      provider.setPickup(TaxiDemoService.hawassaLocations[0]);
      provider.reset();

      expect(provider.status, DemoRideStatus.idle);
      expect(provider.pickup, isNull);
      expect(provider.selectedTaxi, isNull);
    });
    
    test('Fare calculation should be dynamic', () {
       const durationMin = 10;
       final dist1 = 1.0;
       final fare1 = TaxiDemoService.calculateFare(dist1, durationMin);

       final dist2 = 10.0;
       final fare2 = TaxiDemoService.calculateFare(dist2, durationMin);

       expect(fare2, greaterThan(fare1));
       expect(fare1, 15.0 + (dist1 * 8.0) + (durationMin * 0.5));
    });
  });
}
