import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TouristBookingScreen extends StatefulWidget {
  const TouristBookingScreen({super.key});

  @override
  State<TouristBookingScreen> createState() => _TouristBookingScreenState();
}

class _TouristBookingScreenState extends State<TouristBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tourism Bookings"),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Packages"),
            Tab(text: "Guides"),
            Tab(text: "Vehicle Hire"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPackagesList(), _buildGuidesList(), _buildRidesList()],
      ),
    );
  }

  Widget _buildPackagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tourist_bookings')
          .where('userId', isEqualTo: _user?.uid)
          .where('type', isNull: true)
          .snapshots(), // Packages don't have 'type' or have 'package'
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No package bookings found."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _bookingCard(
              data['packageName'] ?? 'Tour',
              data['date'] ?? 'N/A',
              data['status'] ?? 'pending',
              data['totalPrice']?.toDouble() ?? 0.0,
            );
          },
        );
      },
    );
  }

  Widget _buildGuidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tourist_bookings')
          .where('userId', isEqualTo: _user?.uid)
          .where('type', isEqualTo: 'guide')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No guide hire requests found."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _bookingCard(
              "Guide: ${data['guideName']}",
              data['date'] ?? 'N/A',
              data['status'] ?? 'pending',
              data['totalPrice']?.toDouble() ?? 0.0,
            );
          },
        );
      },
    );
  }

  Widget _buildRidesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('contract_rides')
          .where('userId', isEqualTo: _user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("No vehicle hire bookings found."));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _bookingCard(
              "${data['vehicleType']} to ${data['destination']}",
              data['date'] ?? 'N/A',
              data['status'] ?? 'pending',
              data['price']?.toDouble() ?? 0.0,
            );
          },
        );
      },
    );
  }

  Widget _bookingCard(String title, String date, String status, double price) {
    Color statusColor = Colors.orange;
    if (status == 'confirmed' || status == 'assigned')
      statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Date: $date\nPrice: $price ETB"),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
      ),
    );
  }
}
