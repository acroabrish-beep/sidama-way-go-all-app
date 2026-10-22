import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/mobility_models.dart';
import '../../models/city_os_models.dart';
import 'package:intl/intl.dart';

class TicketViewScreen extends StatelessWidget {
  final Ticket ticket;
  const TicketViewScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ticket'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: QrImageView(
                  data: ticket.qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 32),
              _infoRow('Passenger', ticket.passengerName),
              _infoRow('Route', ticket.route),
              _infoRow('Seat', ticket.seatNumber.toString()),
              _infoRow('Date', DateFormat('MMM dd, yyyy').format(ticket.date)),
              _infoRow('Status', ticket.paymentStatus, color: Colors.green),
              const SizedBox(height: 48),
              const Text(
                'Show this QR code at the terminal for scanning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontWeight: color != null ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}
