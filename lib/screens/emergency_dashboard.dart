import 'package:flutter/material.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import 'crud_list_screen.dart';
import '../widgets/ai_insights_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';

class EmergencyDashboard extends StatelessWidget {
  const EmergencyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.emergencyAdmin],
      child: DashboardBase(
        title: 'Emergency Response',
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AIInsightsCard(dashboardContext: 'emergency', title: '🤖 Emergency AI Insights'),
          ),
          _buildLiveAlerts(),
          const SizedBox(height: 24),
          _buildActionGrid(context),
          const SizedBox(height: 24),
          const Text(
            'Incident Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildIncidentList(),
        ],
      ),
    );
  }

  Widget _buildLiveAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_requests')
          .where('status', whereIn: ['pending', 'active'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const GlassCard(child: Text('Error loading alerts', style: TextStyle(color: Colors.white)));
        }
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return GlassCard(
          color: count > 0 ? Colors.red : Colors.green,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active SOS Requests', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$count Active Alerts', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const Icon(Icons.notifications_active, color: Colors.white, size: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildActionItem(context, 'Manage SOS', Icons.emergency, 'sos_requests', ['type', 'location_name', 'status', 'description']),
        _buildActionItem(context, 'Incident Reports', Icons.report, 'incident_reports', ['type', 'location', 'status', 'description']),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, String collection, List<String> fields) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CRUDListScreen(collection: collection, title: title, fields: fields))),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sos_requests').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading incidents', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active incidents', style: TextStyle(color: Colors.white70)));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(
                  data['type'] == 'Police' ? Icons.local_police : Icons.fire_truck,
                  color: Colors.white,
                ),
                title: Text(data['type'] ?? 'Emergency', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('At: ${data['location_name'] ?? 'Unknown'}\nBy: ${data['userName'] ?? 'Citizen'}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pending')
                      _statusButton(doc, 'dispatched', Colors.yellow),
                    if (status == 'dispatched')
                      _statusButton(doc, 'on scene', Colors.orange),
                    if (status == 'on scene')
                      _statusButton(doc, 'resolved', Colors.green),
                    const SizedBox(width: 8),
                    Text(status.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statusButton(DocumentSnapshot doc, String nextStatus, Color color) {
    return ElevatedButton(
      onPressed: () => doc.reference.update({'status': nextStatus}),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 8)),
      child: Text(nextStatus.toUpperCase(), style: const TextStyle(fontSize: 8)),
    );
  }
}
