import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../utils/language_provider.dart';
import 'ai_assistant_screen.dart';

enum TerminalStep {
  selectTerminal,
  selectRoute,
  selectBus,
  selectSeat,
  passengerInfo,
  payment,
  ticket,
}

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  TerminalStep _currentStep = TerminalStep.selectTerminal;
  String _selectedTerminal = '';
  Map<String, dynamic>? _selectedRoute;
  Map<String, dynamic>? _selectedBus;
  int? _selectedSeat;
  String? _paymentMethod;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final List<Map<String, dynamic>> _oldTerminalRoutes = [
    {'route': 'Hawassa → Shashamane', 'fare': 80, 'duration': '1.5 hrs'},
    {'route': 'Hawassa → Dilla', 'fare': 120, 'duration': '2 hrs'},
    {'route': 'Hawassa → Arba Minch', 'fare': 200, 'duration': '4 hrs'},
    {'route': 'Hawassa → Yirgalem', 'fare': 60, 'duration': '1 hr'},
  ];

  final List<Map<String, dynamic>> _newTerminalRoutes = [
    {'route': 'Hawassa → Addis Ababa', 'fare': 280, 'duration': '6 hrs'},
    {'route': 'Hawassa → Adama', 'fare': 220, 'duration': '4.5 hrs'},
    {'route': 'Hawassa → Jimma', 'fare': 300, 'duration': '7 hrs'},
    {'route': 'Hawassa → Bahir Dar', 'fare': 450, 'duration': '12 hrs'},
  ];

  final List<int> _occupiedSeats = List.generate(
    10,
    (index) => Random().nextInt(40) + 1,
  );

  String _ticketId = '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _seedRoutes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('routes')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (var r in _oldTerminalRoutes) {
        final docRef = FirebaseFirestore.instance.collection('routes').doc();
        batch.set(docRef, {...r, 'terminal': 'Hawassa Old Terminal'});
      }
      for (var r in _newTerminalRoutes) {
        final docRef = FirebaseFirestore.instance.collection('routes').doc();
        batch.set(docRef, {...r, 'terminal': 'Hawassa New Terminal'});
      }
      await batch.commit();
    }
  }

  @override
  void initState() {
    super.initState();
    // Demo seeding is debug-only.
    if (kDebugMode) _seedRoutes();
  }

  void _nextStep(TerminalStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _processPayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      _ticketId = 'TK-${DateTime.now().millisecondsSinceEpoch}';
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('bookings').add({
        'ticketId': _ticketId,
        'passengerName': _nameController.text,
        'phone': _phoneController.text,
        'busId': _selectedBus!['id'],
        'seatNumber': _selectedSeat,
        'route': _selectedRoute!['route'],
        'terminal': _selectedTerminal,
        'fare': _selectedRoute!['fare'],
        'paymentMethod': _paymentMethod,
        'status': 'confirmed',
        'userId': user?.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _nextStep(TerminalStep.ticket);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('intercity_bus')),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _buildStepContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case TerminalStep.selectTerminal:
        return _buildTerminalSelection();
      case TerminalStep.selectRoute:
        return _buildRouteSelection();
      case TerminalStep.selectBus:
        return _buildBusSelection();
      case TerminalStep.selectSeat:
        return _buildSeatSelection();
      case TerminalStep.passengerInfo:
        return _buildPassengerInfo();
      case TerminalStep.payment:
        return _buildPayment();
      case TerminalStep.ticket:
        return _buildTicket();
    }
  }

  Widget _buildTerminalSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSelectionCard(
          icon: Icons.history,
          title: 'Hawassa Old Terminal',
          desc:
              'Serving regional routes like Shashamane, Dilla, and Arba Minch.',
          onTap: () {
            setState(() {
              _selectedTerminal = 'Hawassa Old Terminal';
            });
            _nextStep(TerminalStep.selectRoute);
          },
        ),
        const SizedBox(height: 16),
        _buildSelectionCard(
          icon: Icons.new_releases,
          title: 'Hawassa New Terminal',
          desc: 'Serving major cities like Addis Ababa, Adama, and Bahir Dar.',
          onTap: () {
            setState(() {
              _selectedTerminal = 'Hawassa New Terminal';
            });
            _nextStep(TerminalStep.selectRoute);
          },
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 48, color: const Color(0xFF2E7D32)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('terminal_routes')
          .where('terminal', isEqualTo: _selectedTerminal)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final routes = snapshot.data?.docs ?? [];
        if (routes.isEmpty)
          return const Center(
            child: Text('No routes available for this terminal.'),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index].data() as Map<String, dynamic>? ?? {};
            final routeName = r['route'] as String? ?? 'Unknown Route';
            final duration = r['duration'] as String? ?? 'N/A';
            final fare = r['fare'] as num? ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  routeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Duration: $duration'),
                trailing: Text(
                  '$fare ETB',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedRoute = {'route': routeName, 'fare': fare};
                  });
                  _nextStep(TerminalStep.selectBus);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('terminal', isEqualTo: _selectedTerminal)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final vehicles = snapshot.data?.docs ?? [];
        if (vehicles.isEmpty)
          return const Center(child: Text('No buses available right now.'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final b = vehicles[index].data() as Map<String, dynamic>? ?? {};
            final busId =
                b['plateNumber'] as String? ??
                b['id'] as String? ??
                'BUS-${index + 1}';
            final company =
                b['type'] as String? ??
                b['company'] as String? ??
                'Transport Co.';
            final capacity = b['capacity'] as num? ?? 40;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(
                  Icons.directions_bus,
                  color: Color(0xFF1565C0),
                ),
                title: Text(
                  company,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('ID: $busId | Capacity: $capacity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedBus = {
                      'id': busId,
                      'company': company,
                      'capacity': capacity,
                    };
                  });
                  _nextStep(TerminalStep.selectSeat);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeatSelection() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Select Your Seat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 40,
            itemBuilder: (context, index) {
              final seatNum = index + 1;
              final isOccupied = _occupiedSeats.contains(seatNum);
              final isSelected = _selectedSeat == seatNum;

              return GestureDetector(
                onTap: isOccupied
                    ? null
                    : () {
                        setState(() {
                          _selectedSeat = seatNum;
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? Colors.grey[300]
                        : (isSelected ? Colors.green : Colors.white),
                    border: Border.all(
                      color: isOccupied ? Colors.grey : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$seatNum',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isOccupied ? Colors.grey : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedSeat != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _nextStep(TerminalStep.passengerInfo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirm Seat $_selectedSeat'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPassengerInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter full name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter phone number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _nextStep(TerminalStep.payment);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayment() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _summaryRow('Route', _selectedRoute!['route']),
          _summaryRow('Terminal', _selectedTerminal),
          _summaryRow(
            'Bus',
            '${_selectedBus!['company']} (${_selectedBus!['id']})',
          ),
          _summaryRow('Seat Number', '$_selectedSeat'),
          _summaryRow('Fare', '${_selectedRoute!['fare']} ETB'),
          const Divider(height: 40),
          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption(
            title: 'Telebirr',
            color: Colors.green,
            icon: Icons.account_balance_wallet,
            onTap: () => setState(() => _paymentMethod = 'Telebirr'),
            isSelected: _paymentMethod == 'Telebirr',
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            title: 'CBE Birr',
            color: Colors.blue,
            icon: Icons.account_balance,
            onTap: () => setState(() => _paymentMethod = 'CBE Birr'),
            isSelected: _paymentMethod == 'CBE Birr',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _paymentMethod != null ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text('Pay ${_selectedRoute!['fare']} ETB'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildTicket() {
    final ticketData = {
      "ticketId": _ticketId,
      "passenger": _nameController.text,
      "phone": _phoneController.text,
      "bus": _selectedBus!['id'],
      "seat": _selectedSeat.toString(),
      "route": _selectedRoute!['route'],
      "terminal": _selectedTerminal,
      "fare": _selectedRoute!['fare'],
      "payment": _paymentMethod,
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "status": "confirmed",
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Your ticket has been booked.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: ticketData.toString(),
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _ticketDetailRow('Ticket ID', _ticketId),
                _ticketDetailRow('Passenger', _nameController.text),
                _ticketDetailRow('Route', _selectedRoute!['route']),
                _ticketDetailRow('Bus ID', _selectedBus!['id']),
                _ticketDetailRow('Seat', '$_selectedSeat'),
                _ticketDetailRow('Terminal', _selectedTerminal),
                _ticketDetailRow('Fare', '${_selectedRoute!['fare']} ETB'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
