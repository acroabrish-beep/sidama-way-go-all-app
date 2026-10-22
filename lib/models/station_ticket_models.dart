enum StationVehicleType {
  taxi('taxi', 'Taxi'),
  bajaj('bajaj', 'Bajaj'),
  minibus('minibus', 'Minibus');

  const StationVehicleType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static StationVehicleType parse(String value) {
    return values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () => throw FormatException('Unknown vehicle type: $value'),
    );
  }
}

double _toDouble(dynamic value, String field) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid number for $field');
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _toInt(dynamic value, String field) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Invalid integer for $field');
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime _toDate(dynamic value, String field) {
  if (value is String && value.isNotEmpty) return DateTime.parse(value).toLocal();
  throw FormatException('Missing date for $field');
}

DateTime? _toNullableDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.parse(value).toLocal();
  return null;
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a JSON object');
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

class Station {
  const Station({
    required this.id,
    required this.name,
    this.nameAm,
    this.lat,
    this.lng,
    this.active = true,
  });

  final String id;
  final String name;
  final String? nameAm;
  final double? lat;
  final double? lng;
  final bool active;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'].toString(),
      name: json['name'].toString(),
      nameAm: _toNullableString(json['name_am']),
      lat: _toNullableDouble(json['lat']),
      lng: _toNullableDouble(json['lng']),
      active: json['active'] as bool? ?? true,
    );
  }
}

class TariffInfo {
  const TariffInfo({
    required this.id,
    required this.routeId,
    required this.vehicleType,
    required this.fareEtb,
    required this.effectiveFrom,
    this.effectiveTo,
    this.sourceReference,
    this.approvedBy,
    this.createdBy,
  });

  final String id;
  final String routeId;
  final StationVehicleType vehicleType;
  final double fareEtb;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String? sourceReference;
  final String? approvedBy;
  final String? createdBy;

  bool get isOfficial =>
      (sourceReference?.trim().isNotEmpty ?? false) &&
      (approvedBy?.trim().isNotEmpty ?? false);

  String get label =>
      isOfficial ? 'Official tariff' : 'Tariff pending approval';

  factory TariffInfo.fromJson(Map<String, dynamic> json) {
    return TariffInfo(
      id: json['id'].toString(),
      routeId: json['route_id'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicle_type'].toString()),
      fareEtb: _toDouble(json['fare_etb'], 'fare_etb'),
      effectiveFrom: _toDate(json['effective_from'], 'effective_from'),
      effectiveTo: _toNullableDate(json['effective_to']),
      sourceReference: _toNullableString(json['source_reference']),
      approvedBy: _toNullableString(json['approved_by']),
      createdBy: _toNullableString(json['created_by']),
    );
  }
}

class StationDestination {
  const StationDestination({
    required this.routeId,
    required this.station,
    required this.tariffs,
    required this.queueCounts,
  });

  final String routeId;
  final Station station;
  final List<TariffInfo> tariffs;
  final Map<StationVehicleType, int> queueCounts;

  factory StationDestination.fromJson(Map<String, dynamic> json) {
    final counts = _asMap(json['queue_counts']);
    return StationDestination(
      routeId: json['route_id'].toString(),
      station: Station.fromJson(_asMap(json['station'])),
      tariffs: _asList(json['tariffs'])
          .map((item) => TariffInfo.fromJson(_asMap(item)))
          .toList(growable: false),
      queueCounts: {
        for (final type in StationVehicleType.values)
          type: _toNullableInt(counts[type.wireValue]) ?? 0,
      },
    );
  }
}

class PaymentInfo {
  const PaymentInfo({
    required this.provider,
    this.providerRef,
    this.amountEtb,
    this.status,
    this.verifiedAt,
    this.createdAt,
    this.checkoutUrl,
    this.devPayment = false,
  });

  final String provider;
  final String? providerRef;
  final double? amountEtb;
  final String? status;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final String? checkoutUrl;
  final bool devPayment;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      provider: json['provider'].toString(),
      providerRef: _toNullableString(json['provider_ref'] ?? json['providerRef']),
      amountEtb: _toNullableDouble(json['amount_etb'] ?? json['amountEtb']),
      status: _toNullableString(json['status']),
      verifiedAt: _toNullableDate(json['verified_at'] ?? json['verifiedAt']),
      createdAt: _toNullableDate(json['created_at'] ?? json['createdAt']),
      checkoutUrl: _toNullableString(json['checkout_url'] ?? json['checkoutUrl']),
      devPayment: json['devPayment'] as bool? ?? false,
    );
  }
}

