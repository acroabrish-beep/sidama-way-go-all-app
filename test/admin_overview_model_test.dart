import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/admin_overview_models.dart';

Map<String, dynamic> _payload() {
  return {
    'generatedAt': '2026-10-24T10:00:00.000Z',
    'usersTotal': 12,
    'citizenReportsTotal': 7,
    'citizenReportsPending': 3,
    'ticketsTotal': 21,
    'ticketsPaid': 18,
    'paidRevenueEtb': 1250.5,
    'queueWaiting': 4,
    'activeDrivers': 6,
    'hotelReservationsTotal': 9,
    'sosIncidentsTotal': 2,
    'revenueByDay': [
      {'date': '2026-10-23', 'amountEtb': 500},
      {'date': '2026-10-24', 'amountEtb': 750.5},
    ],
    'latestReports': [
      {
        'id': 'report-1',
        'category': 'road',
        'status': 'pending',
        'urgency': 'high',
        'description': 'Pothole near the station',
        'createdAt': '2026-10-24T09:00:00.000Z',
      },
      {
        'id': 'report-2',
        'category': 'water',
        'status': 'resolved',
        'urgency': null,
        'description': null,
        'createdAt': null,
      },
    ],
  };
}

void main() {
  group('AdminOverview payload', () {
    test('parses real backend counts and report summaries', () {
      final overview = AdminOverview.fromJson(_payload());

      expect(overview.usersTotal, 12);
      expect(overview.citizenReportsTotal, 7);
      expect(overview.citizenReportsPending, 3);
      expect(overview.ticketsPaid, 18);
      expect(overview.paidRevenueEtb, 1250.5);
      expect(overview.queueWaiting, 4);
      expect(overview.activeDrivers, 6);
      expect(overview.hotelReservationsTotal, 9);
      expect(overview.sosIncidentsTotal, 2);
      expect(overview.revenueByDay, hasLength(2));
      expect(overview.revenueByDay.last.amountEtb, 750.5);
      expect(overview.latestReports, hasLength(2));
      expect(overview.latestReports.first.category, 'road');
      expect(overview.latestReports.first.urgency, 'high');
      expect(overview.latestReports.last.urgency, isNull);
      expect(overview.latestReports.last.description, isNull);
    });

    test('rejects a malformed or missing aggregate instead of inventing 0', () {
      final missing = _payload()..remove('usersTotal');
      expect(() => AdminOverview.fromJson(missing), throwsFormatException);

      final invalid = _payload()..['ticketsPaid'] = 'not-a-count';
      expect(() => AdminOverview.fromJson(invalid), throwsFormatException);

      final negative = _payload()..['queueWaiting'] = -1;
      expect(() => AdminOverview.fromJson(negative), throwsFormatException);
    });

    test('rejects a malformed revenue series', () {
      final invalid = _payload()..['revenueByDay'] = 'nope';
      expect(() => AdminOverview.fromJson(invalid), throwsFormatException);

      final badAmount = _payload();
      badAmount['revenueByDay'] = [
        {'date': '2026-10-24', 'amountEtb': -5},
      ];
      expect(() => AdminOverview.fromJson(badAmount), throwsFormatException);
    });
  });
}
