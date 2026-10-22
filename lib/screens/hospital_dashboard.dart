import 'package:flutter/material.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import 'crud_list_screen.dart';
import '../widgets/ai_insights_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';

class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.healthAdmin],
      child: DashboardBase(
        title: 'Healthcare Admin',
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AIInsightsCard(dashboardContext: 'hospital', title: '🤖 Healthcare AI Insights'),
          ),
          _buildStats(),
          const SizedBox(height: 24),
          _buildActionGrid(context),
          const SizedBox(height: 24),
          const Text(
            'Ambulance Dispatch',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildDispatchList(),
          const SizedBox(height: 24),
          const Text(
            'Registered Doctors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildDoctorList(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc('healthcare').snapshots(),
      builder: (context, snapshot) {
        final stats = snapshot.hasData ? HealthcareSummaryStats.fromFirestore(snapshot.data!) : null;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Hospitals', stats?.totalHospitals.toString() ?? '...', Icons.local_hospital, Colors.redAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Ambulances', stats?.totalAmbulances.toString() ?? '...', Icons.medical_services, Colors.blueAccent)),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildActionItem(context, 'Hospitals', Icons.local_hospital, 'hospitals', ['name', 'location', 'phone']),
        _buildActionItem(context, 'Doctors', Icons.person, 'doctors', ['name', 'specialty', 'hospital']),
        _buildActionItem(context, 'Appointments', Icons.calendar_month, 'appointments', ['patientName', 'hospitalName', 'status']),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, String collection, List<String> fields) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CRUDListScreen(collection: collection, title: title, fields: fields))),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading appointments', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active appointments', style: TextStyle(color: Colors.white70)));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = data['status'] as String? ?? 'pending';
            final patientName = data['patientName'] as String? ?? 'Patient';
            final reason = data['reason'] as String? ?? 'N/A';
            final hospitalName = data['hospitalName'] as String? ?? 'N/A';

            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(patientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Reason: $reason\nHospital: $hospitalName', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pending') ...[
                      IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => doc.reference.update({'status': 'confirmed'})),
                      IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => doc.reference.update({'status': 'cancelled'})),
                    ],
                    Text(status.toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDoctorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading doctors'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] as String? ?? 'Dr. Smith';
            final specialty = data['specialty'] as String? ?? 'General';
            final isAvailable = data['status'] == 'Available' || data['isAvailable'] == true;

            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(specialty, style: const TextStyle(color: Colors.white70)),
                trailing: CircleAvatar(
                  backgroundColor: isAvailable ? Colors.green : Colors.grey,
                  radius: 5,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
