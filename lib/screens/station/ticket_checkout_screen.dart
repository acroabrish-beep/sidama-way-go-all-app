import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ticket_detail_screen.dart';
import 'station_ui.dart';

class TicketCheckoutScreen extends StatefulWidget {
  const TicketCheckoutScreen({
    super.key,
    required this.station,
    required this.destination,
    required this.tariff,
  });

  final Station station;
  final StationDestination destination;
  final TariffInfo tariff;

  @override
  State<TicketCheckoutScreen> createState() => _TicketCheckoutScreenState();
}

class _TicketCheckoutScreenState extends State<TicketCheckoutScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _purchasing = false;
  String? _error;
  bool _paymentsNotConfigured = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  String _newIdempotencyKey() {
    final random = Random.secure().nextInt(1 << 32);
    return 'app-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  Future<void> _purchase() async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
      _paymentsNotConfigured = false;
    });
    try {
      final purchase = await _api.purchaseTicket(
        routeId: widget.destination.routeId,
        vehicleType: widget.tariff.vehicleType,
        idempotencyKey: _newIdempotencyKey(),
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StationTicketDetailScreen(ticketId: purchase.ticket.id),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _paymentsNotConfigured = error.message == 'Payments not configured';
        _purchasing = false;
      });
    } catch (error) {
      AppLogger.error('Ticket purchase failed', error: error);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to start the ticket purchase.';
        _purchasing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariff = widget.tariff;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Review ticket'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildJourneyCard(),
          StationSectionCard(
            title: 'Fare and tariff',
            icon: Icons.gavel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total fare',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    Text(
                      'ETB ${tariff.fareEtb.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                StationInfoRow(label: 'Tariff status', value: tariff.label),
                if (tariff.sourceReference != null)
                  StationInfoRow(
                    label: 'Source reference',
                    value: tariff.sourceReference!,
                  ),
                if (tariff.approvedBy != null)
                  StationInfoRow(
                    label: 'Approved by',
                    value: tariff.approvedBy!,
                  ),
                StationInfoRow(
                  label: 'Effective from',
                  value: _dateFormat.format(tariff.effectiveFrom),
                ),
                if (tariff.effectiveTo != null)
                  StationInfoRow(
                    label: 'Effective to',
                    value: _dateFormat.format(tariff.effectiveTo!),
                  ),
              ],
            ),
          ),
          StationSectionCard(
            title: 'How payment works',
            icon: Icons.payments,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The server re-reads the active tariff and copies the fare into your ticket. The app cannot change the amount.',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'A ticket is marked paid only after the payment provider confirms the payment. The ticket stays valid for 15 minutes while payment is pending.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            _buildErrorCard(),
          ],
          if (!tariff.isOfficial)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Purchase is blocked because this tariff is not fully approved.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _purchasing || !tariff.isOfficial ? null : _purchase,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _purchasing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Pay ETB ${tariff.fareEtb.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildJourneyCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Journey',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: Colors.grey.shade300,
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.destination.station.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.tariff.vehicleType.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${widget.destination.queueCounts[widget.tariff.vehicleType] ?? 0} waiting',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error!,
            style: TextStyle(
              color: Colors.red.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_paymentsNotConfigured) ...[
            const SizedBox(height: 6),
            const Text(
              'No payment provider is configured on the server. A real payment adapter and credentials are required before tickets can be sold.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
