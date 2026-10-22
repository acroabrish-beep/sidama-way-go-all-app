import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request_model.dart';

class TestDataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fare configuration (must match RideService)
  static const double baseFare = 15.0; // ETB
  static const double perKmRate = 8.0; // ETB per km
  static const double perMinuteRate = 0.5; // ETB per minute

  // Test driver ID (you can replace with your actual test driver UID)
  static const String testDriverId = 'test_driver_123';
  static const String testDriverName = 'Test Driver';
  static const String testDriverPhone = '+251911123456';

  // Test citizen IDs
  static const List<String> testCitizenIds = [
    'test_citizen_1',
    'test_citizen_2',
    'test_citizen_3',
  ];

  static const List<String> testCitizenNames = [
    'Abebe Kebede',
    'Tirunesh Dibaba',
    'Haile Gebreselassie',
  ];

  static const List<String> testCitizenPhones = [
    '+251911111111',
    '+251922222222',
    '+251933333333',
  ];

  // Hawassa locations for realistic rides
  static const List<Map<String, dynamic>> locations = [
    {'name': 'Hawassa Lake Side', 'lat': 7.0450, 'lon': 38.4800},
    {'name': 'Piazza', 'lat': 7.0622, 'lon': 38.4763},
    {'name': 'Menaharia', 'lat': 7.0650, 'lon': 38.4700},
    {'name': 'Bus Terminal', 'lat': 7.0580, 'lon': 38.4850},
    {'name': 'University Campus', 'lat': 7.0700, 'lon': 38.4650},
    {'name': 'Market Area', 'lat': 7.0600, 'lon': 38.4750},
    {'name': 'Hospital Zone', 'lat': 7.0550, 'lon': 38.4900},
    {'name': 'Airport Road', 'lat': 7.0400, 'lon': 38.4950},
  ];

  static const List<String> vehicleTypes = ['Taxi', 'Bajaj', 'Minibus'];
  static const List<String> vehiclePlates = [
    'AA-1234',
    'AA-5678',
    'AA-9012',
    'AA-3456',
  ];

  // Calculate fare using the same formula as RideService
  double calculateFare(double distanceKm, int estimatedMinutes) {
    final distanceFare = distanceKm * perKmRate;
    final timeFare = estimatedMinutes * perMinuteRate;
    return baseFare + distanceFare + timeFare;
  }

  // Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Seed completed rides for earnings testing
  Future<void> seedCompletedRides() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Create rides across different time periods
    final rides = [
      // Today's rides (3 rides)
      _createCompletedRide(
        citizenIndex: 0,
        pickupIndex: 0,
        destinationIndex: 1,
        completedAt: today.add(const Duration(hours: 2)),
        vehicleType: 'Taxi',
        vehiclePlate: 'AA-1234',
      ),
      _createCompletedRide(
        citizenIndex: 1,
        pickupIndex: 2,
        destinationIndex: 3,
        completedAt: today.add(const Duration(hours: 5)),
        vehicleType: 'Bajaj',
        vehiclePlate: 'AA-5678',
      ),
      _createCompletedRide(
        citizenIndex: 2,
        pickupIndex: 4,
        destinationIndex: 5,
        completedAt: today.add(const Duration(hours: 8)),
        vehicleType: 'Taxi',
        vehiclePlate: 'AA-9012',
      ),
      // This week's rides (3 rides, excluding today)
      _createCompletedRide(
        citizenIndex: 0,
        pickupIndex: 1,
        destinationIndex: 2,
        completedAt: weekStart.add(const Duration(days: 2, hours: 10)),
        vehicleType: 'Minibus',
        vehiclePlate: 'AA-3456',
      ),
      _createCompletedRide(
        citizenIndex: 1,
        pickupIndex: 3,
        destinationIndex: 4,
        completedAt: weekStart.add(const Duration(days: 3, hours: 14)),
        vehicleType: 'Taxi',
        vehiclePlate: 'AA-1234',
      ),
      _createCompletedRide(
        citizenIndex: 2,
        pickupIndex: 5,
        destinationIndex: 6,
        completedAt: weekStart.add(const Duration(days: 4, hours: 9)),
        vehicleType: 'Bajaj',
        vehiclePlate: 'AA-5678',
      ),
      // This month's rides (4 rides, excluding this week)
      _createCompletedRide(
        citizenIndex: 0,
        pickupIndex: 6,
        destinationIndex: 7,
        completedAt: monthStart.add(const Duration(days: 5, hours: 11)),
        vehicleType: 'Taxi',
        vehiclePlate: 'AA-9012',
      ),
      _createCompletedRide(
        citizenIndex: 1,
        pickupIndex: 7,
        destinationIndex: 0,
        completedAt: monthStart.add(const Duration(days: 10, hours: 16)),
        vehicleType: 'Minibus',
        vehiclePlate: 'AA-3456',
      ),
      _createCompletedRide(
        citizenIndex: 2,
        pickupIndex: 0,
        destinationIndex: 4,
        completedAt: monthStart.add(const Duration(days: 15, hours: 8)),
        vehicleType: 'Taxi',
        vehiclePlate: 'AA-1234',
      ),
      _createCompletedRide(
        citizenIndex: 0,
        pickupIndex: 2,
        destinationIndex: 5,
        completedAt: monthStart.add(const Duration(days: 20, hours: 13)),
        vehicleType: 'Bajaj',
        vehiclePlate: 'AA-5678',
      ),
    ];

    // Check if test rides already exist
    final existingSnapshot = await _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: testDriverId)
        .limit(1)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      debugPrint('Test rides already exist. Skipping seeding.');
      return;
    }

    // Batch write all rides
    final batch = _db.batch();
    for (final ride in rides) {
      final docRef = _db.collection('ride_requests').doc();
      batch.set(docRef, ride);
    }

    await batch.commit();
    debugPrint('Seeded ${rides.length} completed rides for earnings testing');
  }

  // Seed pending ride requests for driver testing
  Future<void> seedPendingRideRequests() async {
    final now = DateTime.now();

    final pendingRides = [
      _createPendingRide(
        citizenIndex: 0,
        pickupIndex: 0,
        destinationIndex: 1,
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      _createPendingRide(
        citizenIndex: 1,
        pickupIndex: 2,
        destinationIndex: 3,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      _createPendingRide(
        citizenIndex: 2,
        pickupIndex: 4,
        destinationIndex: 5,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
    ];

    // Check if pending rides already exist
    final existingSnapshot = await _db
        .collection('ride_requests')
        .where('status', isEqualTo: RideStatus.requested.name)
        .limit(1)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      debugPrint('Pending ride requests already exist. Skipping seeding.');
      return;
    }

    // Batch write all pending rides
    final batch = _db.batch();
    for (final ride in pendingRides) {
      final docRef = _db.collection('ride_requests').doc();
      batch.set(docRef, ride);
    }

    await batch.commit();
    debugPrint('Seeded ${pendingRides.length} pending ride requests for driver testing');
  }

  // Main seeding function - call this to seed all test data
  Future<void> seedAllTestData() async {
    if (!kDebugMode) {
      debugPrint('Test data seeding only runs in debug mode');
      return;
    }

    debugPrint('Starting test data seeding...');
    await seedCompletedRides();
    await seedPendingRideRequests();
    debugPrint('Test data seeding completed');
  }

  // Helper: Create a completed ride record
  Map<String, dynamic> _createCompletedRide({
    required int citizenIndex,
    required int pickupIndex,
    required int destinationIndex,
    required DateTime completedAt,
    required String vehicleType,
    required String vehiclePlate,
  }) {
    final pickup = locations[pickupIndex];
    final destination = locations[destinationIndex];
    final distance = calculateDistance(
      pickup['lat'],
      pickup['lon'],
      destination['lat'],
      destination['lon'],
    );
    final estimatedMinutes = (distance * 2).round();
    final fare = calculateFare(distance, estimatedMinutes);

    return {
      'riderId': testCitizenIds[citizenIndex],
      'riderName': testCitizenNames[citizenIndex],
      'riderPhone': testCitizenPhones[citizenIndex],
      'pickupLocation': pickup['name'],
      'pickupCoordinates': GeoPoint(pickup['lat'], pickup['lon']),
      'destination': destination['name'],
      'destinationCoordinates': GeoPoint(destination['lat'], destination['lon']),
      'estimatedDistanceKm': distance,
      'estimatedFare': fare,
      'actualFare': fare, // Same as estimated for simplicity
      'status': RideStatus.completed.name,
      'driverId': testDriverId,
      'driverName': testDriverName,
      'driverPhone': testDriverPhone,
      'vehiclePlateNumber': vehiclePlate,
      'createdAt': Timestamp.fromDate(completedAt.subtract(Duration(minutes: estimatedMinutes))),
      'acceptedAt': Timestamp.fromDate(completedAt.subtract(Duration(minutes: estimatedMinutes - 2))),
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  // Helper: Create a pending ride request
  Map<String, dynamic> _createPendingRide({
    required int citizenIndex,
    required int pickupIndex,
    required int destinationIndex,
    required DateTime createdAt,
  }) {
    final pickup = locations[pickupIndex];
    final destination = locations[destinationIndex];
    final distance = calculateDistance(
      pickup['lat'],
      pickup['lon'],
      destination['lat'],
      destination['lon'],
    );
    final estimatedMinutes = (distance * 2).round();
    final fare = calculateFare(distance, estimatedMinutes);

    return {
      'riderId': testCitizenIds[citizenIndex],
      'riderName': testCitizenNames[citizenIndex],
      'riderPhone': testCitizenPhones[citizenIndex],
      'pickupLocation': pickup['name'],
      'pickupCoordinates': GeoPoint(pickup['lat'], pickup['lon']),
      'destination': destination['name'],
      'destinationCoordinates': GeoPoint(destination['lat'], destination['lon']),
      'estimatedDistanceKm': distance,
      'estimatedFare': fare,
      'status': RideStatus.requested.name,
      'driverId': null,
      'driverName': null,
      'driverPhone': null,
      'vehiclePlateNumber': null,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': null,
      'completedAt': null,
    };
  }

  // Clear all test data (useful for resetting)
  Future<void> clearTestData() async {
    if (!kDebugMode) {
      debugPrint('Test data clearing only runs in debug mode');
      return;
    }

    debugPrint('Clearing test data...');

    // Clear completed rides for test driver
    final completedSnapshot = await _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: testDriverId)
        .get();

    final batch = _db.batch();
    for (final doc in completedSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Clear pending requests from test citizens
    for (final citizenId in testCitizenIds) {
      final pendingSnapshot = await _db
          .collection('ride_requests')
          .where('riderId', isEqualTo: citizenId)
          .where('status', isEqualTo: RideStatus.requested.name)
          .get();

      for (final doc in pendingSnapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
    debugPrint('Test data cleared');
  }
}
