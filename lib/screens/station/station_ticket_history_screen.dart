import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ticket_detail_screen.dart';
import 'station_ui.dart';

class StationTicketHistoryScreen extends StatefulWidget {
  const StationTicketHistoryScreen({super.key});

  @override
  State<StationTicketHistoryScreen> createState() =>
      _StationTicketHistoryScreenState();
}

class _StationTicketHistoryScreenState
    extends State<StationTicketHistoryScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  List<StationTicket>? _tickets;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tickets = await _api.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Ticket history load failed', error: error);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your tickets.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My tickets'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StationErrorView(message: _error!, onRetry: _load);
    }
    final tickets = _tickets ?? const <StationTicket>[];
    if (tickets.isEmpty) {
      return const StationEmptyView(
        icon: Icons.receipt_long,
        title: 'No tickets yet',
        message:
            'Tickets you buy from a station will appear here with their QR code and receipt.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
      ),
    );
  }

  Widget _buildTicketCard(StationTicket ticket) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StationTicketDetailScreen(ticketId: ticket.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.route?.label ?? 'Route details unavailable',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StationStatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    ticket.code,
                    style: const TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ETB ${ticket.fareEtb.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${ticket.vehicleType.label} · ${_dateFormat.format(ticket.issuedAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (ticket.status == 'pending_payment')
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Payment is not complete. Open the ticket to continue.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
