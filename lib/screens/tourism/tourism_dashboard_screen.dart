import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tourist_sites_screen.dart';
import '../../widgets/ai_insights_card.dart';

class TourismDashboardScreen extends StatefulWidget {
  const TourismDashboardScreen({super.key});

  @override
  State<TourismDashboardScreen> createState() => _TourismDashboardScreenState();
}

class _TourismDashboardScreenState extends State<TourismDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tourism Dashboard"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Sites"),
            Tab(text: "Guides"),
            Tab(text: "Operators"),
            Tab(text: "Bookings"),
            Tab(text: "Rides"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const TouristSitesScreen(), // Use existing management in TouristSitesScreen
          _buildGuidesTab(),
          _buildOperatorsTab(),
          _buildBookingsTab(),
          _buildRidesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AIInsightsCard(dashboardContext: 'tourism', title: '🤖 Tourism AI Insights'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _statCard("Sites", "tourist_sites", Icons.landscape, Colors.green),
            _statCard("Packages", "tour_packages", Icons.inventory_2, Colors.blue),
            _statCard("Approved Guides", "tour_guides", Icons.person_pin, Colors.teal, filterField: "status", filterValue: "approved"),
            _statCard("Operators", "tour_operators", Icons.business_center, Colors.indigo, filterField: "status", filterValue: "approved"),
            _statCard("Total Bookings", "tourist_bookings", Icons.book_online, Colors.orange),
            _statCard("Contract Rides", "contract_rides", Icons.car_rental, Colors.purple),
          ],
        ),
        const SizedBox(height: 32),
        const Text("Bookings Last 7 Days", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSimpleChart(),
      ],
    );
  }

  Widget _statCard(String label, String collection, IconData icon, Color color, {String? filterField, String? filterValue}) {
    Query query = _firestore.collection(collection);
    if (filterField != null) query = query.where(filterField, isEqualTo: filterValue);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return Card(
          color: color.withValues(alpha: 0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.2))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(count.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          double h = (10 + (index * 20)).toDouble(); // Dummy data logic
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 20, height: h, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Text("D${index + 1}", style: const TextStyle(fontSize: 10)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGuidesTab() {
    return _buildApplicationList('tour_guides', 'fullName', 'experience');
  }

  Widget _buildOperatorsTab() {
    return _buildApplicationList('tour_operators', 'companyName', 'licenseNumber');
  }

  Widget _buildApplicationList(String collection, String titleField, String subField) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(data[titleField] ?? 'N/A'),
                subtitle: Text("${data[subField]} | Status: $status"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => docs[i].reference.update({'status': 'approved'})),
                    IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => docs[i].reference.update({'status': 'rejected'})),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tourist_bookings').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(d['packageName'] ?? d['title'] ?? 'Booking'),
                subtitle: Text("User: ${d['userName']} | ${d['status']}"),
                trailing: PopupMenuButton(
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'confirmed', child: Text("Confirm")),
                    const PopupMenuItem(value: 'cancelled', child: Text("Cancel")),
                  ],
                  onSelected: (val) => docs[i].reference.update({'status': val}),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRidesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('contract_rides').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text("${d['vehicleType']} to ${d['destination']}"),
                subtitle: Text("Pickup: ${d['pickup']} | ${d['status']}"),
                trailing: TextButton(
                  onPressed: () => _showAssignDriverDialog(docs[i]),
                  child: const Text("Assign"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignDriverDialog(DocumentSnapshot doc) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Assign Driver"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: "Driver Name")),
          TextField(controller: phoneC, decoration: const InputDecoration(labelText: "Driver Phone")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () {
          doc.reference.update({'driverName': nameC.text, 'driverPhone': phoneC.text, 'status': 'assigned'});
          Navigator.pop(context);
        }, child: const Text("Assign")),
      ],
    ));
  }
}
