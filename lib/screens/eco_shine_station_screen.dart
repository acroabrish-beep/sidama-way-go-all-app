import 'package:flutter/material.dart';

class EcoShineStationScreen extends StatelessWidget {
  const EcoShineStationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zemenaw Eco-Shine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Station Status: Piazza Hub', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://images.unsplash.com/photo-1509391366360-2e959784a276?q=80&w=1000&auto=format&fit=crop',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _SolarStatusCard()),
                SizedBox(width: 16),
                Expanded(child: _WaterStatusCard()),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Automated Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Customers in Queue: 2'),
                subtitle: Text('Estimated wait: 10 mins'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Eco-Tech Infrastructure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _infraImage('https://images.unsplash.com/photo-1613665813446-82a78c468a1d?q=80&w=500&auto=format&fit=crop'),
                  const SizedBox(width: 12),
                  _infraImage('https://images.unsplash.com/photo-1544724569-5f546fd6f2b5?q=80&w=500&auto=format&fit=crop'),
                  const SizedBox(width: 12),
                  _infraImage('https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=500&auto=format&fit=crop'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Card(
              child: Column(
                children: [
                  ListTile(title: Text('Standard Shine'), trailing: Text('25 ETB')),
                  Divider(height: 0),
                  ListTile(title: Text('Deep Clean & Wax'), trailing: Text('50 ETB')),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Slot Booked! You are #3 in queue.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Book My Shine Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infraImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.network(url, width: 160, fit: BoxFit.cover),
    );
  }
}

class _SolarStatusCard extends StatelessWidget {
  const _SolarStatusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.amber, size: 40),
            const SizedBox(height: 8),
            const Text('Solar Energy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 8,
                    color: Colors.amber,
                    backgroundColor: Colors.amber.withValues(alpha: 0.1),
                  ),
                ),
                const Text('85%', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Storage Status', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _WaterStatusCard extends StatelessWidget {
  const _WaterStatusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.opacity, color: Colors.blue, size: 40),
            const SizedBox(height: 8),
            const Text('Recycling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.92, color: Colors.blue, minHeight: 8),
            const SizedBox(height: 12),
            const Text('92% Efficiency', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Filtered Water', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
