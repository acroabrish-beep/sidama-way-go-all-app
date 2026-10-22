import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/taxi_models.dart';
import '../services/taxi_service.dart';
import '../services/test_data_seeder.dart';
import '../widgets/glass_card.dart';
import 'book_ride_screen.dart';
import 'queue_screen.dart';
import 'driver_ride_requests_screen.dart';
import 'driver_earnings_screen.dart';
import 'ride_history_screen.dart';

class CityTaxiScreen extends StatefulWidget {
  const CityTaxiScreen({super.key});

  @override
  State<CityTaxiScreen> createState() => _CityTaxiScreenState();
}

class _CityTaxiScreenState extends State<CityTaxiScreen> {
  final TaxiService _taxiService = TaxiService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final bool isAdmin = user?.role == UserRole.superAdmin || user?.role == UserRole.taxiAdmin;
    final bool isDriver = user?.role == UserRole.taxiDriver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('City Taxi Service'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'Seed Test Data',
              onPressed: _seedTestData,
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
            ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildStatusHeader(isDriver, user),
            const SizedBox(height: 24),
            if (isDriver) ...[
              _buildDriverActions(),
              const SizedBox(height: 24),
            ] else ...[
              _buildRiderActions(),
              const SizedBox(height: 24),
            ],
            const Text('Taxi Stations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 16),
            _buildStationsList(),
            const SizedBox(height: 24),
            const Text('Popular Destinations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 16),
            _buildPopularDestinations(),
          ],
        ),
      ),
      floatingActionButton: !isDriver ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookRideScreen())),
        label: const Text('BOOK A RIDE'),
        icon: const Icon(Icons.local_taxi),
        backgroundColor: Colors.orange[700],
      ) : null,
    );
  }

  Widget _buildStatusHeader(bool isDriver, UserModel? user) {
    if (isDriver) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final bool isOnline = data['online'] ?? false;
          final String status = data['status'] ?? 'offline';

          return GlassCard(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user?.photo.isNotEmpty == true ? NetworkImage(user!.photo) : null,
                  child: user?.photo.isEmpty == true ? const Icon(Icons.person, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Driver', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Status: ${status.toUpperCase()}', style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.white70)),
                    ],
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: (val) => _taxiService.toggleDriverOnline(user!.uid, val),
                  activeThumbColor: Colors.greenAccent,
                ),
              ],
            ),
          );
        },
      );
    }

    return GlassCard(
      color: const Color(0xFF1A237E),
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome to Smart Taxi', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Reliable, safe, and fast transportation across Hawassa.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildDriverActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            'Ride Requests',
            Icons.local_taxi,
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRideRequestsScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            'Earnings',
            Icons.account_balance_wallet,
            Colors.green,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            'Book Ride',
            Icons.directions_car,
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookRideScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            'Ride History',
            Icons.history,
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen())),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationsList() {
    return StreamBuilder<List<TaxiStation>>(
      stream: _taxiService.getTaxiStations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stations = snapshot.data!;

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            itemBuilder: (context, i) {
              final s = stations[i];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.place, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${s.onlineTaxiCount} Taxis', style: const TextStyle(fontSize: 12, color: Colors.green)),
                        Text('${s.waitingPassengers} Waiting', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularDestinations() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('popular_destinations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(data['name'] ?? 'Destination'),
                subtitle: Text('Estimated Fare: ${data['baseFare']} ETB'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookRideScreen(preselectedDestination: data['name']))),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _seedTestData() async {
    final seeder = TestDataSeeder();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Seeding test data...'),
          ],
        ),
      ),
    );

    try {
      await seeder.seedAllTestData();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding test data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
