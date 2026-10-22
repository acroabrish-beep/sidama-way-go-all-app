import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tourism_models.dart';

class ContractRideScreen extends StatefulWidget {
  const ContractRideScreen({super.key});

  @override
  State<ContractRideScreen> createState() => _ContractRideScreenState();
}

class _ContractRideScreenState extends State<ContractRideScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _pickupC = TextEditingController();
  final _destC = TextEditingController();
  final _dateC = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _timeC = TextEditingController(text: "08:00");
  final _phoneC = TextEditingController();
  final _requestC = TextEditingController();

  String _selectedVehicle = '';
  String _duration = 'Half Day';
  int _passengers = 1;
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _vehicles = [
    {'type': 'Taxi', 'icon': Icons.local_taxi, 'info': '1-4 passengers | 500 ETB/half day | 900 ETB/full day', 'half': 500, 'full': 900},
    {'type': 'Tourist Van', 'icon': Icons.airport_shuttle, 'info': '1-8 passengers | 1200 ETB/half day | 2000 ETB/full day', 'half': 1200, 'full': 2000},
    {'type': 'SUV', 'icon': Icons.directions_car, 'info': '1-5 passengers | 1500 ETB/half day | 2500 ETB/full day', 'half': 1500, 'full': 2500},
    {'type': 'Minibus', 'icon': Icons.directions_bus, 'info': '1-15 passengers | 2000 ETB/half day | 3500 ETB/full day', 'half': 2000, 'full': 3500},
  ];

  double _calculatePrice() {
    if (_selectedVehicle.isEmpty) return 0;
    final v = _vehicles.firstWhere((element) => element['type'] == _selectedVehicle);
    return _duration == 'Half Day' ? v['half'].toDouble() : v['full'].toDouble();
  }

  void _bookVehicle() async {
    if (_selectedVehicle.isEmpty || _pickupC.text.isEmpty || _destC.text.isEmpty || _phoneC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      DateTime bookingDate;
      try {
        bookingDate = DateTime.parse(_dateC.text);
      } catch (e) {
        bookingDate = DateTime.now();
      }

      final doc = await _firestore.collection('contract_rides').add({
        'userId': user?.uid,
        'pickup': _pickupC.text,
        'destination': _destC.text,
        'vehicleType': _selectedVehicle,
        'duration': _duration,
        'passengers': _passengers,
        'price': _calculatePrice(),
        'date': Timestamp.fromDate(bookingDate),
        'time': _timeC.text,
        'passengerPhone': _phoneC.text,
        'paymentMethod': _paymentMethod,
        'specialRequests': _requestC.text,
        'status': "pending",
        'type': "contract",
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text("Booking Successful!"),
          content: Text("Booking ID: ${doc.id}\nStatus: Pending - Driver will be assigned shortly"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ));
        setState(() {
          _selectedVehicle = '';
          _pickupC.clear();
          _destC.clear();
          _phoneC.clear();
          _requestC.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🚗 Hire Vehicle"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Book a vehicle for your Hawassa tour or airport transfer", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            _buildVehicleSelection(),
            if (_selectedVehicle.isNotEmpty) _buildBookingForm(),
            _buildAirportTransferCard(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("My Rides", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _buildMyRides(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
      itemCount: _vehicles.length,
      itemBuilder: (context, i) {
        final v = _vehicles[i];
        final isSelected = _selectedVehicle == v['type'];
        return InkWell(
          onTap: () => setState(() => _selectedVehicle = v['type']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(v['icon'], size: 40, color: isSelected ? Colors.green : Colors.grey),
                const SizedBox(height: 8),
                Text(v['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(v['info'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _pickupC, decoration: const InputDecoration(labelText: "Pickup Location", prefixIcon: Icon(Icons.my_location))),
          const SizedBox(height: 12),
          TextField(controller: _destC, decoration: const InputDecoration(labelText: "Destination", prefixIcon: Icon(Icons.location_on))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Airport', 'Lake Hawassa', 'Tabor', 'Gudumale', 'City Tour'].map((chip) {
              return ActionChip(label: Text(chip, style: const TextStyle(fontSize: 10)), onPressed: () => setState(() => _destC.text = chip));
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _dateC, decoration: const InputDecoration(labelText: "Date", hintText: "YYYY-MM-DD"))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _timeC, decoration: const InputDecoration(labelText: "Time", hintText: "HH:MM"))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Duration:"),
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                isSelected: [_duration == 'Half Day', _duration == 'Full Day'],
                onPressed: (index) => setState(() => _duration = index == 0 ? 'Half Day' : 'Full Day'),
                children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Half Day")), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("Full Day"))],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Passengers:"),
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _passengers = _passengers > 1 ? _passengers - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                  Text("$_passengers", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setState(() => _passengers = _passengers < 15 ? _passengers + 1 : 15), icon: const Icon(Icons.add_circle_outline)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _phoneC, decoration: const InputDecoration(labelText: "Passenger Phone"), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: "Payment Method"),
            items: ['Telebirr', 'CBE Birr', 'Cash'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _requestC, decoration: const InputDecoration(labelText: "Special Requests (Optional)")),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price:"),
              Text("${_calculatePrice()} ETB", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _bookVehicle,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Book Vehicle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAirportTransferCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.blue)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.flight_land, size: 40, color: Colors.blue),
              title: Text("✈️ Airport Transfer", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Arriving at Hawassa Airport? Book your transfer to hotel."),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _pickupC.text = "Hawassa Airport";
                _selectedVehicle = 'Taxi';
              }),
              child: const Text("Book Airport Transfer"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyRides() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('contract_rides').where('userId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No rides booked yet."));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ride = ContractRide.fromMap(data, docs[i].id);
            return ListTile(
              leading: const Icon(Icons.car_rental),
              title: Text("${ride.vehicleType} - ${data['duration'] ?? 'N/A'}"),
              subtitle: Text("${ride.pickup} → ${ride.destination} | ${ride.date.toString().split(' ')[0]}"),
              trailing: Chip(label: Text(ride.status.toUpperCase(), style: const TextStyle(fontSize: 8))),
            );
          },
        );
      },
    );
  }
}
