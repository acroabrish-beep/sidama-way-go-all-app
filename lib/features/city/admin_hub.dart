import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CityAdminHub extends StatelessWidget {
  const CityAdminHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart City Administration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const _CityOverviewStats(),
            const SizedBox(height: 24),
            _buildChartCard('Revenue Analytics'),
            const SizedBox(height: 24),
            _AdminActionsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 10, color: Colors.green)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 14, color: Colors.green)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.green)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: Colors.green)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityOverviewStats extends StatelessWidget {
  const _CityOverviewStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StatBox('Vehicles', '1,240', Colors.blue),
        SizedBox(width: 12),
        _StatBox('Passengers', '8,402', Colors.green),
        SizedBox(width: 12),
        _StatBox('Emergency', '4', Colors.red),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatBox(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AdminActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'label': 'Manage Drivers', 'icon': Icons.people},
      {'label': 'Tourism Places', 'icon': Icons.map},
      {'label': 'Announcements', 'icon': Icons.campaign},
      {'label': 'Emergency Requests', 'icon': Icons.emergency},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5, crossAxisSpacing: 16, mainAxisSpacing: 16),
      itemCount: actions.length,
      itemBuilder: (context, i) => Card(
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(actions[i]['icon'] as IconData, color: Colors.indigo),
              const SizedBox(height: 8),
              Text(actions[i]['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
