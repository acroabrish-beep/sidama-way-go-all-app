import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusTrackScreen extends StatefulWidget {
  const BusTrackScreen({super.key});
  @override
  State<BusTrackScreen> createState() => _BusTrackScreenState();
}

class _BusTrackScreenState extends State<BusTrackScreen> {
  final List<Map<String, dynamic>> routes = [
    {
      'name': 'Route 1 — Piassa → Stadium',
      'stops': ['Piassa', 'Adebabay', 'Post Office', 'Stadium'],
      'status': 'On Route',
      'eta': '5 min',
      'color': 0xFF2E7D32,
    },
    {
      'name': 'Route 2 — Menahariya → University',
      'stops': ['Menahariya', 'Market', 'Hospital', 'University'],
      'status': 'Arriving',
      'eta': '2 min',
      'color': 0xFF1565C0,
    },
    {
      'name': 'Route 3 — Bus Station → Lake',
      'stops': ['Bus Station', 'Tabor', 'Referral', 'Hawassa Lake'],
      'status': 'Delayed',
      'eta': '15 min',
      'color': 0xFFE65100,
    },
  ];

  int selectedRoute = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          'Bus Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1565C0),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Hawassa City — Live Bus Tracking',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('terminal_routes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No active bus routes.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final r = docs[index].data() as Map<String, dynamic>;
                    final isSelected = selectedRoute == index;
                    final routeColor = index % 2 == 0 ? 0xFF2E7D32 : 0xFF1565C0;

                    return GestureDetector(
                      onTap: () => setState(() => selectedRoute = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(routeColor).withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Color(routeColor)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r['route'] as String? ?? 'Unknown Route',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(routeColor),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Origin: ${r['origin'] as String? ?? 'N/A'} | Dest: ${r['destination'] as String? ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fare: ${r['fare'] as num? ?? 0} ETB',
                                  style: const TextStyle(color: Colors.grey),
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
}
