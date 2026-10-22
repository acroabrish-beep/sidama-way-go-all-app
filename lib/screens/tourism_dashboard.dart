import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/glass_card.dart';
import 'crud_list_screen.dart';
import '../models/tourism_models.dart';
import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart';

class TourismDashboard extends StatefulWidget {
  const TourismDashboard({super.key});

  @override
  State<TourismDashboard> createState() => _TourismDashboardState();
}

class _TourismDashboardState extends State<TourismDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
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
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.book_online), text: 'Bookings'),
              Tab(icon: Icon(Icons.person_pin), text: 'Guides'),
              Tab(icon: Icon(Icons.business_center), text: 'Operators'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Packages'),
              Tab(icon: Icon(Icons.car_rental), text: 'Contract Rides'),
              Tab(icon: Icon(Icons.landscape), text: 'Sites'),
              Tab(icon: Icon(Icons.event), text: 'Events'),
              Tab(icon: Icon(Icons.rate_review), text: 'Reviews'),
              Tab(icon: Icon(Icons.local_airport), text: 'Airports'),
              Tab(icon: Icon(Icons.notifications_active), text: 'Alerts'),
              Tab(icon: Icon(Icons.emergency), text: 'Emergency'),
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
                _OverviewTab(),
                _BookingsTab(),
                _GuidesTab(),
                _OperatorsTab(),
                _PackagesTab(),
                _ContractRidesTab(),
                _AttractionsTab(),
                _EventsTab(),
                _ReviewsTab(),
                _AirportPickupTab(),
                _AlertsTab(),
                _EmergencyTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatGrid(),
        const SizedBox(height: 24),
        const Text(
          'Visitor Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalyticsChart(),
        const SizedBox(height: 24),
        const Text(
          'Revenue Trends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRevenueChart(),
      ],
    );
  }

  Widget _buildStatGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CityOSCollection.analytics)
          .doc('tourism')
          .snapshots(),
      builder: (context, snapshot) {
        final stats = snapshot.hasData
            ? TourismSummaryStats.fromFirestore(snapshot.data!)
            : null;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _statCard(
              'Total Bookings',
              stats?.totalBookings.toString() ?? '...',
              Icons.book_online,
              Colors.tealAccent,
            ),
            _statCard(
              'Tour Guides',
              stats?.tourGuides.toString() ?? '...',
              Icons.person_pin,
              Colors.blueAccent,
            ),
            _statCard(
              'Operators',
              stats?.operators.toString() ?? '...',
              Icons.business_center,
              Colors.orangeAccent,
            ),
            _statCard(
              'Contract Rides',
              stats?.contractRides.toString() ?? '...',
              Icons.car_rental,
              Colors.purpleAccent,
            ),
            _statCard(
              'Revenue',
              '${(stats?.totalRevenue ?? 0 / 1000).toStringAsFixed(1)}k ETB',
              Icons.payments,
              Colors.greenAccent,
            ),
            _statCard(
              'Site Visitors',
              stats?.siteVisitors.toString() ?? '...',
              Icons.people,
              Colors.yellowAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 1),
                FlSpot(2, 4),
                FlSpot(3, 2),
                FlSpot(4, 5),
                FlSpot(5, 3),
                FlSpot(6, 4),
              ],
              isCurved: true,
              color: Colors.tealAccent,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.tealAccent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [BarChartRodData(toY: 8, color: Colors.greenAccent)],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [BarChartRodData(toY: 10, color: Colors.greenAccent)],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [BarChartRodData(toY: 14, color: Colors.greenAccent)],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [BarChartRodData(toY: 15, color: Colors.greenAccent)],
            ),
            BarChartGroupData(
              x: 4,
              barRods: [BarChartRodData(toY: 13, color: Colors.greenAccent)],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildListView(
      'tourist_bookings',
      'title',
      'status',
      Icons.book_online,
    );
  }
}

class _GuidesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildApprovalView(
      'tour_guides',
      'fullName',
      'languages',
      Icons.person_pin,
    );
  }
}

class _OperatorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildApprovalView(
      'tour_operators',
      'companyName',
      'phone',
      Icons.business_center,
    );
  }
}

class _PackagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildCRUDView(context, 'tour_packages', 'Packages', [
      'packageName',
      'destination',
      'price',
      'duration',
      'description',
    ], Icons.inventory_2);
  }
}

class _ContractRidesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildListView(
      'contract_rides',
      'vehicleType',
      'status',
      Icons.car_rental,
    );
  }
}

class _AttractionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildCRUDView(context, 'tourist_sites', 'Attractions', [
      'name',
      'category',
      'location',
      'description',
    ], Icons.landscape);
  }
}

class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildCRUDView(context, 'events', 'Events', [
      'title',
      'location',
      'date',
      'description',
    ], Icons.event);
  }
}

class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildListView(
      'tour_reviews',
      'userName',
      'comment',
      Icons.rate_review,
    );
  }
}

class _AirportPickupTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildListView(
      'airport_pickups',
      'type',
      'status',
      Icons.local_airport,
    );
  }
}

class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Send Tourism Notification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
              ),
              child: const Text(
                'BROADCAST',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildCRUDView(context, 'emergency_contacts', 'Emergency', [
      'name',
      'phone',
      'type',
    ], Icons.emergency);
  }
}

Widget _buildListView(
  String collection,
  String titleField,
  String subField,
  IconData icon,
) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: ListTile(
                leading: Icon(icon, color: Colors.tealAccent),
                title: Text(
                  data[titleField] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  data[subField]?.toString() ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildApprovalView(
  String collection,
  String titleField,
  String subField,
  IconData icon,
) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection(collection).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: ListTile(
                leading: Icon(icon, color: Colors.tealAccent),
                title: Text(
                  data[titleField] ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  data[subField]?.toString() ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () => docs[i].reference.update({
                              'status': 'approved',
                            }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => docs[i].reference.update({
                              'status': 'rejected',
                            }),
                          ),
                        ],
                      )
                    : Chip(
                        label: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: status == 'approved'
                            ? Colors.green
                            : Colors.red,
                      ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildCRUDView(
  BuildContext context,
  String collection,
  String title,
  List<String> fields,
  IconData addIcon,
) {
  return Stack(
    children: [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: ListTile(
                    title: Text(
                      d[fields[0]]?.toString() ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      d[fields[1]]?.toString() ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CRUDListScreen(
                            collection: collection,
                            title: title,
                            fields: fields,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CRUDListScreen(
                collection: collection,
                title: title,
                fields: fields,
              ),
            ),
          ),
          backgroundColor: Colors.tealAccent,
          child: Icon(addIcon, color: Colors.teal),
        ),
      ),
    ],
  );
}
