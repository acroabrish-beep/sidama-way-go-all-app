/// Legacy Firestore ticket verification is disabled.
///
/// Station tickets are verified by the backend against the signed QR token and
/// the driver/vehicle assignment. A client must never mark a ticket as used.
class QRService {
  Future<Map<String, dynamic>> verifyTicket(String qrData) async {
    return {
      'success': false,
      'message':
          'Legacy ticket verification is disabled. Use the station driver '
          'scanner so the server can verify the ticket.',
    };
  }
}
