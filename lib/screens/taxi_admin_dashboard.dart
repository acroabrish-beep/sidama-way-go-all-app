import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/city_os_models.dart';
import '../models/taxi_models.dart';
import '../services/taxi_service.dart';
import '../utils/firestore_utils.dart';
import '../widgets/role_protected_widget.dart';
import '../models/user_model.dart';
import 'station/station_metrics_overview.dart';

class TaxiAdminDashboard extends StatefulWidget {
  const TaxiAdminDashboard({super.key});

  @override
  State<TaxiAdminDashboard> createState() => _TaxiAdminDashboardState();
}

class _TaxiAdminDashboardState extends State<TaxiAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaxiService _taxiService = TaxiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Demo seeding is debug-only.
    if (kDebugMode) _taxiService.seedStations();
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.taxiAdmin],
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart City Dispatch',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                'Hawassa Taxi Station Management',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A237E),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.orangeAccent,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Stations'),
              Tab(text: 'Taxis'),
              Tab(text: 'Live Map'),
              Tab(text: 'Requests'),
              Tab(text: 'Alerts'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const _OverviewTab(),
            const _StationsTab(),
            const _TaxisTab(),
            const _LiveMapTab(),
            const _RequestsTab(),
            const _AlertsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) => const StationMetricsOverview();
}

class _StationsTab extends StatefulWidget {
  const _StationsTab();

  @override
  State<_StationsTab> createState() => _StationsTabState();
}

