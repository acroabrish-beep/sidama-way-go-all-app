import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart';

class SmartCityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication & Roles
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection(CityOSCollection.users).doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // INTERCITY TERMINAL
  Stream<List<BusRoute>> getBusRoutes(String terminalId) {
    return _db.collection(CityOSCollection.routes)
      .where('terminalId', isEqualTo: terminalId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BusRoute.fromFirestore(doc)).toList());
  }

  Future<void> bookBusTicket(Ticket ticket) async {
    try {
      await _db.collection(CityOSCollection.tickets).add(ticket.toMap());
    } catch (e) {
      debugPrint("Error booking bus ticket: $e");
      rethrow;
    }
  }

  // EMERGENCY SERVICES
  Future<void> requestEmergency(String type, GeoPoint location, String userName) async {
    try {
      await _db.collection(CityOSCollection.emergencyRequests).add({
        'userId': _auth.currentUser?.uid,
        'userName': userName,
        'type': type,
        'location': location,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error requesting emergency: $e");
    }
  }

  // TOURISM
  Stream<List<TouristSite>> getTouristSites() {
    return _db.collection(CityOSCollection.tourismSites).snapshots()
      .map((snap) => snap.docs.map((doc) => TouristSite.fromMap(doc.data(), doc.id)).toList());
  }

  // ANNOUNCEMENTS
  Stream<List<Map<String, dynamic>>> getAnnouncements() {
    return _db.collection(CityOSCollection.announcements).orderBy('createdAt', descending: true).snapshots()
      .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
