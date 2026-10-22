import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/firestore_utils.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4527A0),
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text("Please login to view wallet"))
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${balance.toInt()} ETB',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _walletBtn(Icons.add, 'Top Up', () => _showTopUpSheet(context)),
                              _walletBtn(Icons.send, 'Send', () {}),
                              _walletBtn(Icons.history, 'History', () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildQuickPay(context),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Transactions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('payments')
                            .where('userId', isEqualTo: user.uid)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, transSnap) {
                          if (!transSnap.hasData) return const Center(child: CircularProgressIndicator());
                          final docs = transSnap.data!.docs;

                          if (docs.isEmpty) return const Center(child: Text("No transactions yet"));

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final t = docs[i].data() as Map<String, dynamic>;
                              final bool isCredit = t['type'] == 'topup' || t['amount'] > 0; // Simplified logic
                              final ts = FirestoreUtils.parseDateTime(t['timestamp']);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCredit
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    child: Icon(
                                      isCredit ? Icons.add_circle : Icons.payment,
                                      color: isCredit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    t['title'] ?? t['reason'] ?? 'Transaction',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(ts != null ? DateFormat('dd MMM, HH:mm').format(ts) : 'N/A'),
                                  trailing: Text(
                                    '${t['amount']} ETB',
                                    style: TextStyle(
                                      color: isCredit ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _walletBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickPay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Pay Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _payItem(context, 'Taxi', Icons.local_taxi, Colors.orange),
              _payItem(context, 'Bus', Icons.directions_bus, Colors.blue),
              _payItem(context, 'Hotel', Icons.hotel, Colors.purple),
              _payItem(context, 'Medicine', Icons.medication, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payItem(BuildContext context, String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _methodTile(context, 'Telebirr', 'assets/images/telebirr.png', Colors.blue),
            _methodTile(context, 'CBE Birr', 'assets/images/cbe.png', Colors.purple),
            _methodTile(context, 'Chapa (Card/Other)', 'assets/images/chapa.png', Colors.green),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(BuildContext context, String name, String asset, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.account_balance_wallet, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name top-up is not connected yet. Top-ups require a live payment provider configured on the server.',
            ),
          ),
        );
      },
    );
  }
}
