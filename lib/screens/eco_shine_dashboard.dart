import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/firestore_service.dart';
import '../widgets/ai_insights_card.dart';

class EcoShineDashboard extends StatefulWidget {
  const EcoShineDashboard({super.key});

  @override
  State<EcoShineDashboard> createState() => _EcoShineDashboardState();
}

class _EcoShineDashboardState extends State<EcoShineDashboard> {
  final FirestoreService _fs = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Eco-Shine Management"),
          backgroundColor: const Color(0xFF00695C),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Stations"),
              Tab(text: "Services"),
              Tab(text: "Requests"),
              Tab(text: "Revenue"),
              Tab(text: "AI Assistant"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStationsTab(),
            _buildServicesTab(),
            _buildRequestsTab(),
            _buildRevenueTab(),
            _buildAIAssistantTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddStationDialog,
          backgroundColor: const Color(0xFF00695C),
          child: const Icon(Icons.add_location),
        ),
      ),
    );
  }

  Widget _buildStationsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: AIInsightsCard(dashboardContext: 'eco_shine', title: '🤖 Eco-Shine AI Insights'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.getCollectionStream('eco_shine_locations'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.eco, color: Colors.green),
                    title: Text(d['name']),
                    subtitle: Text(d['status'] ?? 'Open'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddStationDialog(id: docs[i].id, data: d)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _fs.deleteDocument('eco_shine_locations', docs[i].id)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(onPressed: () => _showAddStationDialog(), icon: const Icon(Icons.add_location), label: const Text("ADD STATION")),
        )
      ],
    );
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.getCollectionStream('eco_shine_services'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(d['serviceName'] ?? 'Service'),
                    subtitle: Text("Price: ${d['price']} ETB"),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => docs[i].reference.delete()),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(onPressed: _showAddServiceDialog, icon: const Icon(Icons.add), label: const Text("ADD SERVICE")),
        )
      ],
    );
  }

  void _showAddServiceDialog() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Eco-Shine Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Service Name (e.g. Full Wash)")),
            TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (ETB)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            _fs.addDocument('eco_shine_services', {
              'serviceName': nameC.text,
              'price': int.parse(priceC.text),
              'timestamp': FieldValue.serverTimestamp(),
            });
            Navigator.pop(context);
          }, child: const Text("Save")),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() => const Center(child: Text("Live Service Orders Monitor"));
  Widget _buildRevenueTab() => const Center(child: Text("Sustainability & Revenue Reports"));

  Widget _buildAIAssistantTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.solar_power, size: 64, color: Colors.teal),
          const SizedBox(height: 16),
          const Text("Sustainability AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("AI Insight: Eco-Shine station at Piazza has saved 450kWh of energy this month. Recommend expanding to 2 more locations in high-traffic commercial zones."),
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: () => _flutterTts.speak("Piazza station has saved 450 kilowatt hours. Expansion recommended."), child: const Text("Review Expansion Plan"))
        ],
      ),
    );
  }

  void _showAddStationDialog({String? id, Map<String, dynamic>? data}) {
    final nameC = TextEditingController(text: data?['name']);
    final statusC = TextEditingController(text: data?['status'] ?? 'Open');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? "Register Eco-Shine Station" : "Update Station"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Station Name")),
            TextField(controller: statusC, decoration: const InputDecoration(labelText: "Status (Open/Closed)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            final payload = {
              'name': nameC.text,
              'status': statusC.text,
              'timestamp': FieldValue.serverTimestamp(),
            };
            if (id == null) {
              _fs.addDocument('eco_shine_locations', payload);
            } else {
              _fs.updateDocument('eco_shine_locations', id, payload);
            }
            Navigator.pop(context);
          }, child: Text(id == null ? "Register" : "Update")),
        ],
      ),
    );
  }
}
