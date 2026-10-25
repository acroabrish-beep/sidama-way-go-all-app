import 'package:flutter/material.dart';

import '../../widgets/ai_insights_card.dart';
import 'admin_station_catalog_screen.dart';
import 'driver_station_screen.dart';
import 'station_ui.dart';

class StationMetricsOverview extends StatelessWidget {
  const StationMetricsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AIInsightsCard(
            dashboardContext: 'taxi_services',
            title: '🤖 Taxi Services AI Insights',
          ),
          const SizedBox(height: 12),
          _buildOperationsCard(context),
          const SizedBox(height: 12),
          const StationPhase5Notice(
            title: 'Station metrics are scheduled for Phase 5',
            message:
                'Ticket, revenue, hourly and reconciliation metrics used the '
                'legacy Next.js /api/admin/taxi/metrics endpoint. That call has '
                'been removed. The metrics RPC will be added with the other '
                'Phase 5 station functions; no demo figures are shown here.',
          ),
          StationSectionCard(
            title: 'What still works',
            icon: Icons.check_circle_outline,
            child: Text(
              'The station catalog, routes and tariff history read directly '
              'from Supabase. Passenger ticket purchase and ticket '
              'verification continue through Supabase Edge Functions.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsCard(BuildContext context) {
    return StationSectionCard(
      title: 'Station operations',
      icon: Icons.confirmation_number,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Open the live catalog or the driver station.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStationCatalogScreen(),
                  ),
                ),
                icon: const Icon(Icons.table_chart, size: 18),
                label: const Text('Stations, tariffs & import'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverStationScreen(),
                  ),
                ),
                icon: const Icon(Icons.local_taxi, size: 18),
                label: const Text('Driver station'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
