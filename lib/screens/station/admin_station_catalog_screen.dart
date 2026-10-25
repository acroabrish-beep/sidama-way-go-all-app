import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ui.dart';

class AdminStationCatalogScreen extends StatefulWidget {
  const AdminStationCatalogScreen({super.key});

  @override
  State<AdminStationCatalogScreen> createState() =>
      _AdminStationCatalogScreenState();
}

class _AdminStationCatalogScreenState extends State<AdminStationCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Station catalog'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orangeAccent,
          tabs: const [
            Tab(text: 'Stations & routes'),
            Tab(text: 'Tariffs'),
            Tab(text: 'CSV import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_CatalogTab(), _TariffsTab(), _ImportTab()],
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab();

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  final StationTicketApiService _api = StationTicketApiService();
  List<Station> _stations = const [];
  List<AdminRoute> _routes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getAdminStations(),
        _api.getAdminRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        _stations = results[0] as List<Station>;
        _routes = results[1] as List<AdminRoute>;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Catalog load failed', error: error);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the station catalog.';
        _loading = false;
      });
    }
  }

  Map<String, String> get _stationNames => {
    for (final station in _stations) station.id: station.name,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StationErrorView(message: _error!, onRetry: reload);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StationPhase5Notice(
          title: 'Catalog writes are scheduled for Phase 5',
          message:
              'Creating stations and routes previously used the Next.js admin '
              'API. The legacy endpoints are retired. The live Supabase catalog '
              'is readable now; authenticated admin functions for writes are '
              'deferred to Phase 5.',
        ),
        const SizedBox(height: 12),
        _sectionHeader(
          title: 'Stations (${_stations.length})',
          icon: Icons.place,
          onRefresh: reload,
        ),
        if (_stations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'No stations are configured yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ..._stations.map(
            (station) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black12),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.place, color: Color(0xFF1A237E)),
                title: Text(station.name),
                subtitle: Text(
                  [
                    if (station.nameAm != null) station.nameAm!,
                    if (station.lat != null && station.lng != null)
                      '${station.lat!.toStringAsFixed(5)}, ${station.lng!.toStringAsFixed(5)}',
                  ].join(' · '),
                ),
                trailing: StationStatusChip(
                  status: station.active ? 'paid' : 'cancelled',
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        _sectionHeader(
          title: 'Routes (${_routes.length})',
          icon: Icons.alt_route,
          onRefresh: reload,
        ),
        if (_routes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'No routes are configured yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ..._routes.map(
            (route) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black12),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.alt_route, color: Color(0xFF1A237E)),
                title: Text(
                  '${_stationNames[route.fromStationId] ?? 'Unknown'} → '
                  '${_stationNames[route.toStationId] ?? 'Unknown'}',
                ),
                trailing: StationStatusChip(
                  status: route.active ? 'paid' : 'cancelled',
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onRefresh,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Reload catalog',
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _TariffsTab extends StatefulWidget {
  const _TariffsTab();

  @override
  State<_TariffsTab> createState() => _TariffsTabState();
}

class _TariffsTabState extends State<_TariffsTab> {
  final StationTicketApiService _api = StationTicketApiService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Station> _stations = const [];
  List<AdminRoute> _routes = const [];
  List<TariffInfo> _tariffs = const [];
  String? _selectedRouteId;
  bool _loading = true;
  bool _loadingTariffs = false;
  String? _error;
  String? _tariffError;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getAdminStations(),
        _api.getAdminRoutes(),
      ]);
      if (!mounted) return;
      final stations = results[0] as List<Station>;
      final routes = results[1] as List<AdminRoute>;
      String? routeId;
      if (routes.isNotEmpty) {
        routeId = routes.any((route) => route.id == _selectedRouteId)
            ? _selectedRouteId
            : routes.first.id;
      }
      setState(() {
        _stations = stations;
        _routes = routes;
        _selectedRouteId = routeId;
        _loading = false;
      });
      if (routeId != null) {
        await _loadTariffs(routeId);
      } else {
        setState(() => _tariffs = const []);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Tariff tab load failed', error: error);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the tariff catalog.';
        _loading = false;
      });
    }
  }

  Future<void> _loadTariffs(String routeId) async {
    setState(() {
      _loadingTariffs = true;
      _tariffError = null;
    });
    try {
      final tariffs = await _api.getAdminTariffs(routeId: routeId);
      if (!mounted || _selectedRouteId != routeId) return;
      setState(() {
        _tariffs = tariffs;
        _loadingTariffs = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _tariffError = error.message;
        _loadingTariffs = false;
      });
    } catch (error) {
      AppLogger.error('Tariff history load failed', error: error);
      if (!mounted) return;
      setState(() {
        _tariffError = 'Unable to load tariff history.';
        _loadingTariffs = false;
      });
    }
  }

  Map<String, String> get _stationNames => {
    for (final station in _stations) station.id: station.name,
  };

  String get _routeLabel {
    final routeId = _selectedRouteId;
    if (routeId == null) return 'No route selected';
    for (final route in _routes) {
      if (route.id != routeId) continue;
      return '${_stationNames[route.fromStationId] ?? 'Unknown'} → '
          '${_stationNames[route.toStationId] ?? 'Unknown'}';
    }
    return 'Unknown route';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StationErrorView(message: _error!, onRetry: reload);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StationPhase5Notice(
          title: 'Tariff creation is scheduled for Phase 5',
          message:
              'Reading approved tariff versions from Supabase works now. '
              'Creating a new fare version previously used the Next.js admin '
              'API; that write path returns in Phase 5 as an authenticated '
              'server-side function.',
        ),
        const SizedBox(height: 12),
        StationSectionCard(
          title: 'Tariff history · $_routeLabel',
          icon: Icons.history,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_routes.isEmpty)
                const Text(
                  'No routes are configured yet.',
                  style: TextStyle(color: Colors.orange, fontSize: 13),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedRouteId,
                  decoration: const InputDecoration(
                    labelText: 'Route',
                    border: OutlineInputBorder(),
                  ),
                  items: _routes
                      .map(
                        (route) => DropdownMenuItem(
                          value: route.id,
                          child: Text(
                            '${_stationNames[route.fromStationId] ?? 'Unknown'} → '
                            '${_stationNames[route.toStationId] ?? 'Unknown'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedRouteId = value;
                      _tariffs = const [];
                    });
                    _loadTariffs(value);
                  },
                ),
                const SizedBox(height: 12),
                if (_loadingTariffs)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_tariffError != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tariffError!,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: _selectedRouteId == null
                            ? null
                            : () => _loadTariffs(_selectedRouteId!),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else if (_tariffs.isEmpty)
                  const Text(
                    'No tariffs recorded for this route.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else
                  Column(
                    children: _tariffs
                        .map(
                          (tariff) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              tariff.isOfficial
                                  ? Icons.verified
                                  : Icons.pending,
                              color: tariff.isOfficial
                                  ? const Color(0xFF2E7D32)
                                  : Colors.orange,
                            ),
                            title: Text(
                              '${tariff.vehicleType.label} · ETB ${tariff.fareEtb.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_dateFormat.format(tariff.effectiveFrom)}'
                                  '${tariff.effectiveTo == null ? ' → open' : ' → ${_dateFormat.format(tariff.effectiveTo!)}'}',
                                ),
                                if (tariff.sourceReference != null)
                                  Text('Ref: ${tariff.sourceReference}'),
                                if (tariff.approvedBy != null)
                                  Text('Approved by: ${tariff.approvedBy}'),
                                if (tariff.createdBy != null)
                                  Text(
                                    'Recorded by admin: ${tariff.createdBy}',
                                  ),
                                Text(tariff.label),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImportTab extends StatelessWidget {
  const _ImportTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        StationPhase5Notice(
          title: 'CSV catalog import is scheduled for Phase 5',
          message:
              'The CSV preview and commit flow used the Next.js admin import '
              'API. Import writes will move to a server-side Supabase function '
              'with the same validation in Phase 5. No import is sent from the '
              'app in this build.',
        ),
        SizedBox(height: 12),
        StationSectionCard(
          title: 'What still works',
          icon: Icons.check_circle_outline,
          child: Text(
            'The Stations, routes and Tariffs tabs read the live Supabase '
            'catalog directly. Passenger ticket purchase and driver ticket '
            'verification use Supabase Edge Functions.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
