import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTRACTOR HUB'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CATEGORIES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildCategoriesGrid(),
            const SizedBox(height: 32),
            const Text('TOP RATED PROVIDERS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildProvidersList(),
            const SizedBox(height: 32),
            const Text('REQUEST QUOTATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildQuotationCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'icon': Icons.electrical_services, 'label': 'Electricians'},
      {'icon': Icons.plumbing, 'label': 'Plumbers'},
      {'icon': Icons.build_rounded, 'label': 'Mechanics'},
      {'icon': Icons.format_paint, 'label': 'Painters'},
      {'icon': Icons.chair_rounded, 'label': 'Carpenters'},
      {'icon': Icons.engineering, 'label': 'Engineers'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return Container(
          decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat['icon'] as IconData, color: Colors.deepOrangeAccent),
              const SizedBox(height: 8),
              Text(cat['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProvidersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('marketplace_providers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading providers');
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No verified providers found.', style: TextStyle(color: Colors.grey));

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = data['name'] as String? ?? 'Provider';
            final category = data['category'] as String? ?? 'General';
            final rating = (data['rating'] as num? ?? 5.0).toString();
            final jobsDone = data['jobsDone'] as num? ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.person, color: Colors.white)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$category • $rating ⭐'),
                trailing: Text('$jobsDone jobs', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuotationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withValues(alpha: 0.3))),
      child: Column(
        children: [
          const Text('Need a custom project estimate?', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Submit your project details and get quotes from verified contractors.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _showQuotationDialog(context), child: const Text('GET FREE QUOTE')),
        ],
      ),
    );
  }

  void _showQuotationDialog(BuildContext context) {
    final descC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Quotation'),
        content: TextField(controller: descC, decoration: const InputDecoration(labelText: 'Describe your project')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = Provider.of<custom_auth.AuthProvider>(context, listen: false).userModel;
                await FirebaseFirestore.instance.collection('quotation_requests').add({
                  'userId': user?.uid,
                  'userName': user?.fullName,
                  'description': descC.text,
                  'status': 'Pending',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation request submitted!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
