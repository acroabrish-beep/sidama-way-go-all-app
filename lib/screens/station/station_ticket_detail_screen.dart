import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import '../../services/station_receipt_service.dart';
import 'station_ui.dart';

class StationTicketDetailScreen extends StatefulWidget {
  const StationTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<StationTicketDetailScreen> createState() =>
      _StationTicketDetailScreenState();
}

class _StationTicketDetailScreenState extends State<StationTicketDetailScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  final StationReceiptService _receiptService = StationReceiptService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  TicketDetail? _detail;
  String? _loadError;
  String? _paymentError;
  bool _loading = true;
  bool _polling = false;
  bool _sharingReceipt = false;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _expiryRefreshRequested = false;

  @override
  void initState() {
    super.initState();
    _load(showLoading: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = false}) async {
    if (_polling) return;
    _polling = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final detail = await _api.getTicket(widget.ticketId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loadError = null;
        _loading = false;
      });
      _syncTimers();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Ticket detail load failed', error: error);
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load this ticket.';
        _loading = false;
      });
    } finally {
      _polling = false;
    }
  }

  void _syncTimers() {
    final status = _detail?.ticket.status;
    if (status == 'pending_payment') {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
        _load();
      });
      _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        final detail = _detail;
        if (detail != null &&
            detail.ticket.expiresAt.isBefore(DateTime.now()) &&
            !_expiryRefreshRequested) {
          _expiryRefreshRequested = true;
          _load();
        }
      });
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  Future<void> _openCheckout(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _paymentError = 'Could not open the payment page.');
      }
    } catch (error) {
      AppLogger.error('Could not open checkout URL', error: error);
      if (!mounted) return;
      setState(() => _paymentError = 'Could not open the payment page.');
    }
  }

  Future<void> _shareReceipt() async {
    final detail = _detail;
    if (detail == null || _sharingReceipt) return;
    setState(() => _sharingReceipt = true);
    try {
      await _receiptService.shareReceipt(detail);
    } catch (error) {
      AppLogger.error('Receipt generation failed', error: error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate the receipt: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Station ticket'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(showLoading: _detail == null),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final detail = _detail;
    if (detail == null) {
      return StationErrorView(
        message: _loadError ?? 'Ticket not available.',
        onRetry: () => _load(showLoading: true),
      );
    }

    final ticket = detail.ticket;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(detail),
          if (_loadError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Latest refresh failed: $_loadError',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
              ),
            ),
          if (ticket.status == 'pending_payment') _buildPendingPayment(detail),
          if (ticket.status == 'paid' || ticket.status == 'used')
            _buildQrCard(detail),
          _buildTicketCard(detail),
          _buildTariffCard(detail),
          _buildPaymentCard(detail),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _sharingReceipt ? null : _shareReceipt,
            icon: _sharingReceipt
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Download / share receipt'),
          ),
          const SizedBox(height: 8),
          const Text(
            'The receipt is generated from the stored ticket and payment records. '
            'For unpaid tickets it is clearly marked as not a payment receipt.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(TicketDetail detail) {
    final ticket = detail.ticket;
    final isPending = ticket.status == 'pending_payment';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.confirmation_number,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ticket.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              StationStatusChip(status: ticket.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            detail.route?.label ?? 'Route details unavailable',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${ticket.vehicleType.label} · ETB ${ticket.fareEtb.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if ((detail.payment ?? ticket.payment)?.provider == 'dev') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEV PAYMENT — no real money was charged',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Text(
              'Payment expires in ${_remainingLabel(ticket.expiresAt)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrCard(TicketDetail detail) {
    if (detail.qrToken == null) {
      return StationSectionCard(
        title: 'Boarding QR',
        icon: Icons.qr_code,
        child: Text(
          detail.qrError ??
              'The QR code is not available yet. Refresh the ticket.',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }
    return StationSectionCard(
      title: 'Boarding QR',
      icon: Icons.qr_code,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: QrImageView(
              data: detail.qrToken!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Show this QR to the driver or assistant at boarding. The driver verifies it against the server.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPayment(TicketDetail detail) {
    final payment = detail.payment;
    final isDev = payment?.provider == 'dev';
    return StationSectionCard(
      title: isDev ? 'DEV PAYMENT' : 'Payment',
      icon: Icons.payments,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDev)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: const Text(
                'DEV PAYMENT — no real money is charged. This ticket exists only in the development environment.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          StationInfoRow(
            label: 'Provider',
            value: payment?.provider ?? 'Unknown until payment starts',
          ),
          if (payment?.providerRef != null)
            StationInfoRow(
              label: 'Payment reference',
              value: payment!.providerRef!,
            ),
          if (payment?.amountEtb != null)
            StationInfoRow(
              label: 'Amount',
              value: 'ETB ${payment!.amountEtb!.toStringAsFixed(2)}',
            ),
          if (payment?.status != null)
            StationInfoRow(label: 'Payment status', value: payment!.status!),
          const SizedBox(height: 10),
          const Text(
            'The ticket becomes valid only after the server receives a verified payment confirmation.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (_paymentError != null) ...[
            const SizedBox(height: 8),
            Text(
              _paymentError!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          if (isDev)
            const StationPhase5Notice(
              title: 'Dev payment completion is paused',
              message:
                  'The legacy Next.js completion endpoint has been removed. '
                  'Phase 5 will move staging completion into a server-side '
                  'Supabase function; production payments continue through '
                  'the provider webhook.',
            ),
          if (payment?.checkoutUrl != null) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _openCheckout(payment!.checkoutUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open payment page'),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Check payment status'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketDetail detail) {
    final ticket = detail.ticket;
    return StationSectionCard(
      title: 'Ticket details',
      icon: Icons.info_outline,
      child: Column(
        children: [
          StationInfoRow(label: 'Code', value: ticket.code),
          StationInfoRow(
            label: 'Vehicle type',
            value: ticket.vehicleType.label,
          ),
          StationInfoRow(
            label: 'Fare',
            value: 'ETB ${ticket.fareEtb.toStringAsFixed(2)}',
          ),
          StationInfoRow(
            label: 'Issued',
            value: _dateFormat.format(ticket.issuedAt),
          ),
          StationInfoRow(
            label: 'Valid until',
            value: _dateFormat.format(ticket.expiresAt),
          ),
          if (ticket.usedAt != null)
            StationInfoRow(
              label: 'Boarded',
              value: _dateFormat.format(ticket.usedAt!),
            ),
          if (ticket.verifiedVehicleId != null)
            StationInfoRow(
              label: 'Verified vehicle',
              value: ticket.verifiedVehicleId!,
            ),
        ],
      ),
    );
  }

  Widget _buildTariffCard(TicketDetail detail) {
    final tariff = detail.tariff;
    return StationSectionCard(
      title: 'Tariff record',
      icon: Icons.gavel,
      child: tariff == null
          ? const Text(
              'The tariff record for this ticket is unavailable.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            )
          : Column(
              children: [
                StationInfoRow(label: 'Status', value: tariff.label),
                StationInfoRow(
                  label: 'Fare',
                  value: 'ETB ${tariff.fareEtb.toStringAsFixed(2)}',
                ),
                StationInfoRow(
                  label: 'Source reference',
                  value: tariff.sourceReference ?? 'Not recorded',
                ),
                StationInfoRow(
                  label: 'Approved by',
                  value: tariff.approvedBy ?? 'Not recorded',
                ),
                StationInfoRow(
                  label: 'Effective from',
                  value: DateFormat('yyyy-MM-dd').format(tariff.effectiveFrom),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentCard(TicketDetail detail) {
    final payment = detail.payment ?? detail.ticket.payment;
    if (payment == null) return const SizedBox.shrink();
    final isDev = payment.provider == 'dev';
    return StationSectionCard(
      title: 'Payment record',
      icon: Icons.receipt,
      child: Column(
        children: [
          if (isDev)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: const Text(
                'DEV PAYMENT — no real money was charged for this ticket.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          StationInfoRow(
            label: 'Provider',
            value: isDev ? 'dev — DEV PAYMENT' : payment.provider,
          ),
          if (payment.providerRef != null)
            StationInfoRow(label: 'Reference', value: payment.providerRef!),
          if (payment.amountEtb != null)
            StationInfoRow(
              label: 'Amount',
              value: 'ETB ${payment.amountEtb!.toStringAsFixed(2)}',
            ),
          if (payment.status != null)
            StationInfoRow(label: 'Status', value: payment.status!),
          if (payment.verifiedAt != null)
            StationInfoRow(
              label: 'Verified',
              value: _dateFormat.format(payment.verifiedAt!),
            ),
        ],
      ),
    );
  }

  String _remainingLabel(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return '0:00';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
