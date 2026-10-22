import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/mobility/driver_registration_screen.dart';

class TaxiQueueScreen extends StatelessWidget {
  const TaxiQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi Queue Management'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers')
            .where('online', isEqualTo: true)
            .where('status', isEqualTo: 'waiting')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final queue = snapshot.data!.docs;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.blueGrey[900],
                child: Column(
                  children: [
                    const Text('Current Queue Active', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('${queue.length}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    const Text('Vehicles Waiting', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final data = queue[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('Taxi: ${data['plateNumber']}'),
                      subtitle: Text('Driver: ${data['fullName']} | ${data['stationName'] ?? 'General'}'),
                      trailing: const Icon(Icons.more_vert),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _joinQueue(context),
                  icon: const Icon(Icons.add),
                  label: const Text('JOIN QUEUE'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _joinQueue(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()));
  }
}
