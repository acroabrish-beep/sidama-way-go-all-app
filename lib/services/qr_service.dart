import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

class QRService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> verifyTicket(String qrData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      final String ticketId = data['ticketId'];

      final doc = await _db.collection(CityOSCollection.tickets).doc(ticketId).get();
      if (!doc.exists) {
        return {'success': false, 'message': 'Invalid Ticket ID'};
      }

      final ticket = Ticket.fromFirestore(doc);
      if (ticket.isUsed) {
        return {'success': false, 'message': 'Ticket already used!'};
      }

      // Mark as used
      await _db.collection(CityOSCollection.tickets).doc(ticketId).update({
        'isUsed': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Ticket Verified Successfully',
        'ticket': ticket.toMap(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error processing QR data'};
    }
  }
}
