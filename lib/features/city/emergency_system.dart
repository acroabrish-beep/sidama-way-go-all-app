import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/city_platform_provider.dart';

class EmergencySystemScreen extends StatelessWidget {
  const EmergencySystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response'),
        backgroundColor: Colors.red.shade900,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _emergencyButton(context, 'Police', Icons.local_police, Colors.blue),
          _emergencyButton(context, 'Ambulance', Icons.medical_services, Colors.red),
          _emergencyButton(context, 'Fire', Icons.fire_truck, Colors.orange),
          _emergencyButton(context, 'Road Assist', Icons.car_repair, Colors.brown),
        ],
      ),
    );
  }

  Widget _emergencyButton(BuildContext context, String type, IconData icon, Color color) {
    return InkWell(
      onTap: () => _sendAlert(context, type),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 50),
            const SizedBox(height: 12),
            Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  void _sendAlert(BuildContext context, String type) async {
    await context.read<CityPlatformProvider>().triggerEmergency(type, const GeoPoint(7.0504, 38.4955));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alert sent to $type department! Stay calm.')),
    );
  }
}