class _StationsTabState extends State<_StationsTab> {
  final TaxiService _taxiService = TaxiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<TaxiStation>>(
        stream: _taxiService.getTaxiStations(),
        builder: (context, stationSnapshot) {
          if (stationSnapshot.hasError)
            return Center(child: Text('Error: ${stationSnapshot.error}'));
          if (!stationSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return StreamBuilder<List<TaxiDriver>>(
            stream: _taxiService.getAllDrivers(),
            builder: (context, driverSnapshot) {
              if (!driverSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final stations = stationSnapshot.data!;
              final allDrivers = driverSnapshot.data!;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF1F3F4),
                    ),
                    columns: const [
                      DataColumn(label: Text('STATION')),
                      DataColumn(label: Text('CAPACITY')),
                      DataColumn(label: Text('TOTAL')),
                      DataColumn(label: Text('ONLINE')),
                      DataColumn(label: Text('BUSY')),
                      DataColumn(label: Text('WAITING PASS.')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: stations.map((s) {
                      final stationDrivers = allDrivers
                          .where((d) => d.stationId == s.id)
                          .toList();
                      final onlineCount = stationDrivers
                          .where((d) => d.online)
                          .length;
                      final busyCount = stationDrivers
                          .where((d) => d.status == TaxiStatus.busy)
                          .length;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(s.capacity.toString())),
                          DataCell(
                            Text(
                              stationDrivers.length.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              onlineCount.toString(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              busyCount.toString(),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(s.waitingPassengers.toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                s.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _showAddTaxiDialog(context, s),
                                  tooltip: 'Add Taxi',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _showViewTaxisDialog(context, s),
                                  tooltip: 'View Taxis',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.swap_horiz,
                                    size: 20,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _showMoveTaxiDialog(context, s),
                                  tooltip: 'Move Taxi',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showRemoveTaxiDialog(context, s),
                                  tooltip: 'Remove Taxi',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStationDialog(context),
        label: const Text('Add Station'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddTaxiDialog(BuildContext context, TaxiStation station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Taxi to ${station.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<TaxiDriver>>(
            stream: _taxiService.getAllDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final availableDrivers = snapshot.data!
                  .where(
                    (d) =>
                        d.approvalStatus == DriverStatus.approved &&
                        d.online &&
                        (d.stationId.isEmpty || d.stationId == 'general'),
                  )
                  .toList();
              if (availableDrivers.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No unassigned online taxis.'),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: availableDrivers.length,
                itemBuilder: (context, index) {
                  final driver = availableDrivers[index];
                  return ListTile(
                    title: Text(driver.fullName),
                    subtitle: Text(
                      '${driver.plateNumber} • ${driver.vehicleModel}',
                    ),
                    onTap: () async {
                      await _taxiService.assignTaxiToStation(
                        driver.id,
                        station.id,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showViewTaxisDialog(BuildContext context, TaxiStation station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Taxis at ${station.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<TaxiDriver>>(
            stream: _taxiService.getAllDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final stationDrivers = snapshot.data!
                  .where((d) => d.stationId == station.id)
                  .toList();
              if (stationDrivers.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No taxis assigned.'),
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: stationDrivers.length,
                itemBuilder: (context, index) {
                  final driver = stationDrivers[index];
                  return ListTile(
                    title: Text(driver.fullName),
                    subtitle: Text(driver.plateNumber),
                    trailing: Text(driver.status.name.toUpperCase()),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMoveTaxiDialog(BuildContext context, TaxiStation sourceStation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move Taxi from ${sourceStation.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<TaxiDriver>>(
            stream: _taxiService.getAllDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final driversAtStation = snapshot.data!
                  .where((d) => d.stationId == sourceStation.id)
                  .toList();
              return ListView.builder(
                shrinkWrap: true,
                itemCount: driversAtStation.length,
                itemBuilder: (context, index) {
                  final driver = driversAtStation[index];
                  return ListTile(
                    title: Text(driver.fullName),
                    onTap: () {
                      Navigator.pop(context);
                      _showSelectTargetStationDialog(
                        context,
                        driver,
                        sourceStation,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSelectTargetStationDialog(
    BuildContext context,
    TaxiDriver driver,
    TaxiStation sourceStation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move ${driver.fullName} to:'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<TaxiStation>>(
            stream: _taxiService.getTaxiStations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final otherStations = snapshot.data!
                  .where((s) => s.id != sourceStation.id)
                  .toList();
              return ListView.builder(
                shrinkWrap: true,
                itemCount: otherStations.length,
                itemBuilder: (context, index) {
                  final target = otherStations[index];
                  return ListTile(
                    title: Text(target.name),
                    onTap: () async {
                      await _taxiService.moveTaxiBetweenStations(
                        driver.id,
                        sourceStation.id,
                        target.id,
                        target.name,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRemoveTaxiDialog(BuildContext context, TaxiStation station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Taxi from ${station.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<TaxiDriver>>(
            stream: _taxiService.getAllDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final driversAtStation = snapshot.data!
                  .where((d) => d.stationId == station.id)
                  .toList();
              return ListView.builder(
                shrinkWrap: true,
                itemCount: driversAtStation.length,
                itemBuilder: (context, index) {
                  final driver = driversAtStation[index];
                  return ListTile(
                    title: Text(driver.fullName),
                    onTap: () async {
                      await _taxiService.removeTaxiFromStation(
                        driver.id,
                        station.id,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddStationDialog(BuildContext context) {
    final nameC = TextEditingController();
    final capC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register New Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Station Name'),
            ),
            TextField(
              controller: capC,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              _taxiService.saveStation(
                TaxiStation(
                  stationId: '',
                  stationName: nameC.text,
                  stationCode: 'HUB',
                  maximumVehicleCapacity: int.parse(capC.text),
                  location: const GeoPoint(7.0504, 38.4955),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

class _TaxisTab extends StatelessWidget {
  const _TaxisTab();

  @override
  Widget build(BuildContext context) {
    final TaxiService taxiService = TaxiService();
    return Scaffold(
      body: StreamBuilder<List<TaxiDriver>>(
        stream: taxiService.getAllDrivers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final taxis = snapshot.data!;
          return ListView.separated(
            itemCount: taxis.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = taxis[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(
                    t.status,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.local_taxi,
                    color: _getStatusColor(t.status),
                  ),
                ),
                title: Text(
                  t.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${t.plateNumber} • ${t.stationName}'),
                trailing: Text(
                  t.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(t.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(TaxiStatus status) {
    switch (status) {
      case TaxiStatus.waiting:
        return Colors.green;
      case TaxiStatus.busy:
        return Colors.orange;
      case TaxiStatus.onTrip:
        return Colors.blue;
      case TaxiStatus.offline:
        return Colors.grey;
    }
  }
}

class _LiveMapTab extends StatelessWidget {
  const _LiveMapTab();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(7.0504, 38.4955),
        initialZoom: 13.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(CityOSCollection.taxiStations)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const MarkerLayer(markers: []);
            return MarkerLayer(
              markers: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final loc =
                    data['location'] as GeoPoint? ?? const GeoPoint(0, 0);
                return Marker(
                  point: LatLng(loc.latitude, loc.longitude),
                  width: 120,
                  height: 60,
                  child: Column(
                    children: [
                      const Icon(Icons.place, color: Colors.blue, size: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          data['name'] ?? 'Station',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(CityOSCollection.drivers)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const MarkerLayer(markers: []);
            return MarkerLayer(
              markers: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final loc = data['location'] as GeoPoint?;
                if (loc == null)
                  return const Marker(point: LatLng(0, 0), child: SizedBox());
                final status = data['status'] ?? 'offline';
                final isOnline = data['online'] ?? false;
                Color color = isOnline
                    ? (status == 'waiting' ? Colors.green : Colors.orange)
                    : Colors.grey;
                return Marker(
                  point: LatLng(loc.latitude, loc.longitude),
                  child: Icon(Icons.navigation, color: color, size: 24),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(CityOSCollection.rideRequests)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!.docs;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, i) {
            final r = requests[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                title: Text(
                  '${r['pickup']} → ${r['destination']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Passenger: ${r['userName']} • Fare: ${r['fare']} ETB',
                ),
                trailing: Text(
                  r['status'] ?? 'Pending',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_alerts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final alerts = snapshot.data!.docs;
        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, i) {
            final a = alerts[i].data() as Map<String, dynamic>;
            return Card(
              color: Colors.red[50],
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: const Icon(Icons.emergency, color: Colors.red),
                title: Text(
                  'SOS from ${a['driverName']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  'Time: ${FirestoreUtils.parseDateTime(a['timestamp']) ?? 'Just now'}',
                ),
                trailing: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('DISPATCH HELP'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
