import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../models/city_os_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Generic CRUD
  Future<void> addDocument(String collection, Map<String, dynamic> data) {
    return _db.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) {
    return _db.collection(collection).doc(docId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).delete();
  }

  Stream<QuerySnapshot> getCollectionStream(String collection, {Query Function(Query)? queryBuilder}) {
    Query query = _db.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  // Specific for Old Terminal
  Stream<QuerySnapshot> getOldTerminalRoutes() => getCollectionStream('old_terminal_routes');
  Stream<QuerySnapshot> getOldTerminalVehicles() => getCollectionStream('old_terminal_vehicles');
  Stream<QuerySnapshot> getOldTerminalDrivers() => getCollectionStream('old_terminal_drivers');

  // Specific for New Terminal
  Stream<QuerySnapshot> getNewTerminalRoutes() => getCollectionStream('new_terminal_routes');

  // Announcements
  Future<void> createAnnouncement(Map<String, dynamic> data) {
    return addDocument(CityOSCollection.announcements, data);
  }

  Future<int> getCollectionCount(String collectionName) async {
    final snapshot = await _db.collection(collectionName).count().get();
    return snapshot.count ?? 0;
  }

  Future<double> getTotalRevenue() async {
    double total = 0;
    final busBookings = await _db.collection('bookings').get();
    for (var doc in busBookings.docs) {
      total += (doc.data()['fare'] ?? 0).toDouble();
    }
    final taxiBookings = await _db.collection('taxi_bookings').get();
    for (var doc in taxiBookings.docs) {
      total += (doc.data()['fare'] ?? 0).toDouble();
    }
    return total;
  }

  Future<void> ensureInitialData() async {
    await checkAndSeedTaxi();
    await checkAndSeedTransport();
    await checkAndSeedLocations();
    await checkAndSeedTourism();
    await checkAndSeedPopularDestinations();
    await _seedBaselineAnalytics();
  }

  Future<void> _seedBaselineAnalytics() async {
    final analytics = _db.collection(CityOSCollection.analytics);

    // Summary
    final summaryDoc = await analytics.doc('summary').get();
    if (!summaryDoc.exists) {
      await analytics.doc('summary').set({
        'totalUsers': 1250,
        'taxiRequests': 450,
        'busBookings': 890,
        'activeSOS': 2,
        'totalRevenue': 450000.0,
        'weeklyRevenue': [12000.0, 15000.0, 18000.0, 14000.0, 22000.0, 19000.0, 25000.0],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Taxi Specific
    final taxiDoc = await analytics.doc('taxi').get();
    if (!taxiDoc.exists) {
      await analytics.doc('taxi').set({
        'totalStations': 11,
        'onlineTaxis': 45,
        'busyTaxis': 12,
        'offlineTaxis': 8,
        'waitingPassengers': 5,
        'completedRides': 342,
        'todayRevenue': 12400.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> checkAndSeedPopularDestinations() async {
    final snapshot = await _db.collection('popular_destinations').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final List<Map<String, dynamic>> destinations = [
        {'name': 'Menaharia', 'fare': 8, 'duration': '10 min'},
        {'name': 'Haik Dar', 'fare': 6, 'duration': '8 min'},
        {'name': 'Tabor', 'fare': 7, 'duration': '12 min'},
        {'name': 'Hawella Tula', 'fare': 10, 'duration': '15 min'},
        {'name': 'Addis Ketema', 'fare': 8, 'duration': '11 min'},
        {'name': 'Gudumale', 'fare': 9, 'duration': '13 min'},
        {'name': 'Misrak', 'fare': 7, 'duration': '10 min'},
        {'name': 'Alamura', 'fare': 12, 'duration': '18 min'},
      ];
      final batch = _db.batch();
      for (var d in destinations) {
        batch.set(_db.collection('popular_destinations').doc(), d);
      }
      await batch.commit();
    }
  }

  Future<void> checkAndSeedLocations() async {
    final snapshot = await _db.collection('locations').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final data = [
        {'name': 'Menaharia Terminal', 'latitude': 7.0621, 'longitude': 38.4772, 'category': 'Terminal'},
        {'name': 'HUCSH Hospital', 'latitude': 7.0622, 'longitude': 38.4831, 'category': 'Hospital'},
        {'name': 'Haile Resort', 'latitude': 7.0639, 'longitude': 38.4813, 'category': 'Hotel'},
        {'name': 'Amora Gedel', 'latitude': 7.0588, 'longitude': 38.4851, 'category': 'Tourism'},
        {'name': 'City Pharmacy', 'latitude': 7.0580, 'longitude': 38.4870, 'category': 'Pharmacy'},
      ];
      final batch = _db.batch();
      for (var d in data) {
        batch.set(_db.collection('locations').doc(), {...d, 'timestamp': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
  }

  Future<void> checkAndSeedTourism() async {
    final snapshot = await _db.collection(CityOSCollection.tourismSites).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final sites = [
        {'name': 'Lake Hawassa', 'category': 'Natural', 'rating': 4.8, 'description': 'The heart of the city.'},
        {'name': 'Tabor Mountain', 'category': 'Hiking', 'rating': 4.5, 'description': 'Panoramic views.'},
      ];
      final batch = _db.batch();
      for (var s in sites) {
        batch.set(_db.collection(CityOSCollection.tourismSites).doc(), {...s, 'createdAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    }
  }

  Future<void> checkAndSeedTaxi() async {
    try {
      final snapshot = await _db.collection(CityOSCollection.taxiStations).limit(1).get();
      if (snapshot.docs.isEmpty) {
        final List<Map<String, dynamic>> initialStations = [
          {'name': 'Menaharia', 'location': const GeoPoint(7.0621, 38.4772), 'capacity': 50, 'status': 'Active', 'onlineTaxiCount': 0, 'totalTaxiCount': 0},
          {'name': 'Piassa', 'location': const GeoPoint(7.0504, 38.4955), 'capacity': 40, 'status': 'Active', 'onlineTaxiCount': 0, 'totalTaxiCount': 0},
        ];
        final batch = _db.batch();
        for (var s in initialStations) {
          batch.set(_db.collection(CityOSCollection.taxiStations).doc(), {...s, 'createdAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e) {
      AppLogger.error('Error seeding taxi data', error: e);
    }
  }

  Future<void> checkAndSeedTransport() async {
    try {
      final snapshot = await _db.collection(CityOSCollection.routes).limit(1).get();
      if (snapshot.docs.isEmpty) {
        final List<Map<String, dynamic>> initialRoutes = [
          {'route': 'Hawassa → Addis Ababa', 'origin': 'Hawassa', 'destination': 'Addis Ababa', 'fare': 280, 'terminal_id': 'new_terminal'},
          {'route': 'Hawassa → Shashamane', 'origin': 'Hawassa', 'destination': 'Shashamane', 'fare': 80, 'terminal_id': 'old_terminal'},
        ];
        final batch = _db.batch();
        for (var r in initialRoutes) {
          batch.set(_db.collection(CityOSCollection.routes).doc(), {...r, 'createdAt': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e) {
      AppLogger.error('Error seeding transport data', error: e);
    }
  }
}
