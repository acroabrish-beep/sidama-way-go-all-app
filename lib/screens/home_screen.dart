import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom_auth;
import 'terminal_screen.dart';
import 'smart_city_map_screen.dart';
import 'profile_screen.dart';
import 'city_taxi_screen.dart';
import 'emergency_screen.dart';
import 'tourism/tourism_home_screen.dart';
import 'healthcare_screen.dart';
import 'pharmacy_screen.dart';
import 'food_screen.dart';
import 'wallet_screen.dart';
import 'settings_screen.dart';
import 'eco_shine_screen.dart';
import 'ai_assistant_screen.dart';
import 'taxi_demo_screen.dart';
import '../utils/language_provider.dart';

import 'digital_id_screen.dart';
import 'citizen_reporting_screen.dart';
import 'hotel_screen.dart';
import 'notifications_screen.dart';
import '../models/user_model.dart';
import 'station/driver_station_screen.dart';
import 'station/station_tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    final List<Widget> pages = [
      const _MainHub(),
      const TerminalScreen(),
      const FoodScreen(),
      const TourismHomeScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: lang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.directions_bus), label: lang.t('bus')),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant), label: lang.t('food')),
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: lang.t('tourist')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: lang.t('profile')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
        backgroundColor: Colors.red,
        tooltip: lang.t('emergency'),
        child: const Icon(Icons.emergency, color: Colors.white),
      ),
    );
  }
}

class _MainHub extends StatelessWidget {
  const _MainHub();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context);
    final user = authProvider.userModel;
    final lang = Provider.of<LanguageProvider>(context);
    final isStationOperator =
        user?.role == UserRole.taxiDriver ||
        user?.role == UserRole.taxiAdmin ||
        user?.role == UserRole.superAdmin;

    final List<Map<String, dynamic>> services = [
      {'title': lang.t('city_map'), 'icon': Icons.map, 'color': 0xFF1976D2, 'screen': const SmartCityMapScreen()},
      {'title': lang.t('bus_terminal'), 'icon': Icons.directions_bus_filled, 'color': 0xFF1565C0, 'screen': const TerminalScreen()},
      {'title': lang.t('city_taxi'), 'icon': Icons.local_taxi, 'color': 0xFFE65100, 'screen': const CityTaxiScreen()},
      {'title': 'Station Tickets', 'icon': Icons.confirmation_number, 'color': 0xFF00695C, 'screen': const StationTicketsScreen()},
      if (isStationOperator)
        {'title': 'Driver Station', 'icon': Icons.qr_code_scanner, 'color': 0xFF1B5E20, 'screen': const DriverStationScreen()},
      {'title': 'Taxi Demo', 'icon': Icons.play_circle_fill, 'color': 0xFFD32F2F, 'screen': const TaxiDemoScreen()},
      {'title': lang.t('emergency'), 'icon': Icons.emergency, 'color': 0xFFC62828, 'screen': const EmergencyScreen()},
      {'title': lang.t('tourist_guide'), 'icon': Icons.map, 'color': 0xFF00897B, 'screen': const TourismHomeScreen()},
      {'title': 'Hotels', 'icon': Icons.hotel, 'color': 0xFF6A1B9A, 'screen': const HotelScreen()},
      {'title': lang.t('healthcare'), 'icon': Icons.local_hospital, 'color': 0xFFD32F2F, 'screen': const HealthcareScreen()},
      {'title': lang.t('pharmacy'), 'icon': Icons.local_pharmacy, 'color': 0xFF388E3C, 'screen': const PharmacyScreen()},
      {'title': lang.t('food'), 'icon': Icons.restaurant, 'color': 0xFFF57C00, 'screen': const FoodScreen()},
      {'title': lang.t('eco_shine'), 'icon': Icons.eco, 'color': 0xFF00695C, 'screen': const EcoShineScreen()},
      {'title': lang.t('wallet'), 'icon': Icons.account_balance_wallet, 'color': 0xFF4527A0, 'screen': const WalletScreen()},
      {'title': 'Digital ID', 'icon': Icons.qr_code, 'color': 0xFF2E7D32, 'screen': const DigitalIDScreen()},
      {'title': 'City Report', 'icon': Icons.report_problem, 'color': 0xFFD84315, 'screen': const CitizenReportingScreen()},
      {'title': lang.t('settings'), 'icon': Icons.settings, 'color': 0xFF455A64, 'screen': const SettingsScreen()},
      {'title': lang.t('ai_assistant'), 'icon': Icons.smart_toy, 'color': 0xFF6A1B9A, 'screen': const AiAssistantScreen()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(lang.t('platform_name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          _buildNotificationIcon(context),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.t('hello')}, ${user?.fullName ?? 'Citizen'}! 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    lang.t('where_to_go'),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCitizenAnnouncementBanner(),
                  const SizedBox(height: 24),
                  Text(lang.t('services'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final s = services[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => s['screen'])),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(s['color']).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(s['icon'], color: Color(s['color']), size: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['title'],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(lang.t('announcements'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).limit(3).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>? ?? {};
                          return _announcementCard(
                            d['title'] as String? ?? 'City Update',
                            d['message'] as String? ?? '',
                            _getCategoryColor(d['category'] as String?),
                          );
                        }).toList(),
                      );
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenAnnouncementBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements')
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No city announcements at the moment.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ));
        }
        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CITY ANNOUNCEMENTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: PageView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>? ?? {};
                  final color = _getCategoryColor(d['category'] as String?);
                  return Card(
                    color: color.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.3))),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.campaign, color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(d['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(d['message'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final authProvider = Provider.of<custom_auth.AuthProvider>(context);
    final user = authProvider.userModel;
    if (user == null) return const SizedBox.shrink();

    int unreadCount = user.unreadNotifications;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
            ),
          )
      ],
    );
  }

  Color _getCategoryColor(String? cat) {
    switch (cat) {
      case 'Emergency': return Colors.red;
      case 'Traffic': return Colors.orange;
      case 'Tourism': return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _announcementCard(String title, String desc, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.campaign, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
      ),
    );
  }
}
