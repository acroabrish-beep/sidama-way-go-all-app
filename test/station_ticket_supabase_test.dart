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

    test('the service no longer calls the Next.js API', () {
      for (final route in [
        '/api/payments/dev/complete',
        '/api/station/vehicles',
        '/api/queue',
        '/api/admin/',
        "'/api/",
      ]) {
        expect(source.contains(route), isFalse, reason: route);
      }
      expect(source.contains('BaseApiService('), isFalse);
      expect(source.contains('package:http/http.dart'), isFalse);
      expect(source.contains('AppConfig.apiBaseUrl'), isFalse);
      expect(source.contains('http.Response'), isFalse);
    });

    test('the admin catalog is read directly from Supabase', () {
      final stations = section(
        source,
        'Future<List<Station>> getAdminStations',
        'Future<List<AdminRoute>> getAdminRoutes',
      );
      expect(stations.contains(".from('st_stations')"), isTrue);
      expect(stations.contains(".eq('active', true)"), isFalse);

      final routes = section(
        source,
        'Future<List<AdminRoute>> getAdminRoutes',
        'Future<List<TariffInfo>> getAdminTariffs',
      );
      expect(routes.contains(".from('st_routes')"), isTrue);

      final tariffs = section(
        source,
        'Future<List<TariffInfo>> getAdminTariffs',
        '\n}',
      );
      expect(tariffs.contains(".from('st_tariffs')"), isTrue);
      expect(tariffs.contains(".eq('route_id', routeId)"), isTrue);
    });

    test('the deferred station features are labelled Phase 5 in the UI', () {
      final driver = read('lib/screens/station/driver_station_screen.dart');
      expect(driver.contains('Phase 5'), isTrue);
      expect(driver.contains('StationTicketApiService'), isFalse);
      expect(driver.contains('_api.'), isFalse);

      final metrics = read('lib/screens/station/station_metrics_overview.dart');
      expect(metrics.contains('Phase 5'), isTrue);
      expect(metrics.contains('StationTicketApiService'), isFalse);
      expect(metrics.contains('_api.'), isFalse);
      expect(metrics.contains('RealtimeService'), isFalse);

      final catalog = read(
        'lib/screens/station/admin_station_catalog_screen.dart',
      );
      expect(catalog.contains('Phase 5'), isTrue);
      for (final removed in [
        'createStation',
        'createRoute',
        'createTariff',
        'importCatalog',
      ]) {
        expect(catalog.contains(removed), isFalse, reason: removed);
      }

      final detail = read(
        'lib/screens/station/station_ticket_detail_screen.dart',
      );
      expect(detail.contains('completeDevPayment'), isFalse);
      expect(detail.contains('/api/payments/dev/complete'), isFalse);
      expect(detail.contains('Phase 5'), isTrue);
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
