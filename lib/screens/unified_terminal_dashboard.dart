import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crud_list_screen.dart';
import 'terminal_qr_scanner.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart';

class UnifiedTerminalDashboard extends StatefulWidget {
  final String? terminalId;
  const UnifiedTerminalDashboard({super.key, this.terminalId});

  @override
  State<UnifiedTerminalDashboard> createState() =>
      _UnifiedTerminalDashboardState();
}

class _UnifiedTerminalDashboardState extends State<UnifiedTerminalDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String get _terminalName {
    if (widget.terminalId == 'old_terminal') return 'Hawassa Old Terminal';
    if (widget.terminalId == 'new_terminal') return 'Hawassa New Terminal';
    return 'Smart Terminal Network';
  }

  bool get _isScoped =>
      widget.terminalId != null &&
      widget.terminalId!.isNotEmpty &&
      widget.terminalId != 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _collection(String collection) {
    final query = FirebaseFirestore.instance.collection(collection);
    if (_isScoped) {
      return query.where('terminal_id', isEqualTo: widget.terminalId);
    }
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.oldTerminalAdmin, UserRole.newTerminalAdmin],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isScoped
                ? '$_terminalName Control Center'
                : 'Unified Terminal Command Center',
          ),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.route), text: 'Operations'),
              Tab(icon: Icon(Icons.manage_accounts), text: 'Management'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI Assistant'),
              Tab(icon: Icon(Icons.qr_code), text: 'Verification'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildOperationsTab(),
            _buildManagementTab(),
            _buildAiTab(),
            _buildVerificationTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _headerCard(),
        const SizedBox(height: 16),
        AIInsightsCard(
          dashboardContext: widget.terminalId ?? 'terminal',
          title: widget.terminalId == 'old_terminal'
              ? '🤖 Old Terminal AI Insights'
              : widget.terminalId == 'new_terminal'
                  ? '🤖 New Terminal AI Insights'
                  : '🤖 Terminal AI Insights',
        ),
        const SizedBox(height: 16),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc(widget.terminalId != null ? 'terminal_${widget.terminalId}' : 'terminal_summary').snapshots(),
          builder: (context, snapshot) {
            final stats = snapshot.hasData ? TerminalSummaryStats.fromFirestore(snapshot.data!) : null;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _statCard(
                  'Active Buses',
                  stats?.activeBuses.toString() ?? '...',
                  Icons.directions_bus,
                  Colors.blue,
                ),
                _statCard(
                  'Delayed Buses',
                  stats?.delayedBuses.toString() ?? '...',
                  Icons.access_time,
                  Colors.red,
                ),
                _statCard(
                  'Passengers Today',
                  stats?.passengersToday.toString() ?? '...',
                  Icons.people,
                  Colors.green,
                ),
                _statCard(
                  'Revenue',
                  '${stats?.todayRevenue.toInt() ?? 0} ETB',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Live Route Snapshot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _collection('terminal_routes').snapshots(),
          builder: (context, snapshot) {
            final routes = snapshot.data?.docs ?? [];
            return Column(
              children: routes.take(5).map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.route, color: Colors.indigo),
                    title: Text(data['route'] ?? 'Route'),
                    subtitle: Text(
                      '${data['origin'] ?? ''} → ${data['destination'] ?? ''}',
                    ),
                    trailing: Text('${data['fare'] ?? 0} ETB'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOperationsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection(CityOSCollection.analytics).doc(widget.terminalId != null ? 'terminal_${widget.terminalId}' : 'terminal_summary').snapshots(),
      builder: (context, snapshot) {
        final stats = snapshot.hasData ? TerminalSummaryStats.fromFirestore(snapshot.data!) : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Live Terminal Dashboard'),
            const SizedBox(height: 8),
            _metricTile(
              'Live Departures',
              '${stats?.activeBuses ?? '...'}',
              Icons.departure_board,
              Colors.teal,
            ),
            _metricTile(
              'Delayed Buses',
              '${stats?.delayedBuses ?? '...'}',
              Icons.warning_amber,
              Colors.red,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Passenger and Revenue Signals'),
            const SizedBox(height: 8),
            _metricTile(
              'Passenger Count',
              '${stats?.passengersToday ?? '...'}',
              Icons.people_alt,
              Colors.green,
            ),
            _metricTile(
              'Revenue',
              '${stats?.todayRevenue ?? '...'} ETB',
              Icons.attach_money,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _sectionTitle('Route Analytics'),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _collection('terminal_routes').snapshots(),
              builder: (context, snapshot) {
                final routes = snapshot.data?.docs ?? [];
                return Column(
                  children: routes.take(6).map((doc) {
                    final data = doc.data();
                    final occupancy = ((data['fare'] ?? 100) as num).toDouble() / 10;
                    return Card(
                      child: ListTile(
                        title: Text(data['route'] ?? 'Route'),
                        subtitle: Text(
                          'Optimization: ${data['optimizationStatus'] ?? 'Balanced'}',
                        ),
                        trailing: Text('${occupancy.toStringAsFixed(0)}% load'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      }
    );
  }

  Widget _buildManagementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Platform Management'),
        const SizedBox(height: 8),
        _managementTile('Routes', Icons.route, 'terminal_routes', [
          'route',
          'origin',
          'destination',
          'fare',
          'duration',
        ]),
        _managementTile('Schedules', Icons.schedule, 'schedules', [
          'destination',
          'departureTime',
          'busNumber',
          'driverName',
          'status',
        ]),
        _managementTile('Buses', Icons.directions_bus, 'vehicles', [
          'plateNumber',
          'company',
          'capacity',
          'status',
        ]),
        _managementTile('Drivers', Icons.person, 'drivers', [
          'name',
          'phone',
          'licenseNumber',
          'performanceScore',
        ]),
        _managementTile('Companies', Icons.business, 'companies', [
          'name',
          'contact',
          'serviceArea',
        ]),
        _managementTile('Boarding Gates', Icons.input, 'gates', [
          'gateName',
          'status',
          'assignedBus',
        ]),
        _managementTile('Bus Bays', Icons.local_parking, 'bays', [
          'bayName',
          'status',
          'assignedBus',
        ]),
        _managementTile(
          'Driver Assignment',
          Icons.assignment_ind,
          'assignments',
          ['driverName', 'busNumber', 'route', 'shift'],
        ),
      ],
    );
  }

  Widget _buildAiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('AI Smart Terminal Assistant'),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _collection('bookings').snapshots(),
          builder: (context, snapshot) {
            final bookings = snapshot.data?.docs ?? [];
            final total = bookings.length;
            return Column(
              children: [
                _insightCard(
                  'Passenger Demand',
                  total > 8
                      ? 'Demand is rising and extra buses are recommended for the next peak window.'
                      : 'Demand is steady; current capacity is sufficient.',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _insightCard(
                  'Bus Shortage',
                  total > 10
                      ? 'Schedule adjustment is recommended for high-volume routes.'
                      : 'No shortage detected yet.',
                  Icons.warning_amber,
                  Colors.red,
                ),
                _insightCard(
                  'Schedule Adjustment',
                  'Shift two departures earlier in the evening to reduce overcrowding.',
                  Icons.schedule,
                  Colors.blue,
                ),
                _insightCard(
                  'Daily Report',
                  'Revenue and occupancy patterns are trending positively for $_terminalName.',
                  Icons.analytics,
                  Colors.green,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerificationTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 72,
              color: Color(0xFF0D47A1),
            ),
            const SizedBox(height: 16),
            const Text(
              'Digital Ticket Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a QR code for boarding validation and instant status updates.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TerminalQRScanner()),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open QR Scanner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      color: const Color(0xFF0D47A1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _terminalName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unified multi-terminal control for routes, schedules, buses, tickets, gates, bays, and AI insights.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _managementTile(
    String title,
    IconData icon,
    String collection,
    List<String> fields,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0D47A1)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CRUDListScreen(
              collection: collection,
              title: title,
              fields: fields,
              initialData: {
                'terminal_id': widget.terminalId ?? 'all',
                'terminal': _terminalName,
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _insightCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}
