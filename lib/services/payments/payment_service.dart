import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/logger.dart';
import '../api/data_api_service.dart';
import '../offline/offline_service.dart';

enum PaymentProvider {
  telebirr,
  cbeBirr,
  chapa,
  santimPay,
  cash,
  wallet,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

class PaymentRequest {
  final String id;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final String description;
  final Map<String, dynamic>? metadata;
  final String userId;
  final DateTime createdAt;

  PaymentRequest({
    required this.id,
    required this.amount,
    this.currency = 'ETB',
    required this.provider,
    required this.description,
    this.metadata,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'provider': provider.toString().split('.').last,
      'description': description,
      'metadata': metadata,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PaymentResponse {
  final String paymentId;
  final PaymentStatus status;
  final String? transactionId;
  final String? referenceId;
  final String? errorMessage;
  final Map<String, dynamic>? providerResponse;
  final DateTime processedAt;

  PaymentResponse({
    required this.paymentId,
    required this.status,
    this.transactionId,
    this.referenceId,
    this.errorMessage,
    this.providerResponse,
    required this.processedAt,
  });

  factory PaymentResponse.fromMap(Map<String, dynamic> map) {
    return PaymentResponse(
      paymentId: map['payment_id'],
      status: _parsePaymentStatus(map['status']),
      transactionId: map['transaction_id'],
      referenceId: map['reference_id'],
      errorMessage: map['error_message'],
      providerResponse: map['provider_response'],
      processedAt: DateTime.parse(map['processed_at']),
    );
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'status': status.toString().split('.').last,
      'transaction_id': transactionId,
      'reference_id': referenceId,
      'error_message': errorMessage,
      'provider_response': providerResponse,
      'processed_at': processedAt.toIso8601String(),
    };
  }
}

class QRReceipt {
  final String id;
  final String paymentId;
  final String qrData;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final bool isUsed;
  final DateTime? usedAt;

  QRReceipt({
    required this.id,
    required this.paymentId,
    required this.qrData,
    required this.generatedAt,
    this.expiresAt,
    this.isUsed = false,
    this.usedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'qr_data': qrData,
      'generated_at': generatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_used': isUsed,
      'used_at': usedAt?.toIso8601String(),
    };
  }
}

class PaymentService {
  static PaymentService? _instance;
  final DataApiService _dataApiService = DataApiService();
  final OfflineService _offlineService = OfflineService.instance;

  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  PaymentService._() {
    _initializeProviders();
  }

  void _initializeProviders() {
    // Initialize payment provider clients
    // In production, this would initialize SDKs for each provider
    AppLogger.info('Payment providers initialized');
  }

  // Payment processing

  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      AppLogger.info('Processing payment: ${request.id} via ${request.provider}');

      // Save payment to database
      await _dataApiService.createPayment({
        'user_id': request.userId,
        'amount': request.amount,
        'currency': request.currency,
        'method': request.provider.toString().split('.').last,
        'status': 'processing',
        'description': request.description,
        'metadata': request.metadata,
      });

      // Process based on provider
      PaymentResponse response;

      switch (request.provider) {
        case PaymentProvider.telebirr:
          response = await _processTelebirrPayment(request);
          break;
        case PaymentProvider.cbeBirr:
          response = await _processCBEPayment(request);
          break;
        case PaymentProvider.chapa:
          response = await _processChapaPayment(request);
          break;
        case PaymentProvider.santimPay:
          response = await _processSantimPayPayment(request);
          break;
        case PaymentProvider.cash:
          response = await _processCashPayment(request);
          break;
        case PaymentProvider.wallet:
          response = await _processWalletPayment(request);
          break;
      }

      // Update payment status in database
      await _dataApiService.updatePayment(
        request.id,
        {
          'status': response.status.toString().split('.').last,
          'transaction_id': response.transactionId,
          'reference_id': response.referenceId,
        },
      );

      // Generate QR receipt if successful
      if (response.status == PaymentStatus.completed) {
        await _generateQRReceipt(request.id, response);
      }

      return response;
    } catch (e) {
      AppLogger.error('Payment processing failed', error: e);
      return PaymentResponse(
        paymentId: request.id,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  Future<PaymentResponse> _processTelebirrPayment(PaymentRequest request) async {
    // Simulate Telebirr payment processing
    await Future.delayed(const Duration(seconds: 2));

    final transactionId = 'TELE_${DateTime.now().millisecondsSinceEpoch}';
    final referenceId = _generateReferenceId();

    return PaymentResponse(
      paymentId: request.id,
      status: PaymentStatus.completed,
      transactionId: transactionId,
      referenceId: referenceId,
      providerResponse: {
        'provider': 'telebirr',
        'transaction_id': transactionId,
      },
      processedAt: DateTime.now(),
    );
  }

  Future<PaymentResponse> _processCBEPayment(PaymentRequest request) async {
    // Simulate CBE Birr payment processing
    await Future.delayed(const Duration(seconds: 3));

    final transactionId = 'CBE_${DateTime.now().millisecondsSinceEpoch}';
    final referenceId = _generateReferenceId();

    return PaymentResponse(
      paymentId: request.id,
      status: PaymentStatus.completed,
      transactionId: transactionId,
      referenceId: referenceId,
      providerResponse: {
        'provider': 'cbe_birr',
        'transaction_id': transactionId,
      },
      processedAt: DateTime.now(),
    );
  }

  Future<PaymentResponse> _processChapaPayment(PaymentRequest request) async {
    // Simulate Chapa payment processing
    await Future.delayed(const Duration(seconds: 2));

    final transactionId = 'CHAPA_${DateTime.now().millisecondsSinceEpoch}';
    final referenceId = _generateReferenceId();

    return PaymentResponse(
      paymentId: request.id,
      status: PaymentStatus.completed,
      transactionId: transactionId,
      referenceId: referenceId,
      providerResponse: {
        'provider': 'chapa',
        'transaction_id': transactionId,
      },
      processedAt: DateTime.now(),
    );
  }

  Future<PaymentResponse> _processSantimPayPayment(PaymentRequest request) async {
    // Simulate SantimPay payment processing
    await Future.delayed(const Duration(seconds: 2));

    final transactionId = 'SANTIM_${DateTime.now().millisecondsSinceEpoch}';
    final referenceId = _generateReferenceId();

    return PaymentResponse(
      paymentId: request.id,
      status: PaymentStatus.completed,
      transactionId: transactionId,
      referenceId: referenceId,
      providerResponse: {
        'provider': 'santimpay',
        'transaction_id': transactionId,
      },
      processedAt: DateTime.now(),
    );
  }

  Future<PaymentResponse> _processCashPayment(PaymentRequest request) async {
    // Cash payments require manual confirmation
    return PaymentResponse(
      paymentId: request.id,
      status: PaymentStatus.pending,
      errorMessage: 'Cash payment requires manual confirmation',
      processedAt: DateTime.now(),
    );
  }

  Future<PaymentResponse> _processWalletPayment(PaymentRequest request) async {
    try {
      // Check wallet balance
      final walletData = await _dataApiService.getWalletTransactions(request.userId);
      final currentBalance = _calculateWalletBalance(walletData['data'] as List);

      if (currentBalance < request.amount) {
        return PaymentResponse(
          paymentId: request.id,
          status: PaymentStatus.failed,
          errorMessage: 'Insufficient wallet balance',
          processedAt: DateTime.now(),
        );
      }

      // Deduct from wallet
      await _dataApiService.createWalletTransaction({
        'user_id': request.userId,
        'type': 'debit',
        'amount': request.amount,
        'balance_after': currentBalance - request.amount,
        'description': request.description,
        'reference_id': request.id,
      });

      final transactionId = 'WALLET_${DateTime.now().millisecondsSinceEpoch}';

      return PaymentResponse(
        paymentId: request.id,
        status: PaymentStatus.completed,
        transactionId: transactionId,
        providerResponse: {
          'provider': 'wallet',
          'transaction_id': transactionId,
          'previous_balance': currentBalance,
          'new_balance': currentBalance - request.amount,
        },
        processedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Wallet payment failed', error: e);
      return PaymentResponse(
        paymentId: request.id,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  // QR Receipt generation

  Future<QRReceipt> _generateQRReceipt(String paymentId, PaymentResponse response) async {
    final qrData = jsonEncode({
      'payment_id': paymentId,
      'transaction_id': response.transactionId,
      'reference_id': response.referenceId,
      'amount': response.providerResponse?['amount'],
      'timestamp': response.processedAt.toIso8601String(),
      'status': response.status.toString().split('.').last,
    });

    final receipt = QRReceipt(
      id: 'QR_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: paymentId,
      qrData: qrData,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );

    // Save receipt to offline storage for validation
    await _offlineService.saveOfflineTicket(receipt.id, receipt.toMap());

    AppLogger.info('QR receipt generated: ${receipt.id}');
    return receipt;
  }

  Widget generateQRWidget(String qrData) {
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
  }

  Future<String> generateQRImage(String qrData) async {
    // This would generate an actual QR code image
    // For now, return the data string
    return qrData;
  }

  // Refund processing

  Future<PaymentResponse> processRefund(String paymentId, String reason) async {
    try {
      AppLogger.info('Processing refund for payment: $paymentId');

      // Create refund request
      final refundId = 'REFUND_${DateTime.now().millisecondsSinceEpoch}';
      
      // Process refund based on original payment method
      final response = PaymentResponse(
        paymentId: paymentId,
        status: PaymentStatus.refunded,
        transactionId: refundId,
        referenceId: _generateReferenceId(),
        processedAt: DateTime.now(),
      );

      // Update payment status
      await _dataApiService.updatePayment(paymentId, {
        'status': 'refunded',
      });

      // Create refund transaction
      await _dataApiService.createPayment({
        'user_id': '', // Would get from original payment
        'amount': 0.0, // Would get from original payment
        'currency': 'ETB',
        'method': 'refund',
        'status': 'completed',
        'description': reason,
        'reference_id': refundId,
      });

      return response;
    } catch (e) {
      AppLogger.error('Refund processing failed', error: e);
      return PaymentResponse(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  // Commission and revenue

  Future<void> processCommission(String paymentId, double amount) async {
    try {
      // Calculate commission based on service type
      final commissionRate = await _getCommissionRate();
      final commissionAmount = amount * (commissionRate / 100);

      // Create commission transaction
      await _dataApiService.createWalletTransaction({
        'user_id': 'system', // System account for commissions
        'type': 'credit',
        'amount': commissionAmount,
        'balance_after': 0.0, // Would calculate
        'description': 'Commission from payment: $paymentId',
        'reference_id': paymentId,
      });

      AppLogger.info('Commission processed: $commissionAmount');
    } catch (e) {
      AppLogger.error('Commission processing failed', error: e);
    }
  }

  Future<double> _getCommissionRate() async {
    // Would fetch from system configuration
    return 15.0; // Default 15%
  }

  // Wallet management

  Future<double> getWalletBalance(String userId) async {
    try {
      final transactions = await _dataApiService.getWalletTransactions(userId);
      return _calculateWalletBalance(transactions['data'] as List);
    } catch (e) {
      AppLogger.error('Failed to get wallet balance', error: e);
      return 0.0;
    }
  }

  double _calculateWalletBalance(List transactions) {
    double balance = 0.0;
    for (final transaction in transactions) {
      if (transaction['type'] == 'credit') {
        balance += (transaction['amount'] as num).toDouble();
      } else if (transaction['type'] == 'debit') {
        balance -= (transaction['amount'] as num).toDouble();
      }
    }
    return balance;
  }

  Future<void> addFunds(String userId, double amount, String method) async {
    try {
      await _dataApiService.createWalletTransaction({
        'user_id': userId,
        'type': 'credit',
        'amount': amount,
        'balance_after': await getWalletBalance(userId) + amount,
        'description': 'Funds added via $method',
        'reference_id': _generateReferenceId(),
      });

      AppLogger.info('Funds added to wallet: $amount');
    } catch (e) {
      AppLogger.error('Failed to add funds', error: e);
    }
  }

  // Transaction history

  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId) async {
    try {
      final payments = await _dataApiService.getPayments(userId);
      final transactions = await _dataApiService.getWalletTransactions(userId);

      // Combine and sort by date
      final allTransactions = [
        ...payments['data'] as List,
        ...transactions['data'] as List,
      ];

      allTransactions.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      return allTransactions
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get transaction history', error: e);
      return [];
    }
  }

  // Utilities

  String _generateReferenceId() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> validateOfflineQR(String qrData) async {
    try {
      final data = jsonDecode(qrData);
      final paymentId = data['payment_id'];

      // Validate with offline service
      final ticket = await _offlineService.getOfflineTicket(paymentId);
      if (ticket != null) {
        await _offlineService.validateOfflineTicket(paymentId);
        AppLogger.info('Offline QR validated: $paymentId');
      }
    } catch (e) {
      AppLogger.error('Offline QR validation failed', error: e);
    }
  }
}