class RouteSummary {
  const RouteSummary({required this.id, this.from, this.to});

  final String id;
  final Station? from;
  final Station? to;

  String get label {
    final fromName = from?.name ?? 'Unknown station';
    final toName = to?.name ?? 'Unknown station';
    return '$fromName → $toName';
  }

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      id: json['id'].toString(),
      from: json['from'] == null ? null : Station.fromJson(_asMap(json['from'])),
      to: json['to'] == null ? null : Station.fromJson(_asMap(json['to'])),
    );
  }
}

class StationTicket {
  const StationTicket({
    required this.id,
    required this.code,
    required this.routeId,
    required this.vehicleType,
    required this.fareEtb,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.usedAt,
    this.verifiedVehicleId,
    this.route,
    this.payment,
  });

  final String id;
  final String code;
  final String routeId;
  final StationVehicleType vehicleType;
  final double fareEtb;
  final String status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? verifiedVehicleId;
  final RouteSummary? route;
  final PaymentInfo? payment;

  bool get isUsable => status == 'paid';
  bool get isPendingPayment => status == 'pending_payment';

  factory StationTicket.fromJson(Map<String, dynamic> json) {
    return StationTicket(
      id: json['id'].toString(),
      code: json['code'].toString(),
      routeId: json['route_id'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicle_type'].toString()),
      fareEtb: _toDouble(json['fare_etb'], 'fare_etb'),
      status: json['status'].toString(),
      issuedAt: _toDate(json['issued_at'], 'issued_at'),
      expiresAt: _toDate(json['expires_at'], 'expires_at'),
      usedAt: _toNullableDate(json['used_at']),
      verifiedVehicleId: _toNullableString(json['verified_vehicle_id']),
      route: json['route'] == null
          ? null
          : RouteSummary.fromJson(_asMap(json['route'])),
      payment: json['payment'] == null
          ? null
          : PaymentInfo.fromJson(_asMap(json['payment'])),
    );
  }
}

class TicketDetail {
  const TicketDetail({
    required this.ticket,
    this.route,
    this.tariff,
    this.payment,
    this.qrToken,
    this.qrError,
  });

  final StationTicket ticket;
  final RouteSummary? route;
  final TariffInfo? tariff;
  final PaymentInfo? payment;
  final String? qrToken;
  final String? qrError;

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    return TicketDetail(
      ticket: StationTicket.fromJson(_asMap(json['ticket'])),
      route: json['route'] == null
          ? null
          : RouteSummary.fromJson(_asMap(json['route'])),
      tariff: json['tariff'] == null
          ? null
          : TariffInfo.fromJson(_asMap(json['tariff'])),
      payment: json['payment'] == null
          ? null
          : PaymentInfo.fromJson(_asMap(json['payment'])),
      qrToken: _toNullableString(json['qrToken']),
      qrError: _toNullableString(json['qrError']),
    );
  }
}

class TicketPurchase {
  const TicketPurchase({
    required this.ticket,
    this.payment,
    this.replayed = false,
  });

  final StationTicket ticket;
  final PaymentInfo? payment;
  final bool replayed;

  factory TicketPurchase.fromJson(Map<String, dynamic> json) {
    return TicketPurchase(
      ticket: StationTicket.fromJson(_asMap(json['ticket'])),
      payment: json['payment'] == null
          ? null
          : PaymentInfo.fromJson(_asMap(json['payment'])),
      replayed: json['replayed'] as bool? ?? false,
    );
  }
}

class DriverVehicle {
  const DriverVehicle({
    required this.id,
    required this.registrationNumber,
    required this.vehicleType,
    required this.status,
  });

  final String id;
  final String registrationNumber;
  final StationVehicleType vehicleType;
  final String status;

