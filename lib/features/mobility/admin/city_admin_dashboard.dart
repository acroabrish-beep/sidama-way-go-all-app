import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/mobility_service.dart';

class CityAdminDashboard extends StatelessWidget {
  const CityAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MobilityService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('City Transport Analytics'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: service.getCityStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Active Taxis', stats['active_taxis']?.toString() ?? '156', Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Buses Running', stats['active_buses']?.toString() ?? '24', Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Total Revenue', '${stats['daily_revenue'] ?? '42.5k'} ETB', Colors.orange),
                    const SizedBox(width: 12),
                    _buildStatCard('Alerts', stats['alerts']?.toString() ?? '0', Colors.red),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Trip Volume (Last 24h)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.indigo,
                          barWidth: 4,
                          spots: [
                            const FlSpot(0, 3),
                            const FlSpot(1, 1),
                            const FlSpot(2, 5),
                            const FlSpot(3, 2),
                            const FlSpot(4, 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Terminal Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.business),
                  title: const Text('Hawassa Old Terminal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.business),
                  title: const Text('Hawassa New Terminal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
