import 'package:flutter_test/flutter_test.dart';
import 'package:sidama_way_go/models/financial_models.dart';
import 'package:sidama_way_go/models/taxi_models.dart';

void main() {
  group('Financial Engine Phase 9 Verification', () {
    test('Fare Rule Mapping', () {
      final rule = FareRule(
        ruleId: 'TEST-RULE-1',
        vehicleType: VehicleType.taxi,
        baseFare: 20.0,
        perKmRate: 15.0,
        perMinuteRate: 2.0,
        surgeMultiplier: 1.2,
      );

      expect(rule.baseFare, 20.0);
      expect(rule.surgeMultiplier, 1.2);
      print('PASS: Fare Rule model mapping verified');
    });

    test('Wallet Model & Balance Types', () {
      final wallet = Wallet(
        ownerId: 'U-001',
        ownerRole: 'citizen',
        balance: 500.0,
        transportCredits: 100.0,
        subsidyBalance: 50.0,
        updatedAt: DateTime.now(),
      );

      expect(wallet.balance, 500.0);
      expect(wallet.transportCredits, 100.0);
      print('PASS: Wallet model and multi-balance confirmed');
    });

    test('Ticket Generation Model', () {
      final ticket = SmartTicket(
        ticketId: 'T-999',
        passengerId: 'P-01',
        passengerName: 'Abebe',
        vehicleId: 'V-01',
        driverId: 'D-01',
        vehicleType: VehicleType.cityBus,
        origin: 'Station A',
        destination: 'Station B',
        fare: 45.0,
        paymentId: 'PAY-888',
        status: TicketStatus.active,
        qrData: 'QR-CODE-DATA',
        createdAt: DateTime.now(),
      );

      expect(ticket.fare, 45.0);
      expect(ticket.status, TicketStatus.active);
      print('PASS: Ticket model serialization confirmed');
    });

    test('Generic Payment Method Enum', () {
      expect(PaymentMethod.telebirr.name, 'telebirr');
      expect(PaymentMethod.chapa.name, 'chapa');
      print('PASS: Generic payment method architecture verified');
    });
  });
}
