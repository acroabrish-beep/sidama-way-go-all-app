import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mobility_provider.dart';
import '../../models/mobility_models.dart';
import '../../models/city_os_models.dart';
import 'ticket_view_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusTerminalScreen extends StatefulWidget {
  const BusTerminalScreen({super.key});

  @override
  State<BusTerminalScreen> createState() => _BusTerminalScreenState();
}

class _BusTerminalScreenState extends State<BusTerminalScreen> {
  String _selectedTerminal = 'Old Terminal';
  final List<String> _terminals = ['Old Terminal', 'New Terminal'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MobilityProvider>().fetchBusRoutes('old_terminal');
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobility = context.watch<MobilityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intercity Bus Terminal'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: _terminals
                  .map((t) => ButtonSegment(value: t, label: Text(t)))
                  .toList(),
              selected: {_selectedTerminal},
              onSelectionChanged: (val) {
                setState(() => _selectedTerminal = val.first);
                mobility.fetchBusRoutes(val.first == 'Old Terminal'
                    ? 'old_terminal'
                    : 'new_terminal');
              },
            ),
          ),
          Expanded(
            child: mobility.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: mobility.busRoutes.length,
                    itemBuilder: (context, index) {
                      final route = mobility.busRoutes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text('${route.start} → ${route.destination}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Fare: ${route.fare} ETB'),
                          trailing: ElevatedButton(
                            onPressed: () => _bookTicket(context, route),
                            child: const Text('Book'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _bookTicket(BuildContext context, BusRoute route) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ticket = Ticket(
      id: '',
      passengerName: user.email?.split('@')[0] ?? 'Passenger',
      userId: user.uid,
      busId: 'bus_${route.id}',
      routeId: route.id,
      seatNumber: 12, // Mock seat selection for now
      route: '${route.start} - ${route.destination}',
      date: DateTime.now(),
      paymentStatus: 'Paid',
      qrData: 'TICKET-${DateTime.now().millisecondsSinceEpoch}',
    );

    await context.read<MobilityProvider>().bookBusTicket(ticket);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketViewScreen(ticket: ticket),
      ),
    );
  }
}
