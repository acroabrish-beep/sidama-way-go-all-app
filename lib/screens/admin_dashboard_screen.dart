import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_registration_screen.dart';
import 'mobility/driver_registration_screen.dart';
import 'admin_location_dashboard.dart';
import '../models/taxi_models.dart';
import '../services/taxi_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('City Admin Dashboard'),
          backgroundColor: const Color(0xFF37474F),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.location_on), text: 'Live Map'),
              Tab(icon: Icon(Icons.business), text: 'Terminals'),
              Tab(icon: Icon(Icons.local_taxi), text: 'City Taxi'),
              Tab(icon: Icon(Icons.place), text: 'Stations'),
              Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminLocationDashboard(),
            _TerminalsTab(),
            _CityTaxiTab(),
            _TaxiStationsTab(),
            _VehiclesTab(),
          ],
        ),
      ),
    );
  }
}

class _TaxiStationsTab extends StatefulWidget {
  const _TaxiStationsTab();

  @override
  State<_TaxiStationsTab> createState() => _TaxiStationsTabState();
}

class _TaxiStationsTabState extends State<_TaxiStationsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _taxiService = TaxiService();

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _addStation() async {
    if (_formKey.currentState!.validate()) {
      await _taxiService.saveStation(TaxiStation(
        stationId: '',
        stationName: _nameController.text,
        stationCode: 'HUB',
        location: const GeoPoint(7.0504, 38.4955),
        maximumVehicleCapacity: int.tryParse(_capacityController.text) ?? 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _nameController.clear();
      _capacityController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station added!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Station', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Station Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Max Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addStation,
                        child: const Text('Add Station'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Stations List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<TaxiStation>>(
            stream: _taxiService.getTaxiStations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final stations = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final s = stations[index];
                  return Card(
                    child: ListTile(
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Text('Cap: ${s.capacity}'),
                          const SizedBox(width: 16),
                          Text('Taxis: ${s.activeTaxiCount}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (s.status == 'Active' ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(s.status, style: TextStyle(color: s.status == 'Active' ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editStation(s)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStation(s.id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _editStation(TaxiStation station) {
    final nameC = TextEditingController(text: station.name);
    final capC = TextEditingController(text: station.capacity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: capC, decoration: const InputDecoration(labelText: 'Capacity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            await _taxiService.saveStation(TaxiStation(
              stationId: station.id,
              stationName: nameC.text,
              stationCode: station.code,
              location: station.location,
              maximumVehicleCapacity: int.tryParse(capC.text) ?? 10,
              createdAt: station.createdAt,
              updatedAt: DateTime.now(),
            ));
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _deleteStation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Station'),
        content: const Text('Are you sure you want to delete this station?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            await _taxiService.deleteStation(id);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _TerminalsTab extends StatelessWidget {
  const _TerminalsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _statCard('Old Terminal Bookings', 'bookings', 'terminal', 'Hawassa Old Terminal'),
        _statCard('New Terminal Bookings', 'bookings', 'terminal', 'Hawassa New Terminal'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Recent Intercity Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Error loading data');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text('No recent bookings.');

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final name = data['passengerName'] as String? ?? 'No Name';
                final route = data['route'] as String? ?? 'Unknown Route';
                final fare = data['fare'] as num? ?? 0;
                final status = data['status'] as String? ?? 'Confirmed';

                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('$route - $fare ETB'),
                    trailing: Chip(label: Text(status)),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _statCard(String label, String collection, String field, String value) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where(field, isEqualTo: value).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$count', style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CityTaxiTab extends StatelessWidget {
  const _CityTaxiTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _simpleStat('Total Taxi Requests', 'taxi_requests'),
        _simpleStat('Drivers in Queue', 'queues', whereField: 'status', whereValue: 'waiting'),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Recent Taxi Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('taxi_requests').orderBy('timestamp', descending: true).limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Error loading data');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text('No recent requests.');

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text('Destination: ${data['destination']}'),
                    subtitle: Text('Fare: ${data['fare']} ETB | Status: ${data['status']}'),
                    trailing: const Icon(Icons.local_taxi, color: Colors.orange),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _simpleStat(String label, String collection, {String? whereField, String? whereValue}) {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (whereField != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$count', style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VehiclesTab extends StatelessWidget {
  const _VehiclesTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _totalCountCard('Registered Vehicles', 'vehicles')),
              const SizedBox(width: 12),
              Expanded(child: _totalCountCard('Total Drivers', 'drivers')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('New Vehicle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRegistrationScreen())),
                  icon: const Icon(Icons.person_add),
                  label: const Text('New Driver'),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Vehicle List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(data['plateNumber']),
                      subtitle: Text('${data['type']} | ${data['driverName']}'),
                      trailing: Chip(label: Text(data['status'] ?? 'Active')),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _totalCountCard(String label, String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('$count', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}
