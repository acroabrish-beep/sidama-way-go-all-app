import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_os_models.dart';

class CityPlatformService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Intercity Bus
  Stream<List<BusRoute>> getIntercityRoutes(String terminalId) {
    return _db.collection('routes')
      .where('terminalId', isEqualTo: terminalId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BusRoute.fromFirestore(doc)).toList());
  }

  Future<void> bookIntercityTicket(Ticket ticket) async {
    await _db.collection('tickets').add({
      'userId': _auth.currentUser?.uid,
      'passengerName': ticket.passengerName,
      'route': ticket.route,
      'terminal': ticket.terminal,
      'seatNumber': ticket.seatNumber,
      'fare': ticket.fare,
      'paymentStatus': 'paid',
      'date': FieldValue.serverTimestamp(),
      'verificationCode': ticket.qrData,
    });
  }

  // Emergency
  Future<void> sendEmergencyAlert(String type, GeoPoint location) async {
    await _db.collection('emergency_requests').add({
      'type': type,
      'userId': _auth.currentUser?.uid,
      'location': location,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Taxi Queue
  Future<void> joinTaxiQueue(String plateNumber) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final queueRef = _db.collection('queues').doc('taxi_queue');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(queueRef);
      List list = snap.data()?['list'] ?? [];
      list.add({
        'uid': uid,
        'plate': plateNumber,
        'timestamp': DateTime.now().toIso8601String(),
      });
      tx.set(queueRef, {'list': list});
    });
  }

  // Tourism
  Stream<List<Announcement>> getAnnouncements() {
    return _db.collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Announcement.fromFirestore(doc)).toList());
  }

  // Hospital & Pharmacy
  Stream<List<Hospital>> getHospitals() {
    return _db.collection('hospitals').snapshots().map((snap) => snap.docs.map((doc) => Hospital.fromFirestore(doc)).toList());
  }

  Stream<List<Pharmacy>> getPharmacies() {
    return _db.collection('pharmacies').snapshots().map((snap) => snap.docs.map((doc) => Pharmacy.fromFirestore(doc)).toList());
  }
}
