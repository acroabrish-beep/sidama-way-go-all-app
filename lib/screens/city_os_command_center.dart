import 'package:flutter/material.dart';
import '../services/city_os_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_insights_card.dart';
import 'smart_city_map_screen.dart';
import 'emergency_command_dashboard.dart';
import 'financial_dashboard_screen.dart';

class CityOSCommandCenter extends StatefulWidget {
  const CityOSCommandCenter({super.key});

  @override
  State<CityOSCommandCenter> createState() => _CityOSCommandCenterState();
}

class _CityOSCommandCenterState extends State<CityOSCommandCenter> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CityOSService _cityOS = CityOSService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HAWASSA CityOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            StreamBuilder<double>(
              stream: _cityOS.getSystemHealthScore(),
              builder: (context, snapshot) {
                final score = snapshot.data ?? 100.0;
                return Text('System Health: ${score.toInt()}%',
                  style: TextStyle(fontSize: 10, color: score > 80 ? Colors.greenAccent : Colors.redAccent));
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_input_component, color: Colors.white), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.hub), text: 'Digital Twin'),
            Tab(icon: Icon(Icons.emergency), text: 'Emergency'),
            Tab(icon: Icon(Icons.payments), text: 'Finance'),
            Tab(icon: Icon(Icons.insights), text: 'Intelligence'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // High performance navigation
        children: const [
          SmartCityMapScreen(),
          EmergencyCommandDashboard(),
          FinancialDashboardScreen(),
          _UnifiedStatsView(),
        ],
      ),
    );
  }
}

class _UnifiedStatsView extends StatelessWidget {
  const _UnifiedStatsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        AIInsightsCard(dashboardContext: 'city_os_master', title: '🧠 CityOS Executive Intelligence'),
        SizedBox(height: 20),
        Text('Real-time City Metrics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        // Additional aggregated KPI cards could go here
        GlassCard(
          child: Column(
            children: [
               ListTile(leading: Icon(Icons.commute, color: Colors.blue), title: Text('Fleet Utilization', style: TextStyle(color: Colors.white)), trailing: Text('78%', style: TextStyle(color: Colors.white))),
               ListTile(leading: Icon(Icons.timer, color: Colors.orange), title: Text('Avg Response Time', style: TextStyle(color: Colors.white)), trailing: Text('4.2m', style: TextStyle(color: Colors.white))),
               ListTile(leading: Icon(Icons.health_and_safety, color: Colors.green), title: Text('Hospital Capacity', style: TextStyle(color: Colors.white)), trailing: Text('142 beds', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ],
    );
  }
}
