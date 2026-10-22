import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

class TourismService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tourist Sites
  Stream<List<TouristSite>> getTouristSites() {
    return _db.collection('tourist_sites').snapshots().map(
      (snap) => snap.docs.map((doc) => TouristSite.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  Future<void> addTouristSite(TouristSite site) {
    return _db.collection('tourist_sites').add(site.toMap());
  }

  // Tour Packages
  Stream<List<TourPackage>> getTourPackages() {
    return _db.collection('tour_packages').snapshots().map(
      (snap) => snap.docs.map((doc) => TourPackage.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  // Tour Guides
  Stream<List<TourGuide>> getGuides() {
    return _db.collection('tour_guides').snapshots().map(
      (snap) => snap.docs.map((doc) => TourGuide.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  Stream<List<TourGuide>> getApprovedGuides() {
    return _db.collection('tour_guides')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TourGuide.fromMap(doc.data(), doc.id)).toList());
  }

  // Contract Rides
  Future<void> bookContractRide(ContractRide ride) {
    return _db.collection('contract_rides').add(ride.toMap());
  }

  // Bookings
  Future<void> createBooking(TouristBooking booking) {
    return _db.collection('tourist_bookings').add(booking.toMap());
  }

  Stream<List<TouristBooking>> getUserBookings(String userId) {
    return _db.collection('tourist_bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => TouristBooking.fromMap(doc.data(), doc.id)).toList());
  }

  // Events
  Stream<List<TouristEvent>> getEvents() {
    return _db.collection('events').orderBy('date').snapshots().map(
      (snap) => snap.docs.map((doc) => TouristEvent.fromMap(doc.data(), doc.id)).toList(),
    );
  }

  // Operator Registration
  Future<void> registerOperator(TourOperator operator) {
    return _db.collection('tour_operators').doc(operator.id).set(operator.toMap());
  }

  // Guide Registration
  Future<void> registerGuide(TourGuide guide) {
    return _db.collection('tour_guides').add(guide.toMap());
  }
}
