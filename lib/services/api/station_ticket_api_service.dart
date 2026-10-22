import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/station_ticket_models.dart';
import 'base_api_service.dart';

class StationTicketApiService {
  StationTicketApiService({BaseApiService? api}) : _api = api ?? BaseApiService();

  final BaseApiService _api;

  Map<String, dynamic> _json(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected server response');
  }

  Future<List<Station>> getStations() async {
    final response = await _api.get('/api/stations');
    final data = _json(response);
    return (data['stations'] as List<dynamic>? ?? const [])
        .map((item) => Station.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<StationDestination>> getDestinations(String stationId) async {
    final response = await _api.get(
      '/api/stations/${Uri.encodeComponent(stationId)}/destinations',
    );
    final data = _json(response);
    return (data['destinations'] as List<dynamic>? ?? const [])
        .map((item) => StationDestination.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TariffInfo> getQuote({
    required String routeId,
    required StationVehicleType vehicleType,
  }) async {
    final response = await _api.get(
      '/api/tariffs/quote',
      queryParams: {'routeId': routeId, 'vehicleType': vehicleType.wireValue},
    );
    final data = _json(response);
    return TariffInfo.fromJson(data['tariff'] as Map<String, dynamic>);
  }

  Future<TicketPurchase> purchaseTicket({
    required String routeId,
    required StationVehicleType vehicleType,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '/api/tickets',
      body: {
        'routeId': routeId,
        'vehicleType': vehicleType.wireValue,
        'idempotencyKey': idempotencyKey,
      },
    );
    return TicketPurchase.fromJson(_json(response));
  }

  Future<List<StationTicket>> getMyTickets() async {
    final response = await _api.get('/api/tickets');
    final data = _json(response);
    return (data['tickets'] as List<dynamic>? ?? const [])
        .map((item) => StationTicket.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TicketDetail> getTicket(String ticketId) async {
    final response = await _api.get(
      '/api/tickets/${Uri.encodeComponent(ticketId)}',
    );
    return TicketDetail.fromJson(_json(response));
  }

  Future<void> completeDevPayment(String ticketId) async {
    await _api.post(
      '/api/payments/dev/complete',
      body: {'ticketId': ticketId},
    );
  }

  Future<List<DriverVehicle>> getDriverVehicles() async {
    final response = await _api.get('/api/station/vehicles');
    final data = _json(response);
    return (data['vehicles'] as List<dynamic>? ?? const [])
        .map((item) => DriverVehicle.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<QueueSnapshot> getQueue(String stationId, {String? vehicleId}) async {
    final response = await _api.get(
      '/api/queue',
      queryParams: {
        'stationId': stationId,
        'vehicleId': ?vehicleId,
      },
    );
    return QueueSnapshot.fromJson(_json(response));
  }

  Future<String> checkIn({
    required String stationId,
    required String vehicleId,
  }) async {
    final response = await _api.post(
      '/api/queue/check-in',
      body: {'stationId': stationId, 'vehicleId': vehicleId},
    );
    return _json(response)['queueId'].toString();
  }

  Future<bool> checkOut(String vehicleId) async {
    final response = await _api.post(
      '/api/queue/check-out',
      body: {'vehicleId': vehicleId},
    );
    return _json(response)['checkedOut'] as bool? ?? false;
  }

  Future<VerificationOutcome> verifyQr({
    required String qrToken,
    required String vehicleId,
  }) async {
    final response = await _api.post(
      '/api/tickets/verify',
      body: {'qrToken': qrToken, 'vehicleId': vehicleId},
    );
    return VerificationOutcome.fromJson(_json(response));
  }

  Future<VerificationOutcome> verifyCode({
    required String code,
    required String vehicleId,
  }) async {
    final response = await _api.post(
      '/api/tickets/verify-code',
      body: {'code': code, 'vehicleId': vehicleId},
    );
    return VerificationOutcome.fromJson(_json(response));
  }

  Future<StationMetrics> getTaxiMetrics() async {
    final response = await _api.get('/api/admin/taxi/metrics');
    return StationMetrics.fromJson(_json(response));
  }

  Future<List<Station>> getAdminStations() async {
    final response = await _api.get('/api/admin/stations');
    final data = _json(response);
    return (data['stations'] as List<dynamic>? ?? const [])
        .map((item) => Station.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<String> createStation({
    required String name,
    String? nameAm,
    double? lat,
    double? lng,
  }) async {
    final response = await _api.post(
      '/api/admin/stations',
      body: {
        'name': name,
        if (nameAm != null && nameAm.trim().isNotEmpty) 'nameAm': nameAm.trim(),
        'lat': ?lat,
        'lng': ?lng,
      },
    );
    return _json(response)['stationId'].toString();
  }

  Future<List<AdminRoute>> getAdminRoutes() async {
    final response = await _api.get('/api/admin/routes');
    final data = _json(response);
    return (data['routes'] as List<dynamic>? ?? const [])
        .map((item) => AdminRoute.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<String> createRoute({
    required String fromStationId,
    required String toStationId,
  }) async {
    final response = await _api.post(
      '/api/admin/routes',
      body: {
        'fromStationId': fromStationId,
        'toStationId': toStationId,
      },
    );
    return _json(response)['routeId'].toString();
  }

  Future<List<TariffInfo>> getAdminTariffs({String? routeId}) async {
    final response = await _api.get(
      '/api/admin/tariffs',
      queryParams: {'routeId': ?routeId},
    );
    final data = _json(response);
    return (data['tariffs'] as List<dynamic>? ?? const [])
        .map((item) => TariffInfo.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<String> createTariff({
    required String routeId,
    required StationVehicleType vehicleType,
    required double fareEtb,
    required String effectiveFrom,
    required String sourceReference,
    required String approvedBy,
  }) async {
    final response = await _api.post(
      '/api/admin/tariffs',
      body: {
        'routeId': routeId,
        'vehicleType': vehicleType.wireValue,
        'fareEtb': fareEtb,
        'effectiveFrom': effectiveFrom,
        'sourceReference': sourceReference,
        'approvedBy': approvedBy,
      },
    );
    return _json(response)['tariffId'].toString();
  }

  Future<CatalogImportResult> importCatalog({
    required String stationsCsv,
    required String routesCsv,
    required String tariffsCsv,
    required bool commit,
  }) async {
    try {
      final response = await _api.post(
        '/api/admin/import',
        body: {
          'stationsCsv': stationsCsv,
          'routesCsv': routesCsv,
          'tariffsCsv': tariffsCsv,
          'commit': commit,
        },
      );
      return CatalogImportResult.fromJson(_json(response));
    } on ApiException catch (error) {
      final data = error.data;
      if (data is Map<String, dynamic> && data['errors'] is List) {
        return CatalogImportResult.fromJson(data);
      }
      rethrow;
    }
  }

  void dispose() {
    _api.dispose();
  }
}
