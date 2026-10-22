import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mobility_provider.dart';

class CityTaxiScreen extends StatefulWidget {
  const CityTaxiScreen({super.key});

  @override
  State<CityTaxiScreen> createState() => _CityTaxiScreenState();
}

class _CityTaxiScreenState extends State<CityTaxiScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MobilityProvider>().fetchTaxiRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobility = context.watch<MobilityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hawassa City Taxi'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: mobility.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: mobility.taxiRoutes.length,
              itemBuilder: (context, index) {
                final route = mobility.taxiRoutes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.local_taxi, color: Colors.black),
                    ),
                    title: Text('${route.from} → ${route.to}'),
                    subtitle: Text('Fixed Fare: ${route.fare} ETB'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Booking flow for fixed taxi routes
                    },
                  ),
                );
              },
            ),
    );
  }
}
