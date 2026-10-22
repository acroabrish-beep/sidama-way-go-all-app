import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/station_ticket_models.dart';
import 'station_ui.dart';

class VerificationResultCard extends StatelessWidget {
  const VerificationResultCard({super.key, required this.outcome});

  final VerificationOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (title, message, color, icon) = switch (outcome.result) {
      VerificationResult.valid => (
          'Valid ticket — boarding recorded',
          'This ticket is now marked as used. The passenger may board.',
          const Color(0xFF2E7D32),
          Icons.check_circle,
        ),
      VerificationResult.alreadyUsed => (
          'Already used',
          'This ticket was already verified. Do not board the passenger again.',
          Colors.orange.shade800,
          Icons.warning_amber_rounded,
        ),
      VerificationResult.expired => (
          'Expired ticket',
          'This ticket is past its validity time. Do not board the passenger.',
          Colors.red.shade800,
          Icons.timer_off,
        ),
      VerificationResult.invalid => (
          'Invalid ticket',
          'The code or QR does not match a valid station ticket. Do not board the passenger.',
          Colors.red.shade800,
          Icons.cancel,
        ),
    };

    final ticket = outcome.ticket;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13)),
          if (outcome.routeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                outcome.routeError!,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          if (ticket != null) ...[
            const Divider(height: 20),
            StationInfoRow(label: 'Code', value: ticket.code),
            if (outcome.route != null)
              StationInfoRow(label: 'Route', value: outcome.route!.label),
            StationInfoRow(
              label: 'Vehicle type',
              value: ticket.vehicleType.label,
            ),
            StationInfoRow(
              label: 'Fare',
              value: 'ETB ${ticket.fareEtb.toStringAsFixed(2)}',
            ),
            if (ticket.usedAt != null)
              StationInfoRow(
                label: 'Used at',
                value: dateFormat.format(ticket.usedAt!),
              ),
            if (ticket.verifiedVehicleId != null)
              StationInfoRow(
                label: 'Verified vehicle',
                value: ticket.verifiedVehicleId!,
              ),
          ],
        ],
      ),
    );
  }
}
