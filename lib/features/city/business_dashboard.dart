import 'package:flutter/material.dart';
import '../../services/extended_platform_service.dart';
import '../../models/extended_city_models.dart';

class BusinessDashboard extends StatelessWidget {
  final String businessId;
  final String businessType; // Hotel, Restaurant, Pharmacy

  const BusinessDashboard({super.key, required this.businessId, required this.businessType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$businessType Dashboard')),
      body: StreamBuilder<List<CityOrder>>(
        stream: ExtendedPlatformService().getBusinessOrders(businessId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatOverview(orders),
                const SizedBox(height: 24),
                const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final order = orders[i];
                      return Card(
                        child: ListTile(
                          title: Text('Order #${order.id.substring(0, 5)}'),
                          subtitle: Text('Status: ${order.status}'),
                          trailing: Text('${order.totalAmount} ETB'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatOverview(List<CityOrder> orders) {
    double revenue = orders.fold(0, (sum, item) => sum + item.totalAmount);
    return Row(
      children: [
        _statItem('Orders', '${orders.length}', Colors.blue),
        const SizedBox(width: 12),
        _statItem('Revenue', '${revenue.toStringAsFixed(0)} ETB', Colors.green),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
