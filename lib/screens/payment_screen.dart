import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/firestore_utils.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final methods = [
      {'name': 'Telebirr', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
      {'name': 'CBE Birr', 'icon': Icons.account_balance, 'color': Colors.purple},
      {'name': 'Chapa', 'icon': Icons.payment, 'color': Colors.indigo},
      {'name': 'Cash', 'icon': Icons.money, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF283593),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text("Please login"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnap) {
                double balance = 0;
                if (userSnap.hasData && userSnap.data!.exists) {
                  balance = (userSnap.data!.data() as Map<String, dynamic>)['walletBalance']?.toDouble() ?? 0.0;
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      color: const Color(0xFF283593),
                      child: Column(
                        children: [
                          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
                          Text('${balance.toStringAsFixed(2)} ETB', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showTopUpDialog(context, user.uid),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Money'),
                            style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF283593), backgroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ...methods.map((m) => Card(
                            child: ListTile(
                              leading: Icon(m['icon'] as IconData, color: m['color'] as Color),
                              title: Text(m['name'] as String),
                              trailing: TextButton(onPressed: () {}, child: const Text('Select')),
                            ),
                          )),
                          const SizedBox(height: 24),
                          const Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('payments')
                                .where('userId', isEqualTo: user.uid)
                                .orderBy('timestamp', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, paySnap) {
                              if (!paySnap.hasData) return const Center(child: CircularProgressIndicator());
                              final docs = paySnap.data!.docs;

                              if (docs.isEmpty) return const Text("No recent payments", style: TextStyle(color: Colors.grey));

                              return Column(
                                children: docs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  final ts = FirestoreUtils.parseDateTime(d['timestamp']);
                                  final amount = d['amount'] ?? 0;
                                  final isCredit = d['type'] == 'topup';

                                  return ListTile(
                                    title: Text(d['title'] ?? 'Payment'),
                                    subtitle: Text(ts != null ? DateFormat('dd MMM').format(ts) : 'N/A'),
                                    trailing: Text(
                                      '${isCredit ? "+" : "-"}$amount ETB',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.black),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _showTopUpDialog(BuildContext context, String uid) {
    final amountC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Top Up Wallet"),
        content: TextField(controller: amountC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount (ETB)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final double amount = double.tryParse(amountC.text) ?? 0;
              if (amount > 0) {
                await FirebaseFirestore.instance.collection('payments').add({
                  'userId': uid,
                  'amount': amount,
                  'type': 'topup',
                  'title': 'Wallet Top-up',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'walletBalance': FieldValue.increment(amount),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("Top Up"),
          ),
        ],
      ),
    );
  }
}
