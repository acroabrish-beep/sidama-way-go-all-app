import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_models.dart';
import '../models/taxi_models.dart';

class FinancialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SMART WALLET ENGINE ---

  Stream<Wallet?> getWallet(String userId) {
    return _db.collection('wallets').doc(userId).snapshots().map((doc) {
      if (doc.exists) return Wallet.fromFirestore(doc);
      return null;
    });
  }

  Future<void> topUpWallet(String userId, double amount, PaymentMethod method) async {
    await _db.runTransaction((transaction) async {
      final walletRef = _db.collection('wallets').doc(userId);
      final walletSnap = await transaction.get(walletRef);

      final paymentRef = _db.collection('payments').doc();
      final transRef = _db.collection('wallet_transactions').doc();

      if (!walletSnap.exists) {
        transaction.set(walletRef, {
          'balance': amount,
          'ownerRole': 'citizen',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(walletRef, {
          'balance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(paymentRef, {
        'userId': userId,
        'amount': amount,
        'method': method.name,
        'status': PaymentStatus.completed.name,
        'referenceType': 'topup',
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.set(transRef, {
        'walletId': userId,
        'type': WalletTransactionType.topUp.name,
        'amount': amount,
        'description': 'Wallet Top-up via ${method.name}',
        'referenceId': paymentRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- DIGITAL PAYMENT ENGINE ---

  Future<String> processPayment({
    required String userId,
    required String recipientId,
    required double amount,
    required PaymentMethod method,
    required String referenceType,
    required String referenceId,
  }) async {
    final paymentRef = _db.collection('payments').doc();

    await _db.runTransaction((transaction) async {
      // 1. If method is Wallet, check balance
      if (method == PaymentMethod.wallet) {
        final walletRef = _db.collection('wallets').doc(userId);
        final walletSnap = await transaction.get(walletRef);
        if (!walletSnap.exists || (walletSnap.get('balance') as num) < amount) {
          throw Exception('Insufficient wallet balance');
        }
        transaction.update(walletRef, {
          'balance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add transaction record
        final transRef = _db.collection('wallet_transactions').doc();
        transaction.set(transRef, {
          'walletId': userId,
          'type': WalletTransactionType.payment.name,
          'amount': -amount,
          'description': 'Payment for $referenceType',
          'referenceId': paymentRef.id,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 2. Create Payment Record
      transaction.set(paymentRef, {
        'userId': userId,
        'recipientId': recipientId,
        'amount': amount,
        'method': method.name,
        'status': PaymentStatus.completed.name,
        'referenceType': referenceType,
        'referenceId': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Update Recipient Wallet (if driver/operator)
      if (recipientId.isNotEmpty) {
        final rWalletRef = _db.collection('wallets').doc(recipientId);
        transaction.set(rWalletRef, {
          'balance': FieldValue.increment(amount * 0.8), // 80% to recipient
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4. Government Share (20%)
        final govWalletRef = _db.collection('wallets').doc('government_main');
        transaction.set(govWalletRef, {
          'balance': FieldValue.increment(amount * 0.2),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    return paymentRef.id;
  }

  // --- DIGITAL TICKETING ---

  Future<SmartTicket> generateTicket({
    required String passengerId,
    required String passengerName,
    required String vehicleId,
    required String driverId,
    required VehicleType vehicleType,
    required String origin,
    required String destination,
    required double fare,
    required String paymentId,
  }) async {
    final ticketRef = _db.collection('tickets').doc();
    final ticket = SmartTicket(
      ticketId: ticketRef.id,
      passengerId: passengerId,
      passengerName: passengerName,
      vehicleId: vehicleId,
      driverId: driverId,
      vehicleType: vehicleType,
      origin: origin,
      destination: destination,
      fare: fare,
      paymentId: paymentId,
      status: TicketStatus.active,
      qrData: 'TICKET|${ticketRef.id}|$passengerId|$fare',
      createdAt: DateTime.now(),
    );

    await ticketRef.set(ticket.toMap());
    return ticket;
  }

  // --- CITY REVENUE AGGREGATION ---

  Stream<Map<String, dynamic>> getRevenueSummary() {
    return _db.collection('payments')
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .snapshots()
        .map((snap) {
          double today = 0;
          double total = 0;
          final now = DateTime.now();

          for (var doc in snap.docs) {
            double amt = (doc.get('amount') as num).toDouble();
            total += amt;
            DateTime ts = (doc.get('timestamp') as Timestamp).toDate();
            if (ts.year == now.year && ts.month == now.month && ts.day == now.day) {
              today += amt;
            }
          }

          return {
            'revenueToday': today,
            'totalRevenue': total,
            'transactionCount': snap.docs.length,
          };
        });
  }
}
