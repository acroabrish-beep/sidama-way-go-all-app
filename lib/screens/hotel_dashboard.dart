import 'package:flutter/material.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import 'crud_list_screen.dart';
import '../widgets/ai_insights_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';

class HotelDashboard extends StatelessWidget {
  const HotelDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.hotelAdmin],
      child: DashboardBase(
        title: 'Hotel Admin',
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CRUDListScreen(collection: 'hotels', title: 'Hotels', fields: ['name', 'location', 'rating', 'description']))),
          backgroundColor: Colors.purpleAccent,
          child: const Icon(Icons.add_home, color: Colors.white),
        ),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AIInsightsCard(dashboardContext: 'hotel', title: '🤖 Hotel AI Insights'),
          ),
          _buildSummary(),
          const SizedBox(height: 24),
          const Text(
            'Active Bookings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildBookingList(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc('hotel').snapshots(),
      builder: (context, snapshot) {
        final stats = snapshot.hasData ? HotelSummaryStats.fromFirestore(snapshot.data!) : null;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard('Total Hotels', stats?.totalHotels.toString() ?? '...', Icons.hotel, Colors.purpleAccent),
            _buildStatCard('Revenue', '${(stats?.totalRevenue ?? 0 / 1000).toStringAsFixed(1)}k', Icons.attach_money, Colors.greenAccent),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('hotel_reservations').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading reservations', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No active reservations', style: TextStyle(color: Colors.white70)));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            return GlassCard(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(data['hotelName']?.toString() ?? 'Hotel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('Guest: ${data['guestName']}\nPhone: ${data['guestPhone']}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pending') ...[
                      IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => doc.reference.update({'status': 'confirmed'})),
                      IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => doc.reference.update({'status': 'rejected'})),
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
}
