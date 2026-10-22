import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mobility_models.dart';
import '../models/taxi_models.dart';
import '../models/city_os_models.dart';

class MobilityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Intercity Bus Methods
  Future<List<BusRoute>> getBusRoutes(String terminalId) async {
    var snapshot = await _db
        .collection('bus_routes')
        .where('terminalId', isEqualTo: terminalId)
        .get();
    return snapshot.docs.map((doc) => BusRoute.fromFirestore(doc)).toList();
  }

  Future<String> bookTicket(Ticket ticket) async {
    var docRef = await _db.collection('tickets').add(ticket.toMap());
    return docRef.id;
  }

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _db
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList());
  }

  // Taxi Methods
  Future<List<TaxiRoute>> getTaxiRoutes() async {
    var snapshot = await _db.collection('taxi_routes').get();
    return snapshot.docs.map((doc) => TaxiRoute.fromFirestore(doc)).toList();
  }

  Stream<List<TaxiDriver>> getTaxiQueue(String stationId) {
    return _db
        .collection('drivers')
        .where('stationId', isEqualTo: stationId)
        .where('online', isEqualTo: true)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TaxiDriver.fromFirestore(doc)).toList());
  }

  Future<void> joinTaxiQueue(String userId, String stationId, String stationName) async {
    await _db.collection('drivers').doc(userId).update({
      'stationId': stationId,
      'stationName': stationName,
      'online': true,
      'status': 'waiting',
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Admin Methods
  Future<void> verifyTicket(String ticketId) async {
    await _db.collection('tickets').doc(ticketId).update({'isScanned': true});
  }

  Stream<Map<String, dynamic>> getCityStats() {
    return _db.collection('city_stats').doc('current').snapshots().map((doc) => doc.data() ?? {});
  }
}
