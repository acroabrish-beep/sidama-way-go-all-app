import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/role_protected_widget.dart';
import '../widgets/tourism_hotels_overview.dart';
import '../widgets/tourism_overview_tab.dart';
import '../widgets/tourism_phase2_widgets.dart';
import 'tourism/tourist_sites_screen.dart';

class TourismDashboard extends StatefulWidget {
  const TourismDashboard({super.key});

  @override
  State<TourismDashboard> createState() => _TourismDashboardState();
}

class _TourismDashboardState extends State<TourismDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _notMigratedTabs = [
    _NotMigratedTab(
      label: 'Bookings',
      icon: Icons.book_online,
      module: 'Tour bookings',
    ),
    _NotMigratedTab(
      label: 'Guides',
      icon: Icons.person_pin,
      module: 'Tour guides',
    ),
    _NotMigratedTab(
      label: 'Operators',
      icon: Icons.business_center,
      module: 'Tour operators',
    ),
    _NotMigratedTab(
      label: 'Packages',
      icon: Icons.inventory_2,
      module: 'Tour packages',
    ),
    _NotMigratedTab(
      label: 'Contract Rides',
      icon: Icons.car_rental,
      module: 'Contract rides',
    ),
    _NotMigratedTab(
      label: 'Events',
      icon: Icons.event,
      module: 'Events',
    ),
    _NotMigratedTab(
      label: 'Reviews',
      icon: Icons.rate_review,
      module: 'Tour reviews',
    ),
    _NotMigratedTab(
      label: 'Airports',
      icon: Icons.local_airport,
      module: 'Airport pickups',
    ),
    _NotMigratedTab(
      label: 'Alerts',
      icon: Icons.notifications_active,
      module: 'Tourism broadcasts',
    ),
    _NotMigratedTab(
      label: 'Emergency',
      icon: Icons.emergency,
      module: 'Emergency contacts',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3 + _notMigratedTabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.tourismAdmin],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Tourism Control Center',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.tealAccent,
            labelColor: Colors.tealAccent,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              const Tab(icon: Icon(Icons.landscape), text: 'Sites'),
              const Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
              ..._notMigratedTabs.map(
                (tab) => Tab(icon: Icon(tab.icon), text: tab.label),
              ),
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
              children: [
                const TourismOverviewTab(),
                const TouristSitesScreen(embedded: true),
                const TourismHotelsOverview(),
                ..._notMigratedTabs.map(
                  (tab) => Phase2NotMigratedPanel(
                    module: tab.module,
                    icon: tab.icon,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotMigratedTab {
  const _NotMigratedTab({
    required this.label,
    required this.icon,
    required this.module,
  });

  final String label;
  final IconData icon;
  final String module;
}
