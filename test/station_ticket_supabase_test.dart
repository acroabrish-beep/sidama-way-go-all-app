import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

String section(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  if (startIndex < 0 || endIndex < 0) {
    throw StateError('Could not locate section between "$start" and "$end"');
  }
  return source.substring(startIndex, endIndex);
}

void main() {
  final source = read('lib/services/api/station_ticket_api_service.dart');

  group('station tickets use Supabase directly', () {
    test('reads the operational station tables', () {
      for (final table in [
        'st_stations',
        'st_routes',
        'st_tariffs',
        'st_tickets',
        'st_payments',
        'st_queue',
      ]) {
        expect(source.contains("'$table'"), isTrue, reason: table);
      }
      expect(source.contains('transport_stations'), isFalse);
    });

    test('purchase, detail and verification go through Edge Functions', () {
      expect(source.contains("_invoke('purchase-ticket'"), isTrue);
      expect(source.contains("_invoke('ticket-qr'"), isTrue);
      expect(
        RegExp(r"_invoke\('verify-ticket'").allMatches(source).length,
        2,
        reason: 'QR and manual code both use verify-ticket',
      );
    });

    test('migrated methods no longer call the Next.js ticket routes', () {
      for (final route in [
        '/api/tickets',
        '/api/tickets/verify',
        '/api/tariffs/quote',
        '/api/stations/',
      ]) {
        expect(source.contains(route), isFalse, reason: route);
      }
    });

    test('purchase and verification send the Firebase token, not a secret', () {
      final block = section(
        source,
        'Future<Map<String, dynamic>> _invoke',
        '\n  ApiException _functionError',
      );
      expect(block.contains("'Authorization': 'Bearer \$token'"), isTrue);
      expect(block.contains("'apikey': key"), isTrue);
      expect(block.toLowerCase().contains('service_role'), isFalse);
      expect(block.contains('FIREBASE_SERVICE_ACCOUNT'), isFalse);
      expect(block.contains('QR_SIGNING_SECRET'), isFalse);
    });

    test('tickets are read only for the signed-in passenger', () {
      final block = section(
        source,
        'Future<List<StationTicket>> getMyTickets',
        'Future<TicketDetail> getTicket',
      );
      expect(block.contains(".eq('passenger_firebase_uid', user.uid)"), isTrue);
    });

    test('the client never writes station tables', () {
      expect(source.contains('.insert('), isFalse);
      expect(source.contains('.update('), isFalse);
      expect(source.contains('.upsert('), isFalse);
      expect(source.contains('.delete('), isFalse);
    });

    test('only the staging dev-payment helper remains on the backend', () {
      expect(source.contains("'/api/payments/dev/complete'"), isTrue);
      expect(source.contains("'/api/station/vehicles'"), isTrue);
      expect(source.contains("'/api/queue'"), isTrue);
      expect(source.contains("'/api/admin/"), isTrue);
    });

    test('fares are selected by the server date rules', () {
      final block = section(
        source,
        'bool _isActiveTariffRow',
        'Future<List<Station>> getStations',
      );
      expect(block.contains('effective_from'), isTrue);
      expect(block.contains('effective_to'), isTrue);
      expect(block.contains('compareTo(today)'), isTrue);
    });
  });
}
