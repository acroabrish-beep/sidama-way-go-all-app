import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/station_ticket_models.dart';

void main() {
  group('TariffInfo honesty labels', () {
    TariffInfo tariff({
      String? source,
      String? approvedBy,
      String? createdBy,
    }) => TariffInfo(
      id: 'tariff-1',
      routeId: 'route-1',
      vehicleType: StationVehicleType.taxi,
      fareEtb: 25,
      effectiveFrom: DateTime(2026, 1, 1),
      sourceReference: source,
      approvedBy: approvedBy,
      createdBy: createdBy,
    );

    test('official only when source reference and approving authority exist', () {
      expect(
        tariff(
          source: 'TR-2026-01',
          approvedBy: 'Hawassa Transport Office',
        ).isOfficial,
        isTrue,
      );
      expect(
        tariff(
          source: 'TR-2026-01',
          approvedBy: 'Hawassa Transport Office',
        ).label,
        'Official tariff',
      );
    });

    test('pending approval when either field is missing or blank', () {
      for (final value in [
        tariff(source: 'TR-2026-01'),
        tariff(approvedBy: 'Hawassa Transport Office'),
        tariff(source: '   ', approvedBy: 'Hawassa Transport Office'),
        tariff(source: 'TR-2026-01', approvedBy: '  '),
      ]) {
        expect(value.isOfficial, isFalse);
        expect(value.label, 'Tariff pending approval');
      }
    });

    test('fromJson keeps approving authority separate from creator', () {
      final parsed = TariffInfo.fromJson({
        'id': 'tariff-9',
        'route_id': 'route-9',
        'vehicle_type': 'bajaj',
        'fare_etb': '18.50',
        'effective_from': '2026-03-01T00:00:00.000Z',
        'effective_to': null,
        'source_reference': 'Official letter 14/2026',
        'approved_by': 'Hawassa Transport Office',
        'created_by': 'admin-firebase-uid',
      });

      expect(parsed.vehicleType, StationVehicleType.bajaj);
      expect(parsed.fareEtb, 18.5);
      expect(parsed.approvedBy, 'Hawassa Transport Office');
      expect(parsed.createdBy, 'admin-firebase-uid');
      expect(parsed.isOfficial, isTrue);
    });
  });

  group('StationVehicleType', () {
    test('parses every wire value', () {
      expect(StationVehicleType.parse('taxi'), StationVehicleType.taxi);
      expect(StationVehicleType.parse('bajaj'), StationVehicleType.bajaj);
      expect(StationVehicleType.parse('minibus'), StationVehicleType.minibus);
    });

    test('rejects unknown wire values instead of guessing', () {
      expect(
        () => StationVehicleType.parse('bus'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('StationTicket status', () {
    StationTicket ticket(String status) => StationTicket(
      id: 'ticket-1',
      code: 'ABC123',
      routeId: 'route-1',
      vehicleType: StationVehicleType.taxi,
      fareEtb: 25,
      status: status,
      issuedAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 1, 2),
    );

    test('only paid tickets are usable at boarding', () {
      for (final status in [
        'pending_payment',
        'used',
        'expired',
        'cancelled',
        'refunded',
      ]) {
        expect(ticket(status).isUsable, isFalse, reason: status);
      }
      expect(ticket('paid').isUsable, isTrue);
    });

    test('pending state is explicit', () {
      expect(ticket('pending_payment').isPendingPayment, isTrue);
      expect(ticket('paid').isPendingPayment, isFalse);
    });
  });

  group('VerificationOutcome', () {
    test('parses all server result values', () {
      for (final result in VerificationResult.values) {
        final outcome = VerificationOutcome.fromJson({'result': result.wireValue});
        expect(outcome.result, result);
      }
    });

    test('rejects unknown results', () {
      expect(
        () => VerificationOutcome.fromJson({'result': 'trusted_by_app'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('surfaces route lookup errors instead of hiding them', () {
      final outcome = VerificationOutcome.fromJson({
        'result': 'valid',
        'ticket': {
          'id': 'ticket-1',
          'code': 'ABC123',
          'route_id': 'route-1',
          'vehicle_type': 'taxi',
          'fare_etb': 25,
          'status': 'used',
          'issued_at': '2026-01-01T10:00:00.000Z',
          'expires_at': '2026-01-02T10:00:00.000Z',
        },
        'route': null,
        'routeError': 'Route lookup failed',
      });

      expect(outcome.ticket?.status, 'used');
      expect(outcome.route, isNull);
      expect(outcome.routeError, 'Route lookup failed');
    });
  });

  group('StationMetrics', () {
    test('parses the server metrics payload', () {
      final metrics = StationMetrics.fromJson({
        'generatedAt': '2026-03-01T10:00:00.000Z',
        'ticketsSold': {'today': 3, 'days7': 10, 'days30': 40},
        'paidRevenueEtb': {'today': 75.5, 'days7': 250, 'days30': 1000},
        'verificationRate': 0.5,
        'expiredTickets': 2,
        'activeDrivers': 7,
        'liveQueue': [
          {
            'stationId': 'station-1',
            'station': 'Hawassa Main',
            'vehicleType': 'taxi',
            'count': 4,
          },
        ],
        'ticketsPerHour': [
          {'hour': '2026-03-01T09:00:00.000Z', 'tickets': 2},
        ],
        'topRoutes': [
          {
            'routeId': 'route-1',
            'from': 'A',
            'to': 'B',
            'tickets': 20,
          },
        ],
        'reconciliation': [
          {
            'paymentId': 'payment-1',
            'providerRef': 'ref-1',
            'paymentStatus': 'paid',
            'paymentAmountEtb': 25,
            'ticketCode': 'ABC123',
            'ticketStatus': 'used',
            'ticketFareEtb': 25,
            'mismatch': false,
          },
        ],
      });

      expect(metrics.ticketsSoldToday, 3);
      expect(metrics.revenueToday, 75.5);
      expect(metrics.verificationRate, 0.5);
      expect(metrics.liveQueue.single.station, 'Hawassa Main');
      expect(metrics.liveQueue.single.vehicleType, StationVehicleType.taxi);
      expect(metrics.topRoutes.single.tickets, 20);
      expect(metrics.reconciliation.single.mismatch, isFalse);
    });

    test('keeps missing verification rate unknown rather than assuming zero', () {
      final metrics = StationMetrics.fromJson({
        'generatedAt': '2026-03-01T10:00:00.000Z',
        'ticketsSold': {'today': 0, 'days7': 0, 'days30': 0},
        'paidRevenueEtb': {'today': 0, 'days7': 0, 'days30': 0},
        'verificationRate': null,
        'expiredTickets': 0,
        'activeDrivers': 0,
        'liveQueue': [],
        'ticketsPerHour': [],
        'topRoutes': [],
        'reconciliation': [],
      });

      expect(metrics.verificationRate, isNull);
    });
  });
}
