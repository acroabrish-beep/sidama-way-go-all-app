/// Typed payload for the Supabase `get_admin_overview` RPC.
///
/// Every field is produced by the backend from Supabase. The client must not
/// substitute defaults for a malformed response; [AdminOverview.fromJson]
/// throws [FormatException] so the UI can show an honest error instead.
class AdminOverview {
  const AdminOverview({
    required this.generatedAt,
    required this.usersTotal,
    required this.citizenReportsTotal,
    required this.citizenReportsPending,
    required this.ticketsTotal,
    required this.ticketsPaid,
    required this.paidRevenueEtb,
    required this.queueWaiting,
    required this.activeDrivers,
    required this.hotelReservationsTotal,
    required this.sosIncidentsTotal,
    required this.revenueByDay,
    required this.latestReports,
  });

  final DateTime generatedAt;
  final int usersTotal;
  final int citizenReportsTotal;
  final int citizenReportsPending;
  final int ticketsTotal;
  final int ticketsPaid;
  final double paidRevenueEtb;
  final int queueWaiting;
  final int activeDrivers;
  final int hotelReservationsTotal;
  final int sosIncidentsTotal;
  final List<AdminRevenueDay> revenueByDay;
  final List<AdminLatestReport> latestReports;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final days = _list(json['revenueByDay']);
    final reports = _list(json['latestReports']);

    return AdminOverview(
      generatedAt: _date(json['generatedAt']),
      usersTotal: _count(json['usersTotal']),
      citizenReportsTotal: _count(json['citizenReportsTotal']),
      citizenReportsPending: _count(json['citizenReportsPending']),
      ticketsTotal: _count(json['ticketsTotal']),
      ticketsPaid: _count(json['ticketsPaid']),
      paidRevenueEtb: _money(json['paidRevenueEtb']),
      queueWaiting: _count(json['queueWaiting']),
      activeDrivers: _count(json['activeDrivers']),
      hotelReservationsTotal: _count(json['hotelReservationsTotal']),
      sosIncidentsTotal: _count(json['sosIncidentsTotal']),
      revenueByDay: days
          .map((day) {
            return AdminRevenueDay.fromJson(_map(day));
          })
          .toList(growable: false),
      latestReports: reports
          .map((report) {
            return AdminLatestReport.fromJson(_map(report));
          })
          .toList(growable: false),
    );
  }
}

class AdminRevenueDay {
  const AdminRevenueDay({required this.date, required this.amountEtb});

  final String date;
  final double amountEtb;

  factory AdminRevenueDay.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    if (date is! String || date.isEmpty) {
      throw const FormatException('Missing revenue day');
    }
    return AdminRevenueDay(date: date, amountEtb: _money(json['amountEtb']));
  }
}

class AdminLatestReport {
  const AdminLatestReport({
    required this.id,
    required this.category,
    required this.status,
    required this.urgency,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String status;
  final String? urgency;
  final String? description;
  final DateTime? createdAt;

  factory AdminLatestReport.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing report id');
    }

    final createdAt = json['createdAt'];
    return AdminLatestReport(
      id: id,
      category: _string(json['category'], fallback: 'other'),
      status: _string(json['status'], fallback: 'pending'),
      urgency: _optionalString(json['urgency']),
      description: _optionalString(json['description']),
      createdAt: createdAt is String && createdAt.isNotEmpty
          ? DateTime.tryParse(createdAt)
          : null,
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Expected an object');
}

List<Object?> _list(Object? value) {
  if (value is List) return value;
  throw const FormatException('Expected a list');
}

String _string(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? _optionalString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int _count(Object? value) {
  final parsed = value is int
      ? value
      : value is num
      ? value.toInt()
      : value is String
      ? int.tryParse(value)
      : null;
  if (parsed == null || parsed < 0) {
    throw const FormatException('Invalid count');
  }
  return parsed;
}

double _money(Object? value) {
  final parsed = value is num
      ? value.toDouble()
      : value is String
      ? double.tryParse(value)
      : null;
  if (parsed == null || !parsed.isFinite || parsed < 0) {
    throw const FormatException('Invalid amount');
  }
  return parsed;
}

DateTime _date(Object? value) {
  if (value is! String) throw const FormatException('Invalid date');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed;
}
