import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/smart_city_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartCityProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildEmergencyButton(context, provider, authProvider, 'AMBULANCE', Icons.medical_services, Colors.red),
          _buildEmergencyButton(context, provider, authProvider, 'POLICE', Icons.local_police, Colors.blue),
          _buildEmergencyButton(context, provider, authProvider, 'FIRE', Icons.fire_truck, Colors.orange),
          _buildEmergencyButton(context, provider, authProvider, 'ROAD ASSIST', Icons.car_repair, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context, SmartCityProvider provider, AuthProvider auth, String type, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _triggerEmergency(context, provider, auth, type),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 10),
            Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _triggerEmergency(BuildContext context, SmartCityProvider provider, AuthProvider auth, String type) async {
    // In a real app, get real GPS coordinates
    const location = GeoPoint(7.0504, 38.4955);
    final userName = auth.userModel?.fullName ?? 'Anonymous';

    await provider.triggerSOS(type, location, userName);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type request sent! Help is on the way.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
