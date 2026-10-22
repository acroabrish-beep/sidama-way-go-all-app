import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';
import 'taxi_models.dart';

enum PaymentMethod { telebirr, cbeBirr, bankTransfer, chapa, santimPay, visa, mastercard, cash, wallet, governmentAccount }

enum PaymentStatus { pending, processing, completed, failed, refunded, partiallyRefunded }

enum WalletTransactionType { topUp, withdrawal, payment, refund, reward, subsidy, bonus, penalty, commission }

enum TicketStatus { active, verified, used, expired, cancelled }

class FareRule {
  final String ruleId;
  final VehicleType vehicleType;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final double surgeMultiplier;
  final Map<String, double> categoryDiscounts; // e.g. {'student': 0.2, 'elderly': 0.3}
  final bool isNightService;
  final bool isHoliday;

  FareRule({
    required this.ruleId,
    required this.vehicleType,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    this.surgeMultiplier = 1.0,
    this.categoryDiscounts = const {},
    this.isNightService = false,
    this.isHoliday = false,
  });

  factory FareRule.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FareRule(
      ruleId: doc.id,
      vehicleType: VehicleType.values.firstWhere((e) => e.name == data['vehicleType'], orElse: () => VehicleType.taxi),
      baseFare: (data['baseFare'] ?? 0.0).toDouble(),
      perKmRate: (data['perKmRate'] ?? 0.0).toDouble(),
      perMinuteRate: (data['perMinuteRate'] ?? 0.0).toDouble(),
      surgeMultiplier: (data['surgeMultiplier'] ?? 1.0).toDouble(),
      categoryDiscounts: Map<String, double>.from(data['categoryDiscounts'] ?? {}),
      isNightService: data['isNightService'] ?? false,
      isHoliday: data['isHoliday'] ?? false,
    );
  }
}

class Wallet {
  final String ownerId;
  final String ownerRole; // citizen, driver, operator, government
  final double balance;
  final double transportCredits;
  final double promoBalance;
  final double subsidyBalance;
  final String currency;
  final DateTime updatedAt;

  Wallet({
    required this.ownerId,
    required this.ownerRole,
    this.balance = 0.0,
    this.transportCredits = 0.0,
    this.promoBalance = 0.0,
    this.subsidyBalance = 0.0,
    this.currency = 'ETB',
    required this.updatedAt,
  });

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Wallet(
      ownerId: doc.id,
      ownerRole: data['ownerRole'] ?? 'citizen',
      balance: (data['balance'] ?? 0.0).toDouble(),
      transportCredits: (data['transportCredits'] ?? 0.0).toDouble(),
      promoBalance: (data['promoBalance'] ?? 0.0).toDouble(),
      subsidyBalance: (data['subsidyBalance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'ETB',
      updatedAt: FirestoreUtils.parseDateTimeOrDefault(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerRole': ownerRole,
      'balance': balance,
      'transportCredits': transportCredits,
      'promoBalance': promoBalance,
      'subsidyBalance': subsidyBalance,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WalletTransaction {
  final String transactionId;
  final String walletId;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final String referenceId; // Payment ID or Trip ID
  final DateTime timestamp;

  WalletTransaction({
    required this.transactionId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    required this.referenceId,
    required this.timestamp,
  });

  factory WalletTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WalletTransaction(
      transactionId: doc.id,
      walletId: data['walletId'] ?? '',
      type: WalletTransactionType.values.firstWhere((e) => e.name == data['type'], orElse: () => WalletTransactionType.payment),
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      referenceId: data['referenceId'] ?? '',
      timestamp: FirestoreUtils.parseDateTimeOrDefault(data['timestamp']),
    );
  }
}

class SmartTicket {
  final String ticketId;
  final String passengerId;
  final String passengerName;
  final String vehicleId;
  final String driverId;
  final VehicleType vehicleType;
  final String origin;
  final String destination;
  final double fare;
  final String paymentId;
  final TicketStatus status;
  final String qrData;
  final DateTime createdAt;

  SmartTicket({
    required this.ticketId,
    required this.passengerId,
    required this.passengerName,
    required this.vehicleId,
    required this.driverId,
    required this.vehicleType,
    required this.origin,
    required this.destination,
    required this.fare,
    required this.paymentId,
    required this.status,
    required this.qrData,
    required this.createdAt,
  });

  factory SmartTicket.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SmartTicket(
      ticketId: doc.id,
      passengerId: data['passengerId'] ?? '',
      passengerName: data['passengerName'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      driverId: data['driverId'] ?? '',
      vehicleType: VehicleType.values.firstWhere((e) => e.name == data['vehicleType'], orElse: () => VehicleType.taxi),
      origin: data['origin'] ?? '',
      destination: data['destination'] ?? '',
      fare: (data['fare'] ?? 0.0).toDouble(),
      paymentId: data['paymentId'] ?? '',
      status: TicketStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => TicketStatus.active),
      qrData: data['qrData'] ?? '',
      createdAt: FirestoreUtils.parseDateTimeOrDefault(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'vehicleType': vehicleType.name,
      'origin': origin,
      'destination': destination,
      'fare': fare,
      'paymentId': paymentId,
      'status': status.name,
      'qrData': qrData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class FinancialPayment {
  final String paymentId;
  final String userId;
  final String recipientId;
  final double amount;
  final double taxAmount;
  final double commissionAmount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String referenceType; // trip, ticket, topup
  final String referenceId;
  final DateTime timestamp;

  FinancialPayment({
    required this.paymentId,
    required this.userId,
    required this.recipientId,
    required this.amount,
    this.taxAmount = 0.0,
    this.commissionAmount = 0.0,
    required this.method,
    required this.status,
    required this.referenceType,
    required this.referenceId,
    required this.timestamp,
  });

  factory FinancialPayment.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FinancialPayment(
      paymentId: doc.id,
      userId: data['userId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0.0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0.0).toDouble(),
      method: PaymentMethod.values.firstWhere((e) => e.name == data['method'], orElse: () => PaymentMethod.cash),
      status: PaymentStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => PaymentStatus.pending),
      referenceType: data['referenceType'] ?? '',
      referenceId: data['referenceId'] ?? '',
      timestamp: FirestoreUtils.parseDateTimeOrDefault(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'recipientId': recipientId,
      'amount': amount,
      'taxAmount': taxAmount,
      'commissionAmount': commissionAmount,
      'method': method.name,
      'status': status.name,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
