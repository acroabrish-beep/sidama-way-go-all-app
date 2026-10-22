import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/smart_city_provider.dart';

import '../../models/city_os_models.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IntercityTerminalScreen extends StatefulWidget {
  const IntercityTerminalScreen({super.key});

  @override
  State<IntercityTerminalScreen> createState() => _IntercityTerminalScreenState();
}

class _IntercityTerminalScreenState extends State<IntercityTerminalScreen> {
  String _selectedTerminal = 'old'; // 'old' or 'new'
  BusVehicle? _selectedBus;
  int? _selectedSeat;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartCityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Terminal Booking'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTerminalSelector(),
          Expanded(
            child: _selectedBus == null ? _buildBusList(provider) : _buildSeatSelection(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'old', label: Text('Old Terminal'), icon: Icon(Icons.history)),
          ButtonSegment(value: 'new', label: Text('New Terminal'), icon: Icon(Icons.new_releases)),
        ],
        selected: {_selectedTerminal},
        onSelectionChanged: (val) {
          setState(() {
            _selectedTerminal = val.first;
            _selectedBus = null;
            _selectedSeat = null;
          });
          context.read<SmartCityProvider>().fetchBuses(_selectedTerminal);
        },
      ),
    );
  }

  Widget _buildBusList(SmartCityProvider provider) {
    if (provider.availableBuses.isEmpty) {
      return const Center(child: Text('No buses available for this terminal.'));
    }

    return ListView.builder(
      itemCount: provider.availableBuses.length,
      itemBuilder: (context, index) {
        final bus = provider.availableBuses[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.directions_bus, color: Color(0xFF2E7D32)),
            title: Text('Bus: ${bus.plateNumber}'),
            subtitle: Text('Driver: ${bus.driverName}\nRoute: ${bus.routeId}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedBus = bus),
          ),
        );
      },
    );
  }

  Widget _buildSeatSelection(SmartCityProvider provider) {
    final bus = _selectedBus!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Select Seat for Bus ${bus.plateNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: bus.totalSeats,
              itemBuilder: (context, index) {
                final seatNum = index + 1;
                final isOccupied = bus.occupiedSeats.contains(seatNum);
                final isSelected = _selectedSeat == seatNum;

                return GestureDetector(
                  onTap: isOccupied ? null : () => setState(() => _selectedSeat = seatNum),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOccupied ? Colors.grey : (isSelected ? Colors.green : Colors.white),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('$seatNum', style: TextStyle(color: isSelected || isOccupied ? Colors.white : Colors.black))),
                  ),
                );
              },
            ),
          ),
          if (_selectedSeat != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: () => _confirmBooking(provider),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('PROCEED TO BOOKING'),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmBooking(SmartCityProvider provider) async {
    final ticket = Ticket(
      id: '',
      passengerName: provider.currentUser?.fullName ?? 'Passenger',
      userId: provider.currentUser?.uid ?? '',
      route: _selectedBus!.routeId,
      busId: _selectedBus!.id,
      routeId: _selectedBus!.routeId,
      seatNumber: _selectedSeat!,
      date: DateTime.now(),
      paymentStatus: 'paid',
      qrData: 'VER-${DateTime.now().millisecondsSinceEpoch}',
    );

    await provider.bookTicket(ticket);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Booking Confirmed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your ticket has been generated successfully.'),
            const SizedBox(height: 20),
            QrImageView(data: ticket.qrData, size: 200),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
    setState(() {
      _selectedBus = null;
      _selectedSeat = null;
    });
  }
}
