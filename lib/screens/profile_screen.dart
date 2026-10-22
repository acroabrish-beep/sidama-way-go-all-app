import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'payment_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';

import '../utils/language_provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<custom_auth.AuthProvider>(context);
    final userData = authProvider.userModel;

    final items = [
      {'icon': Icons.history, 'label': lang.translate('trip_history'), 'color': 0xFF2E7D32, 'screen': null},
      {'icon': Icons.payment, 'label': lang.translate('payment'), 'color': 0xFF1565C0, 'screen': const PaymentScreen()},
      {'icon': Icons.map, 'label': lang.translate('explore'), 'color': 0xFF00695C, 'screen': const MapScreen()},
      {'icon': Icons.notifications, 'label': lang.translate('notifications'), 'color': 0xFF4527A0, 'screen': const NotificationsScreen()},
      {'icon': Icons.language, 'label': lang.translate('language'), 'color': 0xFF00695C, 'screen': null, 'isLanguage': true},
      {'icon': Icons.help, 'label': lang.translate('help_support'), 'color': 0xFF37474F, 'screen': null},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(
          lang.translate('profile'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 12),
                Text(
                  userData?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Text(
                  'Hawassa, Sidama',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox('${userData?.walletBalance.toInt() ?? 0}', 'ETB'),
                    _statBox(userData?.role.name.toUpperCase() ?? 'CITIZEN', 'ROLE'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(item['color'] as int).withValues(alpha: 0.1),
                        child: Icon(item['icon'] as IconData, color: Color(item['color'] as int)),
                      ),
                      title: Text(item['label'] as String),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (item['isLanguage'] == true) {
                          _showLanguageDialog(context, lang);
                        } else if (item['screen'] != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => item['screen'] as Widget));
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildHistorySection(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      lang.translate('sign_out'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: user.uid).limit(3).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>? ?? {};
                final route = d['route'] as String? ?? 'Bus Booking';
                final status = d['status'] as String? ?? '';
                final fare = d['fare'] as num? ?? 0;
                return ListTile(
                  dense: true,
                  title: Text(route),
                  subtitle: Text(status),
                  trailing: Text('$fare ETB'),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                lang.setLanguage('en');
                Navigator.pop(context);
              },
              trailing: lang.currentLang == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
            ),
            ListTile(
              title: const Text('አማርኛ (Amharic)'),
              onTap: () {
                lang.setLanguage('am');
                Navigator.pop(context);
              },
              trailing: lang.currentLang == 'am' ? const Icon(Icons.check, color: Colors.green) : null,
            ),
            ListTile(
              title: const Text('Sidaamu Afoo'),
              onTap: () {
                lang.setLanguage('sid');
                Navigator.pop(context);
              },
              trailing: lang.currentLang == 'sid' ? const Icon(Icons.check, color: Colors.green) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
