import 'package:flutter/material.dart';
import '../../services/city_platform_service.dart';

class TaxiQueueScreen extends StatefulWidget {
  const TaxiQueueScreen({super.key});

  @override
  State<TaxiQueueScreen> createState() => _TaxiQueueScreenState();
}

class _TaxiQueueScreenState extends State<TaxiQueueScreen> {
  final _plateController = TextEditingController();
  bool _isWaiting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Taxi Queue')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Join the city digital queue to receive passenger turn notifications.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(labelText: 'Taxi Plate Number (e.g. HW-34567)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isWaiting ? null : () async {
                setState(() => _isWaiting = true);
                await CityPlatformService().joinTaxiQueue(_plateController.text);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully joined the queue!')));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('JOIN QUEUE'),
            ),
            const SizedBox(height: 48),
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.timer)),
                title: Text('Current Queue Position: 12'),
                subtitle: Text('Est. waiting time: 15 mins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