  factory DriverVehicle.fromJson(Map<String, dynamic> json) {
    return DriverVehicle(
      id: json['id'].toString(),
      registrationNumber: json['registration_number'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicle_type'].toString()),
      status: json['status'].toString(),
    );
  }
}

class QueueEntry {
  const QueueEntry({
    required this.queueId,
    required this.vehicleId,
    required this.vehicleType,
    required this.checkedInAt,
    this.position,
  });

  final String queueId;
  final String vehicleId;
  final StationVehicleType vehicleType;
  final DateTime checkedInAt;
  final int? position;

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      queueId: json['queueId'].toString(),
      vehicleId: json['vehicleId'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicleType'].toString()),
      checkedInAt: _toDate(json['checkedInAt'], 'checkedInAt'),
      position: _toNullableInt(json['position']),
    );
  }
}

class WaitingVehicle {
  const WaitingVehicle({
    required this.queueId,
    required this.vehicleId,
    required this.vehicleType,
    required this.checkedInAt,
    this.registrationNumber,
  });

  final String queueId;
  final String vehicleId;
  final StationVehicleType vehicleType;
  final DateTime checkedInAt;
  final String? registrationNumber;

  factory WaitingVehicle.fromJson(Map<String, dynamic> json) {
    return WaitingVehicle(
      queueId: json['queueId'].toString(),
      vehicleId: json['vehicleId'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicleType'].toString()),
      checkedInAt: _toDate(json['checkedInAt'], 'checkedInAt'),
      registrationNumber: _toNullableString(json['registrationNumber']),
    );
  }
}

class QueueSnapshot {
  const QueueSnapshot({
    required this.stationId,
    required this.counts,
    required this.nextWaitingVehicles,
    this.myEntry,
  });

  final String stationId;
  final Map<StationVehicleType, int> counts;
  final List<WaitingVehicle> nextWaitingVehicles;
  final QueueEntry? myEntry;

  factory QueueSnapshot.fromJson(Map<String, dynamic> json) {
    final counts = _asMap(json['counts']);
    return QueueSnapshot(
      stationId: json['stationId'].toString(),
      counts: {
        for (final type in StationVehicleType.values)
          type: _toNullableInt(counts[type.wireValue]) ?? 0,
      },
      nextWaitingVehicles: _asList(json['nextWaitingVehicles'])
          .map((item) => WaitingVehicle.fromJson(_asMap(item)))
          .toList(growable: false),
      myEntry: json['myEntry'] == null
          ? null
          : QueueEntry.fromJson(_asMap(json['myEntry'])),
    );
  }
}

enum VerificationResult {
  valid('valid'),
  alreadyUsed('already_used'),
  expired('expired'),
  invalid('invalid');

  const VerificationResult(this.wireValue);

  final String wireValue;

  static VerificationResult parse(String value) {
    return values.firstWhere(
      (result) => result.wireValue == value,
      orElse: () => throw FormatException('Unknown verification result: $value'),
    );
  }
}

class VerificationOutcome {
  const VerificationOutcome({
    required this.result,
    this.ticket,
    this.route,
    this.routeError,
  });

  final VerificationResult result;
  final StationTicket? ticket;
  final RouteSummary? route;
  final String? routeError;

  factory VerificationOutcome.fromJson(Map<String, dynamic> json) {
    return VerificationOutcome(
      result: VerificationResult.parse(json['result'].toString()),
      ticket: json['ticket'] == null
          ? null
          : StationTicket.fromJson(_asMap(json['ticket'])),
      route: json['route'] == null
          ? null
          : RouteSummary.fromJson(_asMap(json['route'])),
      routeError: _toNullableString(json['routeError']),
    );
  }
}

class LiveQueueCount {
  const LiveQueueCount({
    required this.stationId,
    required this.vehicleType,
    required this.count,
    this.station,
  });

  final String stationId;
  final StationVehicleType vehicleType;
  final int count;
  final String? station;

  factory LiveQueueCount.fromJson(Map<String, dynamic> json) {
    return LiveQueueCount(
      stationId: json['stationId'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicleType'].toString()),
      count: _toInt(json['count'], 'count'),
      station: _toNullableString(json['station']),
    );
  }
}

class HourlyTicketCount {
  const HourlyTicketCount({required this.hour, required this.tickets});

  final DateTime hour;
  final int tickets;

