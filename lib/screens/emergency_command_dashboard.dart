import 'package:flutter/material.dart';
import '../models/emergency_models.dart';
import '../services/emergency_dispatch_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_insights_card.dart';

class EmergencyCommandDashboard extends StatefulWidget {
  const EmergencyCommandDashboard({super.key});

  @override
  State<EmergencyCommandDashboard> createState() => _EmergencyCommandDashboardState();
}

class _EmergencyCommandDashboardState extends State<EmergencyCommandDashboard> {
  final EmergencyDispatchService _emergencyService = EmergencyDispatchService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      appBar: AppBar(
        title: const Text('City Public Safety Command', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.emergency_share, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const AIInsightsCard(dashboardContext: 'emergency_response', title: '🚨 Emergency AI Command'),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildIncidentFeed()),
                Expanded(flex: 2, child: _buildResourceMonitor()),
              ],
            ),
          ),
          _buildSafetyKPIBar(),
        ],
      ),
    );
  }

  Widget _buildIncidentFeed() {
    return StreamBuilder<List<EmergencyIncident>>(
      stream: _emergencyService.getActiveIncidents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final incidents = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final i = incidents[index];
            return _incidentCard(i);
          },
        );
      },
    );
  }

  Widget _incidentCard(EmergencyIncident i) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: i.priority == IncidentPriority.critical ? Colors.red : Colors.white12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getIcon(i.type), color: _getPriorityColor(i.priority), size: 32),
        title: Text(i.type.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(i.description, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(i.status.name.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${DateTime.now().difference(i.createdAt).inMinutes}m ago', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        onTap: () => _showIncidentDetail(i),
      ),
    );
  }

  Widget _buildResourceMonitor() {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resource Readiness', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _resourceCard('Ambulances', '12 Available', Icons.medical_services, Colors.red),
          _resourceCard('Police Units', '45 Active', Icons.policy, Colors.blue),
          _resourceCard('Fire Units', '5 Ready', Icons.fire_truck, Colors.orange),
          const Divider(color: Colors.white24, height: 32),
          const Text('Hospital Capacity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<HospitalCapacity>>(
            stream: _emergencyService.getHospitalStatus(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                children: snapshot.data!.map((h) => _hospitalMiniCard(h)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _resourceCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _hospitalMiniCard(HospitalCapacity h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(h.hospitalName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${h.availableBeds} beds', style: TextStyle(color: h.availableBeds < 5 ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSafetyKPIBar() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _emergencyService.getEmergencyKPIs(),
      builder: (context, snapshot) {
        final kpi = snapshot.data ?? {};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kpiItem('Response Time', '${(kpi['avgResponseTime'] ?? 0).toStringAsFixed(1)} min'),
              _kpiItem('Active Incidents', '${kpi['activeIncidents'] ?? 0}'),
              _kpiItem('Critical Level', '${(kpi['criticalIncidents'] ?? 0)} HIGH'),
              _kpiItem('City Safety', '94%'),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
  ]);

  IconData _getIcon(IncidentType t) {
    switch (t) {
      case IncidentType.medical: return Icons.medical_services;
      case IncidentType.fire: return Icons.local_fire_department;
      default: return Icons.warning;
    }
  }

  Color _getPriorityColor(IncidentPriority p) {
    switch (p) {
      case IncidentPriority.critical: return Colors.red;
      case IncidentPriority.high: return Colors.orange;
      default: return Colors.yellow;
    }
  }

  void _showIncidentDetail(EmergencyIncident i) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2D),
        title: Text('Dispatch Control: ${i.type.name.toUpperCase()}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reported By: ${i.reportedBy}', style: const TextStyle(color: Colors.white70)),
            Text('Location: ${i.address}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Text(i.description, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Smart Recommendations:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const ListTile(leading: Icon(Icons.medical_services, color: Colors.red), title: Text('Ambulance 402 (2.5 km away)', style: TextStyle(color: Colors.white, fontSize: 12))),
            const ListTile(leading: Icon(Icons.policy, color: Colors.blue), title: Text('Police Unit 10 (1.8 km away)', style: TextStyle(color: Colors.white, fontSize: 12))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () {
            _emergencyService.dispatchUnits(i.incidentId, ['V-PRO-001'], 'CMD-ADMIN');
            Navigator.pop(context);
          }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('DISPATCH NOW')),
        ],
      ),
    );
  }
}
