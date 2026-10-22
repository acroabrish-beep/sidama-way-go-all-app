import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_insights_card.dart';
import '../models/city_os_models.dart';

import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin],
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc('summary').snapshots(),
        builder: (context, snapshot) {
          final stats = snapshot.hasData ? CitySummaryStats.fromFirestore(snapshot.data!) : null;

          return DashboardBase(
            title: 'Super Admin Dashboard',
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: AIInsightsCard(dashboardContext: 'super_admin', title: '🤖 City-Wide AI Insights'),
              ),
              const Text(
                'City Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildStatGrid(stats),
              const SizedBox(height: 24),
              const Text(
                'Revenue Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildRevenueChart(stats?.weeklyRevenue),
              const SizedBox(height: 24),
              const Text(
                'Active Emergency Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildEmergencyList(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatGrid(CitySummaryStats? stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Users', stats?.totalUsers.toString() ?? '...', Icons.people, Colors.blue),
        _buildStatCard('Taxi Requests', stats?.taxiRequests.toString() ?? '...', Icons.local_taxi, Colors.orange),
        _buildStatCard('Bus Bookings', stats?.busBookings.toString() ?? '...', Icons.directions_bus, Colors.green),
        _buildStatCard('Active SOS', stats?.activeSOS.toString() ?? '...', Icons.emergency, Colors.red),
        _buildStatCard('Total Revenue', '${stats?.totalRevenue.toInt() ?? 0} ETB', Icons.account_balance_wallet, Colors.greenAccent),
        _buildStatCard('System Health', 'Optimal', Icons.memory, Colors.tealAccent),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<double>? weeklyData) {
    final List<FlSpot> spots = [];
    if (weeklyData != null) {
      for (int i = 0; i < weeklyData.length; i++) {
        spots.add(FlSpot(i.toDouble(), weeklyData[i] / 1000)); // Normalize
      }
    } else {
      for (int i = 0; i < 7; i++) spots.add(FlSpot(i.toDouble(), 0));
    }

    return GlassCard(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withValues(alpha: 0.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.emergencyRequests).orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(data['type'] ?? 'Emergency', style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['locationName'] ?? 'Unknown Location', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
