import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/intelligence_models.dart';
import '../services/transport_intelligence_service.dart';
import '../widgets/glass_card.dart';

class ExecutiveIntelligenceDashboard extends StatefulWidget {
  const ExecutiveIntelligenceDashboard({super.key});

  @override
  State<ExecutiveIntelligenceDashboard> createState() => _ExecutiveIntelligenceDashboardState();
}

class _ExecutiveIntelligenceDashboardState extends State<ExecutiveIntelligenceDashboard> {
  final TransportIntelligenceService _intelService = TransportIntelligenceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('City Operational Intelligence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            onPressed: () => _intelService.updateCityIntelligence(),
            tooltip: 'Run Intelligence Engine',
          ),
        ],
      ),
      body: StreamBuilder<CityKPI>(
        stream: _intelService.getCityKPIs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final kpi = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle('Executive City Health'),
              _buildKPIGrid(kpi),
              const SizedBox(height: 30),
              _buildSectionTitle('Fleet & Revenue Trends'),
              _buildTrendCharts(),
              const SizedBox(height: 30),
              _buildSectionTitle('Active Operational Alerts'),
              _buildAlertList(),
              const SizedBox(height: 30),
              _buildSectionTitle('Smart Recommendations'),
              _buildRecommendationList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildKPIGrid(CityKPI kpi) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _kpiCard('City Health', '${kpi.cityHealthScore.toInt()}%', Icons.health_and_safety, Colors.green),
        _kpiCard('Fleet Readiness', '${kpi.fleetHealthScore.toInt()}%', Icons.commute, Colors.blue),
        _kpiCard('Station Flow', '${kpi.stationHealthScore.toInt()}%', Icons.hub, Colors.orange),
        _kpiCard('Daily Revenue', '${kpi.totalRevenue.toInt()} ETB', Icons.payments, Colors.purple),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTrendCharts() {
    return SizedBox(
      height: 200,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [const FlSpot(0, 3), const FlSpot(2, 5), const FlSpot(4, 4), const FlSpot(6, 8), const FlSpot(8, 6)],
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertList() {
    return StreamBuilder<List<OperationalAlert>>(
      stream: _intelService.getActiveAlerts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const GlassCard(child: Center(child: Text('No Active Alerts', style: TextStyle(color: Colors.white54))));
        }
        return Column(
          children: snapshot.data!.map((a) => _alertItem(a)).toList(),
        );
      },
    );
  }

  Widget _alertItem(OperationalAlert alert) {
    Color severityColor = alert.severity == AlertSeverity.critical ? Colors.red : Colors.orange;
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: severityColor),
        title: Text(alert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(alert.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }

  Widget _buildRecommendationList() {
    return StreamBuilder<List<SmartRecommendation>>(
      stream: _intelService.getTopRecommendations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const GlassCard(child: Center(child: Text('Engine processing data...', style: TextStyle(color: Colors.white54))));
        }
        return Column(
          children: snapshot.data!.map((r) => _recItem(r)).toList(),
        );
      },
    );
  }

  Widget _recItem(SmartRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.blueAccent.withValues(alpha: 0.1), Colors.transparent]),
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 15, child: Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
        title: Text(rec.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(rec.action, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Text('Impact: ${rec.impactScore.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ),
    );
  }
}