  factory HourlyTicketCount.fromJson(Map<String, dynamic> json) {
    return HourlyTicketCount(
      hour: _toDate(json['hour'], 'hour'),
      tickets: _toInt(json['tickets'], 'tickets'),
    );
  }
}

class TopRouteStat {
  const TopRouteStat({
    required this.routeId,
    required this.tickets,
    this.from,
    this.to,
  });

  final String routeId;
  final int tickets;
  final String? from;
  final String? to;

  factory TopRouteStat.fromJson(Map<String, dynamic> json) {
    return TopRouteStat(
      routeId: json['routeId'].toString(),
      tickets: _toInt(json['tickets'], 'tickets'),
      from: _toNullableString(json['from']),
      to: _toNullableString(json['to']),
    );
  }
}

class ReconciliationRow {
  const ReconciliationRow({
    required this.paymentId,
    required this.paymentStatus,
    required this.mismatch,
    this.providerRef,
    this.paymentAmountEtb,
    this.ticketCode,
    this.ticketStatus,
    this.ticketFareEtb,
  });

  final String paymentId;
  final String paymentStatus;
  final bool mismatch;
  final String? providerRef;
  final double? paymentAmountEtb;
  final String? ticketCode;
  final String? ticketStatus;
  final double? ticketFareEtb;

  factory ReconciliationRow.fromJson(Map<String, dynamic> json) {
    return ReconciliationRow(
      paymentId: json['paymentId'].toString(),
      paymentStatus: json['paymentStatus'].toString(),
      mismatch: json['mismatch'] as bool? ?? false,
      providerRef: _toNullableString(json['providerRef']),
      paymentAmountEtb: _toNullableDouble(json['paymentAmountEtb']),
      ticketCode: _toNullableString(json['ticketCode']),
      ticketStatus: _toNullableString(json['ticketStatus']),
      ticketFareEtb: _toNullableDouble(json['ticketFareEtb']),
    );
  }
}

class StationMetrics {
  const StationMetrics({
    required this.generatedAt,
    required this.ticketsSoldToday,
    required this.ticketsSold7d,
    required this.ticketsSold30d,
    required this.revenueToday,
    required this.revenue7d,
    required this.revenue30d,
    required this.expiredTickets,
    required this.activeDrivers,
    required this.liveQueue,
    required this.ticketsPerHour,
    required this.topRoutes,
    required this.reconciliation,
    this.verificationRate,
  });

  final DateTime generatedAt;
  final int ticketsSoldToday;
  final int ticketsSold7d;
  final int ticketsSold30d;
  final double revenueToday;
  final double revenue7d;
  final double revenue30d;
  final double? verificationRate;
  final int expiredTickets;
  final int activeDrivers;
  final List<LiveQueueCount> liveQueue;
  final List<HourlyTicketCount> ticketsPerHour;
  final List<TopRouteStat> topRoutes;
  final List<ReconciliationRow> reconciliation;

