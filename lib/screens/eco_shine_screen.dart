import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;

class EcoShineScreen extends StatelessWidget {
  const EcoShineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco-Shine Stations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00695C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF00695C).withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF00695C)),
                SizedBox(width: 12),
                Expanded(child: Text('Solar-powered stations with water recycling & free USB charging', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('eco_shine_locations').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final stations = snapshot.data?.docs ?? [];
                if (stations.isEmpty) return const Center(child: Text('No Eco-Shine stations available yet.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stations.length,
                  itemBuilder: (context, i) {
                    final s = stations[i].data() as Map<String, dynamic>? ?? {};
                    final name = s['name'] as String? ?? 'Station';
                    final status = s['status'] as String? ?? 'Open';
                    final capacity = (s['currentOccupancy'] ?? 0) / (s['maxCapacity'] ?? 1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(20)),
                                  child: Text('Status: $status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Estimated Wait Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: capacity,
                              backgroundColor: Colors.grey.shade200,
                              color: capacity > 0.6 ? Colors.orange : Colors.teal,
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                _Badge(Icons.wb_sunny, 'Solar'),
                                _Badge(Icons.recycling, 'Water Recycle'),
                                _Badge(Icons.usb, 'USB'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Prices from 50 ETB', style: TextStyle(fontWeight: FontWeight.bold)),
                                ElevatedButton(
                                  onPressed: status == 'Open' ? () => _bookSlot(context, stations[i].id, name) : null,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white),
                                  child: const Text('Book Slot'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _bookSlot(BuildContext context, String stationId, String name) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null && context.mounted) {
      try {
        final user = Provider.of<custom_auth.AuthProvider>(context, listen: false).userModel;
        await FirebaseFirestore.instance.collection('eco_shine_bookings').add({
          'stationId': stationId,
          'stationName': name,
          'userId': user?.uid,
          'userName': user?.fullName,
          'appointmentDate': Timestamp.fromDate(date),
          'status': 'Booked',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Slot booked for ${date.day}/${date.month}/${date.year}!'), backgroundColor: const Color(0xFF00695C)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking error: $e')));
        }
      }
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}
