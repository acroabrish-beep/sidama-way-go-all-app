import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'terminal_qr_scanner.dart';

class TransportationAdminDashboard extends StatefulWidget {
  const TransportationAdminDashboard({super.key});

  @override
  State<TransportationAdminDashboard> createState() => _TransportationAdminDashboardState();
}

class _TransportationAdminDashboardState extends State<TransportationAdminDashboard> {
  final FirestoreService _fs = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    // Demo seeding is debug-only.
    if (kDebugMode) _fs.checkAndSeedTransport();
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).userModel?.role;
    if (role != UserRole.superAdmin && role != UserRole.governmentFleetAdmin) {
      return const Scaffold(body: Center(child: Text("Access Denied")));
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Transport Admin"),
          backgroundColor: const Color(0xFF1565C0),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Routes"),
              Tab(text: "Vehicles"),
              Tab(text: "Drivers"),
              Tab(text: "Schedules"),
              Tab(text: "Tickets"),
              Tab(text: "AI Assistant"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRoutesTab(),
            _buildVehiclesTab(),
            _buildDriversTab(),
            _buildSchedulesTab(),
            _buildTicketsTab(),
            _buildAIAssistantTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                if (tabIndex == 4) { // Tickets Tab
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TerminalQRScanner()));
                } else {
                   _showAddRouteDialog();
                }
              },
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.qr_code_scanner),
            );
          }
        ),
      ),
    );
  }

  void _showAddRouteDialog() {
    // Basic dialog to add route
  }

  Widget _buildRoutesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getCollectionStream('routes'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: Text("${data['origin']} -> ${data['destination']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _fs.deleteDocument('routes', docs[i].id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehiclesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getCollectionStream('vehicles'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(data['plateNumber']),
              subtitle: Text("${data['type']} - ${data['model']} (${data['capacity']} seats)"),
              trailing: Text(data['status'], style: TextStyle(color: data['status'] == 'Active' ? Colors.green : Colors.grey)),
            );
          },
        );
      },
    );
  }

  Widget _buildDriversTab() {
    return const Center(child: Text("Drivers Management coming soon"));
  }

  Widget _buildSchedulesTab() {
    return const Center(child: Text("Schedules Management coming soon"));
  }

  Widget _buildTicketsTab() {
    return const Center(child: Text("Tickets Analytics coming soon"));
  }

  Widget _buildAIAssistantTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.psychology, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text("Transport AI Insight", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("AI Recommendation: Passenger demand for Addis Ababa route peaks on Friday afternoons. Recommend increasing bus frequency between 2 PM and 6 PM."),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _flutterTts.speak("Demand for Addis Ababa route is high on Friday afternoons. Consider adding more vehicles."),
            icon: const Icon(Icons.volume_up),
            label: const Text("Voice Report"),
          ),
        ],
      ),
    );
  }
}