  factory StationMetrics.fromJson(Map<String, dynamic> json) {
    final sold = _asMap(json['ticketsSold']);
    final revenue = _asMap(json['paidRevenueEtb']);
    return StationMetrics(
      generatedAt: _toDate(json['generatedAt'], 'generatedAt'),
      ticketsSoldToday: _toInt(sold['today'], 'ticketsSold.today'),
      ticketsSold7d: _toInt(sold['days7'], 'ticketsSold.days7'),
      ticketsSold30d: _toInt(sold['days30'], 'ticketsSold.days30'),
      revenueToday: _toDouble(revenue['today'], 'paidRevenueEtb.today'),
      revenue7d: _toDouble(revenue['days7'], 'paidRevenueEtb.days7'),
      revenue30d: _toDouble(revenue['days30'], 'paidRevenueEtb.days30'),
      verificationRate: _toNullableDouble(json['verificationRate']),
      expiredTickets: _toInt(json['expiredTickets'], 'expiredTickets'),
      activeDrivers: _toInt(json['activeDrivers'], 'activeDrivers'),
      liveQueue: _asList(json['liveQueue'])
          .map((item) => LiveQueueCount.fromJson(_asMap(item)))
          .toList(growable: false),
      ticketsPerHour: _asList(json['ticketsPerHour'])
          .map((item) => HourlyTicketCount.fromJson(_asMap(item)))
          .toList(growable: false),
      topRoutes: _asList(json['topRoutes'])
          .map((item) => TopRouteStat.fromJson(_asMap(item)))
          .toList(growable: false),
      reconciliation: _asList(json['reconciliation'])
          .map((item) => ReconciliationRow.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

class AdminRoute {
  const AdminRoute({
    required this.id,
    required this.fromStationId,
    required this.toStationId,
    required this.active,
  });

  final String id;
  final String fromStationId;
  final String toStationId;
  final bool active;

  factory AdminRoute.fromJson(Map<String, dynamic> json) {
    return AdminRoute(
      id: json['id'].toString(),
      fromStationId: json['from_station_id'].toString(),
      toStationId: json['to_station_id'].toString(),
      active: json['active'] as bool? ?? true,
    );
  }
}

class ImportStationRow {
  const ImportStationRow({
    required this.name,
    this.nameAm,
    this.lat,
    this.lng,
  });

  final String name;
  final String? nameAm;
  final double? lat;
  final double? lng;

  factory ImportStationRow.fromJson(Map<String, dynamic> json) {
    return ImportStationRow(
      name: json['name'].toString(),
      nameAm: _toNullableString(json['name_am']),
      lat: _toNullableDouble(json['lat']),
      lng: _toNullableDouble(json['lng']),
    );
  }
}

class ImportRouteRow {
  const ImportRouteRow({
    required this.fromStation,
    required this.toStation,
  });

  final String fromStation;
  final String toStation;

  factory ImportRouteRow.fromJson(Map<String, dynamic> json) {
    return ImportRouteRow(
      fromStation: json['from_station'].toString(),
      toStation: json['to_station'].toString(),
    );
  }
}

class ImportTariffRow {
  const ImportTariffRow({
    required this.fromStation,
    required this.toStation,
    required this.vehicleType,
    required this.fareEtb,
    required this.effectiveFrom,
    required this.sourceReference,
    required this.approvedBy,
  });

  final String fromStation;
  final String toStation;
  final StationVehicleType vehicleType;
  final double fareEtb;
  final String effectiveFrom;
  final String sourceReference;
  final String approvedBy;

  factory ImportTariffRow.fromJson(Map<String, dynamic> json) {
    return ImportTariffRow(
      fromStation: json['from_station'].toString(),
      toStation: json['to_station'].toString(),
      vehicleType: StationVehicleType.parse(json['vehicle_type'].toString()),
      fareEtb: _toDouble(json['fare_etb'], 'fare_etb'),
      effectiveFrom: json['effective_from'].toString(),
      sourceReference: json['source_reference'].toString(),
      approvedBy: json['approved_by'].toString(),
    );
  }
}

class CatalogImportResult {
  const CatalogImportResult({
    required this.valid,
    required this.committed,
    this.errors = const [],
    this.stations = const [],
    this.routes = const [],
    this.tariffs = const [],
    this.summary,
  });

  final bool valid;
  final bool committed;
  final List<String> errors;
  final List<ImportStationRow> stations;
  final List<ImportRouteRow> routes;
  final List<ImportTariffRow> tariffs;
  final Map<String, int>? summary;

  factory CatalogImportResult.fromJson(Map<String, dynamic> json) {
    final preview = json['preview'] is Map ? _asMap(json['preview']) : null;
    final summaryJson = json['summary'] is Map ? _asMap(json['summary']) : null;
    return CatalogImportResult(
      valid: json['valid'] as bool? ?? false,
      committed: json['committed'] as bool? ?? false,
      errors: _asList(json['errors']).map((item) => item.toString()).toList(),
      stations: preview == null
          ? const []
          : _asList(preview['stations'])
              .map((item) => ImportStationRow.fromJson(_asMap(item)))
              .toList(growable: false),
      routes: preview == null
          ? const []
          : _asList(preview['routes'])
              .map((item) => ImportRouteRow.fromJson(_asMap(item)))
              .toList(growable: false),
      tariffs: preview == null
          ? const []
          : _asList(preview['tariffs'])
              .map((item) => ImportTariffRow.fromJson(_asMap(item)))
              .toList(growable: false),
      summary: summaryJson?.map(
        (key, value) => MapEntry(key, _toInt(value, key)),
      ),
    );
  }
}
