import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'ai_assistant_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PHARMACY DELIVERY')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPrescriptionUpload(),
                const SizedBox(height: 32),
                const Text('AVAILABLE MEDICINES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildMedicineListStream(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text('Ask AI', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMedicineListStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) => (doc['name'] as String).toLowerCase().contains(_searchQuery)).toList();
        }

        if (docs.isEmpty) return const Text('No medicines found matching your search.');

        return Column(
          children: docs.map<Widget>((doc) {
            return _buildMedicineItem(context, doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMedicineItem(BuildContext context, DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    final name = m['name'] as String? ?? 'Medicine';
    final quantity = m['quantity'] as num? ?? 0;
    final price = m['price'] as num? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Stock: $quantity'),
        trailing: Text('$price ETB', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        onTap: () => _orderMedicine(context, doc),
      ),
    );
  }

  void _orderMedicine(BuildContext context, DocumentSnapshot medDoc) {
    final m = medDoc.data() as Map<String, dynamic>? ?? {};
    final medName = m['name'] as String? ?? 'Medicine';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order $medName'),
        content: const Text('Do you want to order this medicine? Delivery takes 30-60 mins.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final user = Provider.of<AuthProvider>(context, listen: false).userModel;
              await FirebaseFirestore.instance.collection('medicine_orders').add({
                'medicineId': medDoc.id,
                'medicineName': medName,
                'customerName': user?.fullName ?? 'Customer',
                'customerPhone': user?.phone ?? 'N/A',
                'status': 'pending',
                'userId': user?.uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed!')));
            },
            child: const Text('ORDER NOW'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionUpload() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF009624)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text('UPLOAD PRESCRIPTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Get medicines delivered to your door', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green),
            child: const Text('CHOOSE FILE'),
          ),
        ],
      ),
    );
  }
}
