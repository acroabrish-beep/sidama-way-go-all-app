import 'package:flutter/material.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import 'crud_list_screen.dart';
import '../widgets/ai_insights_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';

class PharmacyDashboard extends StatelessWidget {
  const PharmacyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.pharmacyAdmin],
      child: DashboardBase(
        title: 'Pharmacy Admin',
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CRUDListScreen(collection: 'medicines', title: 'Medicines', fields: ['name', 'quantity', 'price', 'pharmacy']))),
          backgroundColor: Colors.tealAccent,
          child: const Icon(Icons.add_shopping_cart, color: Colors.teal),
        ),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AIInsightsCard(dashboardContext: 'pharmacy', title: '🤖 Pharmacy AI Insights'),
          ),
          _buildStats(),
          const SizedBox(height: 24),
          const Text(
            'Inventory Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildInventoryList(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc('pharmacy').snapshots(),
      builder: (context, snapshot) {
        final stats = snapshot.hasData ? PharmacySummaryStats.fromFirestore(snapshot.data!) : null;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Pharmacies', stats?.totalPharmacies.toString() ?? '...', Icons.local_pharmacy, Colors.greenAccent)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Total Meds', stats?.totalMedicines.toString() ?? '...', Icons.medication, Colors.orangeAccent)),
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

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicine_orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading orders', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active orders', style: TextStyle(color: Colors.white70)));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = data['status'] as String? ?? 'pending';
            final medicineName = data['medicineName'] as String? ?? 'Medicine';
            final customerName = data['customerName'] as String? ?? 'Customer';
            final customerPhone = data['customerPhone'] as String? ?? 'N/A';

            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(medicineName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('By: $customerName\nPhone: $customerPhone', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pending')
                      _statusButton(doc, 'preparing', Colors.yellow),
                    if (status == 'preparing')
                      _statusButton(doc, 'ready', Colors.orange),
                    if (status == 'ready')
                      _statusButton(doc, 'delivered', Colors.green),
                    const SizedBox(width: 8),
                    Text(status.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontSize: 8, fontWeight: FontWeight.bold)),
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
