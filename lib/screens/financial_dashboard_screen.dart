import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/financial_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_insights_card.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final FinancialService _finService = FinancialService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('City Financial Command', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _finService.getRevenueSummary(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'revenueToday': 0.0, 'totalRevenue': 0.0, 'transactionCount': 0};

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const AIInsightsCard(dashboardContext: 'finance', title: '💰 AI Financial Analysis'),
              const SizedBox(height: 20),
              _buildRevenueCards(data),
              const SizedBox(height: 30),
              _buildRevenueChart(),
              const SizedBox(height: 30),
              _buildProviderStats(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueCards(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _statCard('Revenue Today', '${data['revenueToday']} ETB', Icons.today, Colors.green),
        _statCard('Total Revenue', '${data['totalRevenue']} ETB', Icons.account_balance_wallet, Colors.blue),
        _statCard('Transactions', '${data['transactionCount']}', Icons.receipt_long, Colors.orange),
        _statCard('Active Wallets', '1,240', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return SizedBox(
      height: 220,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Revenue Flow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: Colors.blueAccent)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: Colors.blueAccent)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 18, color: Colors.blueAccent)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 14, color: Colors.blueAccent)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 22, color: Colors.blueAccent)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Providers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _providerTile('Telebirr', 0.65, Colors.blue),
        _providerTile('CBE Birr', 0.20, Colors.purple),
        _providerTile('Cash', 0.15, Colors.green),
      ],
    );
  }

  Widget _providerTile(String name, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            const Spacer(),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white10, color: color),
            ),
            const SizedBox(width: 12),
            Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
