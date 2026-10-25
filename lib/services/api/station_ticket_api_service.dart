import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../models/station_ticket_models.dart';
import 'base_api_service.dart';

class StationTicketApiService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<T> _withDb<T>(
    Future<T> Function() action,
    String failureMessage, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return await action().timeout(timeout);
    } on PostgrestException catch (error) {
      throw ApiException(
        '$failureMessage: ${error.message}',
        code: error.code,
        originalError: error,
      );
    } on TimeoutException {
      throw ApiException(
        '$failureMessage: the request timed out. Please try again.',
        code: 'network_timeout',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(failureMessage, originalError: error);
    }
  }

  Future<String> _firebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('Sign in again to continue.', code: 'no_session');
    }
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Sign in again to continue.', code: 'no_session');
      }
      return token;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'Your sign-in session could not be read. Please sign in again.',
        code: 'token_unavailable',
        originalError: error,
      );
    }
  }

  String _anonKey() {
    try {
      final key = AppConfig.supabaseAnonKey.trim();
      if (key.isEmpty) throw const FormatException('missing key');
      return key;
    } catch (_) {
      throw ApiException(
        'Supabase is not configured for this build.',
        code: 'supabase_not_configured',
      );
    }
  }

  Future<Map<String, dynamic>> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final token = await _firebaseToken();
    final key = _anonKey();
    try {
      final response = await _client.functions
          .invoke(
            functionName,
            body: body,
            headers: {'Authorization': 'Bearer $token', 'apikey': key},
          )
          .timeout(const Duration(seconds: 30));
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw ApiException(
        'The ticket service returned an unexpected response.',
        code: 'invalid_response',
      );
    } on FunctionException catch (error) {
      throw _functionError(error);
    } on TimeoutException {
      throw ApiException(
        'The ticket service timed out. Please try again.',
        code: 'network_timeout',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'Could not reach the ticket service. Check your connection and try again.',
        code: 'network_error',
        originalError: error,
      );
    }
  }

  ApiException _functionError(FunctionException error) {
    final details = error.details;
    String? message;
    String? code;
    if (details is Map) {
      final rawMessage = details['error'] ?? details['message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage.trim();
      }
      final rawCode = details['code'];
      if (rawCode is String && rawCode.isNotEmpty) code = rawCode;
    }
    if (error.status == 404 && code == 'NOT_FOUND') {
      message = 'The ticket service is not deployed for this build.';
    }
    return ApiException(
      message ?? _defaultFunctionMessage(error.status),
      statusCode: error.status,
      code: code,
      originalError: error,
    );
  }

  String _defaultFunctionMessage(int status) {
    switch (status) {
      case 401:
        return 'Sign in again to continue.';
      case 403:
        return 'You do not have access to this ticket service.';
      case 404:
        return 'The requested ticket record was not found.';
      case 409:
        return 'The ticket could not be updated. Refresh and try again.';
      case 429:
        return 'Too many attempts. Wait a moment and try again.';
      case 503:
        return 'The ticket service is temporarily unavailable.';
      default:
        return 'The ticket service request failed. Please try again.';
    }
  }

  String get _today {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool _isActiveTariffRow(Map<String, dynamic> row) {
    final from = row['effective_from']?.toString();
    if (from == null || from.isEmpty) return false;
    final today = _today;
    if (from.compareTo(today) > 0) return false;
    final to = row['effective_to']?.toString();
    return to == null || to.isEmpty || to.compareTo(today) > 0;
  }

  Future<List<Station>> getStations({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final rows = await _withDb(
      () => _client
          .from('st_stations')
          .select('id, name, name_am, lat, lng, active')
          .eq('active', true)
          .order('name'),
      'Unable to load stations from Supabase',
      timeout: timeout,
    );
    return rows
        .map((row) => Station.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<StationDestination>> getDestinations(String stationId) async {
    final routes = await _withDb(
      () => _client
          .from('st_routes')
          .select('id, from_station_id, to_station_id')
          .eq('from_station_id', stationId)
          .eq('active', true),
      'Unable to load destinations',
    );
    if (routes.isEmpty) return const [];

    final destinationIds = <String>{
      for (final route in routes)
        if (route['to_station_id'] != null) route['to_station_id'].toString(),
    }.toList(growable: false);
    final routeIds = <String>[
      for (final route in routes)
        if (route['id'] != null) route['id'].toString(),
    ];

    final stations = await _withDb(
      () => _client
          .from('st_stations')
          .select('id, name, name_am, lat, lng, active')
          .inFilter('id', destinationIds)
          .eq('active', true),
      'Unable to load destination stations',
    );
    final tariffs = await _withDb(
      () => _client
          .from('st_tariffs')
          .select(
            'id, route_id, vehicle_type, fare_etb, effective_from, '
            'effective_to, source_reference, approved_by',
          )
          .inFilter('route_id', routeIds)
          .lte('effective_from', _today),
      'Unable to load fares',
    );
    final queue = await _withDb(
      () => _client
          .from('st_queue')
          .select('station_id, vehicle_type')
          .eq('station_id', stationId)
          .eq('status', 'waiting'),
      'Unable to load the waiting queue',
    );

    final stationsById = {
      for (final station in stations) station['id'].toString(): station,
    };
    final activeTariffs = tariffs
        .where(_isActiveTariffRow)
        .map((row) => TariffInfo.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    final queueCounts = {for (final type in StationVehicleType.values) type: 0};
    for (final entry in queue) {
      final type = entry['vehicle_type']?.toString();
      for (final candidate in StationVehicleType.values) {
        if (candidate.wireValue == type) {
          queueCounts[candidate] = queueCounts[candidate]! + 1;
          break;
        }
      }
    }

    final destinations = <StationDestination>[];
    for (final route in routes) {
      final routeId = route['id']?.toString();
      final destinationId = route['to_station_id']?.toString();
      final station = destinationId == null
          ? null
          : stationsById[destinationId];
      if (routeId == null || station == null) continue;
      destinations.add(
        StationDestination(
          routeId: routeId,
          station: Station.fromJson(Map<String, dynamic>.from(station)),
          tariffs: activeTariffs
              .where((tariff) => tariff.routeId == routeId)
              .toList(growable: false),
          queueCounts: Map.of(queueCounts),
        ),
      );
    }
    return destinations;
  }

  Future<TariffInfo> getQuote({
    required String routeId,
    required StationVehicleType vehicleType,
  }) async {
    final route = await _withDb(
      () => _client
          .from('st_routes')
          .select('id')
          .eq('id', routeId)
          .eq('active', true)
          .maybeSingle(),
      'Unable to load the route',
    );
    if (route == null) {
      throw ApiException(
        'Route not found',
        statusCode: 404,
        code: 'route_not_found',
      );
    }

    final rows = await _withDb(
      () => _client
          .from('st_tariffs')
          .select(
            'id, route_id, vehicle_type, fare_etb, effective_from, '
            'effective_to, source_reference, approved_by',
          )
          .eq('route_id', routeId)
          .eq('vehicle_type', vehicleType.wireValue)
          .lte('effective_from', _today)
          .order('effective_from', ascending: false),
      'Unable to load the tariff',
    );
    final active = rows
        .where(_isActiveTariffRow)
        .map((row) => TariffInfo.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    if (active.isEmpty) {
      throw ApiException(
        'Tariff not set',
        statusCode: 404,
        code: 'tariff_not_set',
      );
    }
    return active.first;
  }

  Future<TicketPurchase> purchaseTicket({
    required String routeId,
    required StationVehicleType vehicleType,
    required String idempotencyKey,
  }) async {
    final data = await _invoke('purchase-ticket', {
      'routeId': routeId,
      'vehicleType': vehicleType.wireValue,
      'idempotencyKey': idempotencyKey,
    });
    return TicketPurchase.fromJson(data);
  }

  Future<List<StationTicket>> getMyTickets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('Sign in again to continue.', code: 'no_session');
    }

    final rows = await _withDb(
      () => _client
          .from('st_tickets')
          .select(
            'id, code, route_id, vehicle_type, fare_etb, status, issued_at, '
            'expires_at, used_at, verified_vehicle_id',
          )
          .eq('passenger_firebase_uid', user.uid)
          .order('issued_at', ascending: false)
          .limit(50),
      'Unable to load tickets',
    );
    if (rows.isEmpty) return const [];

    final routeIds = <String>{
      for (final row in rows)
        if (row['route_id'] != null) row['route_id'].toString(),
    }.toList(growable: false);
    final ticketIds = <String>{
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(),
    }.toList(growable: false);

    final routes = await _withDb(
      () => _client
          .from('st_routes')
          .select('id, from_station_id, to_station_id')
          .inFilter('id', routeIds),
      'Unable to load ticket routes',
    );
    final stationIds = <String>{
      for (final route in routes) ...[
        if (route['from_station_id'] != null)
          route['from_station_id'].toString(),
        if (route['to_station_id'] != null) route['to_station_id'].toString(),
      ],
    }.toList(growable: false);
    final stations = stationIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _withDb(
            () => _client
                .from('st_stations')
                .select('id, name, name_am, lat, lng, active')
                .inFilter('id', stationIds),
            'Unable to load ticket stations',
          );
    final payments = await _withDb(
      () => _client
          .from('st_payments')
          .select(
            'ticket_id, provider, provider_ref, amount_etb, status, '
            'verified_at, created_at',
          )
          .inFilter('ticket_id', ticketIds)
          .order('created_at', ascending: false),
      'Unable to load ticket payments',
    );

    final stationsById = {
      for (final station in stations) station['id'].toString(): station,
    };
    final routesById = {
      for (final route in routes) route['id'].toString(): route,
    };
    final latestPayments = <String, Map<String, dynamic>>{};
    for (final payment in payments) {
      final ticketId = payment['ticket_id']?.toString();
      if (ticketId == null || latestPayments.containsKey(ticketId)) continue;
      latestPayments[ticketId] = Map<String, dynamic>.from(payment);
    }

    return rows
        .map((row) {
          final json = Map<String, dynamic>.from(row);
          final route = routesById[row['route_id']?.toString()];
          if (route != null) {
            json['route'] = {
              'id': route['id'],
              'from': stationsById[route['from_station_id']?.toString()],
              'to': stationsById[route['to_station_id']?.toString()],
            };
          }
          final payment = latestPayments[row['id']?.toString()];
          if (payment != null) json['payment'] = payment;

          final expiresAt = DateTime.tryParse(
            row['expires_at']?.toString() ?? '',
          );
          if (json['status'] == 'pending_payment' &&
              expiresAt != null &&
              !expiresAt.isAfter(DateTime.now())) {
            json['status'] = 'expired';
          }
          return StationTicket.fromJson(json);
        })
        .toList(growable: false);
  }

  Future<TicketDetail> getTicket(String ticketId) async {
    final data = await _invoke('ticket-qr', {'ticketId': ticketId});
    return TicketDetail.fromJson(data);
  }

  Future<VerificationOutcome> verifyQr({
    required String qrToken,
    required String vehicleId,
  }) async {
    final data = await _invoke('verify-ticket', {
      'qrToken': qrToken,
      'vehicleId': vehicleId,
    });
    return VerificationOutcome.fromJson(data);
  }

  Future<VerificationOutcome> verifyCode({
    required String code,
    required String vehicleId,
  }) async {
    final data = await _invoke('verify-ticket', {
      'code': code,
      'vehicleId': vehicleId,
    });
    return VerificationOutcome.fromJson(data);
  }

  Future<List<Station>> getAdminStations({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final rows = await _withDb(
      () => _client
          .from('st_stations')
          .select('id, name, name_am, lat, lng, active')
          .order('name'),
      'Unable to load the station catalog',
      timeout: timeout,
    );
    return rows
        .map((row) => Station.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<AdminRoute>> getAdminRoutes({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final rows = await _withDb(
      () => _client
          .from('st_routes')
          .select('id, from_station_id, to_station_id, active')
          .order('from_station_id'),
      'Unable to load the route catalog',
      timeout: timeout,
    );
    return rows
        .map((row) => AdminRoute.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<TariffInfo>> getAdminTariffs({
    String? routeId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final rows = await _withDb(
      () {
        var query = _client
            .from('st_tariffs')
            .select(
              'id, route_id, vehicle_type, fare_etb, effective_from, '
              'effective_to, source_reference, approved_by, created_by',
            );
        if (routeId != null) {
          query = query.eq('route_id', routeId);
        }
        return query.order('effective_from', ascending: false);
      },
      'Unable to load tariffs',
      timeout: timeout,
    );
    return rows
        .map((row) => TariffInfo.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }
}
