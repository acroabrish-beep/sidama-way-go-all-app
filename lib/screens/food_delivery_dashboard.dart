import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/firestore_service.dart';
import '../widgets/ai_insights_card.dart';

class FoodDeliveryDashboard extends StatefulWidget {
  const FoodDeliveryDashboard({super.key});

  @override
  State<FoodDeliveryDashboard> createState() => _FoodDeliveryDashboardState();
}

class _FoodDeliveryDashboardState extends State<FoodDeliveryDashboard> {
  final FirestoreService _fs = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kitchen Command"),
          backgroundColor: const Color(0xFFAD1457),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Restaurants"),
              Tab(text: "Menus"),
              Tab(text: "Live Orders"),
              Tab(text: "Drivers"),
              Tab(text: "AI Assistant"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRestaurantsTab(),
            _buildMenusTab(),
            _buildOrdersTab(),
            _buildDriversTab(),
            _buildAIAssistantTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddRestaurantDialog,
          backgroundColor: const Color(0xFFAD1457),
          child: const Icon(Icons.add_business),
        ),
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: AIInsightsCard(dashboardContext: 'food_delivery', title: '🤖 Food Delivery AI Insights'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.getCollectionStream('restaurants'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.pink),
                    title: Text(d['name']),
                    subtitle: Text(d['type'] ?? 'Fast Food'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddRestaurantDialog(id: docs[i].id, data: d)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _fs.deleteDocument('restaurants', docs[i].id)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(onPressed: () => _showAddRestaurantDialog(), icon: const Icon(Icons.add_business), label: const Text("ADD RESTAURANT")),
        )
      ],
    );
  }

  Widget _buildMenusTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _fs.getCollectionStream('menus'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(d['itemName'] ?? 'Menu Item'),
                    subtitle: Text("${d['restaurantName']} • ${d['price']} ETB"),
                    trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => docs[i].reference.delete()),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(onPressed: _showAddMenuDialog, icon: const Icon(Icons.add), label: const Text("ADD MENU ITEM")),
        )
      ],
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('food_orders').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No active orders'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final status = d['status'] ?? 'pending';
            final items = (d['items'] as List?)?.map((it) => "${it['quantity']}x ${it['name']}").join(", ") ?? 'No items';

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(d['restaurantName'] ?? 'Restaurant'),
                subtitle: Text('Order: $items\nBy: ${d['userName'] ?? 'Customer'}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'pending') _statusBtn(docs[i], 'preparing', Colors.yellow),
                    if (status == 'preparing') _statusBtn(docs[i], 'out_for_delivery', Colors.orange),
                    if (status == 'out_for_delivery') _statusBtn(docs[i], 'delivered', Colors.green),
                    Text(status.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusBtn(DocumentSnapshot doc, String next, Color color) {
    return ElevatedButton(
      onPressed: () => doc.reference.update({'status': next}),
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(60, 25)),
      child: Text(next.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.black)),
    );
  }
  Widget _buildDriversTab() => const Center(child: Text("Active Delivery Fleet Registry"));

  Widget _buildAIAssistantTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.fastfood, size: 64, color: Colors.pink),
          const SizedBox(height: 16),
          const Text("Food Logistics AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("AI Insight: Lunch peak detected at Haile Resort Restaurant. Current average prep time is 25 minutes. Recommend assigning 2 extra motorcycles for express delivery within Hawassa city center."),
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: () => _flutterTts.speak("Lunch peak at Haile Resort. Assign extra motorcycles for delivery."), child: const Text("Optimize Fleet Assignment"))
        ],
      ),
    );
  }

  void _showAddMenuDialog() {
    final resC = TextEditingController();
    final itemC = TextEditingController();
    final priceC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Menu Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: resC, decoration: const InputDecoration(labelText: "Restaurant Name")),
            TextField(controller: itemC, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (ETB)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            _fs.addDocument('menus', {
              'restaurantName': resC.text,
              'itemName': itemC.text,
              'price': int.parse(priceC.text),
              'timestamp': FieldValue.serverTimestamp(),
            });
            Navigator.pop(context);
          }, child: const Text("Save")),
        ],
      ),
    );
  }

  void _showAddRestaurantDialog({String? id, Map<String, dynamic>? data}) {
    final nameC = TextEditingController(text: data?['name']);
    final typeC = TextEditingController(text: data?['type']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? "Register Restaurant" : "Update Restaurant"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: "Restaurant Name")),
            TextField(controller: typeC, decoration: const InputDecoration(labelText: "Cuisine Type")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            final payload = {
              'name': nameC.text,
              'type': typeC.text,
              'isActive': true,
              'timestamp': FieldValue.serverTimestamp(),
            };
            if (id == null) {
              _fs.addDocument('restaurants', payload);
            } else {
              _fs.updateDocument('restaurants', id, payload);
            }
            Navigator.pop(context);
          }, child: Text(id == null ? "Register" : "Update")),
        ],
      ),
    );
  }
}
