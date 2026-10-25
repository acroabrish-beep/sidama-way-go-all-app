import 'package:flutter/material.dart';

import '../../widgets/tourism_hotels_overview.dart';
import '../../widgets/tourism_overview_tab.dart';
import '../../widgets/tourism_phase2_widgets.dart';
import 'tourist_sites_screen.dart';

class TourismDashboardScreen extends StatefulWidget {
  const TourismDashboardScreen({super.key});

  @override
  State<TourismDashboardScreen> createState() =>
      _TourismDashboardScreenState();
}

class _TourismDashboardScreenState extends State<TourismDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tourism Dashboard'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.landscape), text: 'Sites'),
            Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
            Tab(icon: Icon(Icons.person_pin), text: 'Guides'),
            Tab(icon: Icon(Icons.business_center), text: 'Operators'),
            Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
            Tab(icon: Icon(Icons.car_rental), text: 'Rides'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D40), Color(0xFF00796B)],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TourismOverviewTab(),
              TouristSitesScreen(embedded: true),
              TourismHotelsOverview(),
              Phase2NotMigratedPanel(
                module: 'Tour guides',
                icon: Icons.person_pin,
              ),
              Phase2NotMigratedPanel(
                module: 'Tour operators',
                icon: Icons.business_center,
              ),
              Phase2NotMigratedPanel(
                module: 'Tour bookings',
                icon: Icons.book_online,
              ),
              Phase2NotMigratedPanel(
                module: 'Contract rides',
                icon: Icons.car_rental,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
