import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_os_models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CITY FLOW ANALYTICS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('REAL-TIME MONITORING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                _statStream('USERS', CityOSCollection.users, Icons.people, Colors.green),
                const SizedBox(width: 12),
                _statStream('TAXIS', CityOSCollection.vehicles, Icons.local_taxi, Colors.blue, whereField: 'type', whereValue: 'City Taxi'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('TRANSPORT DEMAND FORECAST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildDemandChart(),
            const SizedBox(height: 32),
            const Text('RECENT CITY ALERTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildAlertsList(),
          ],
        ),
      ),
    );
  }

  Widget _statStream(String label, String collection, IconData icon, Color color, {String? whereField, String? whereValue}) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (whereField != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final val = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemandChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(30), _bar(50), _bar(80), _bar(100), _bar(70), _bar(40),
        ],
      ),
    );
  }

  Widget _bar(double h) {
    return Container(
      width: 20,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAlertsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.announcements).orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No recent alerts.');

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>? ?? {};
            final priority = d['priority'] as String? ?? 'Medium';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.warning_rounded, color: priority == 'High' ? Colors.red : Colors.orange),
                title: Text(d['title'] as String? ?? 'Alert'),
                subtitle: Text(d['message'] as String? ?? ''),
                trailing: Text(priority, style: TextStyle(color: priority == 'High' ? Colors.red : Colors.orange, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
