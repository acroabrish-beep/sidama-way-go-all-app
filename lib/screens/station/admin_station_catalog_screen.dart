import 'package:firebase_auth/firebase_auth.dart';
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
  final GlobalKey<_CatalogTabState> _catalogKey = GlobalKey();
  final GlobalKey<_TariffsTabState> _tariffsKey = GlobalKey();

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

  void _reloadCatalogTabs() {
    _catalogKey.currentState?.reload();
    _tariffsKey.currentState?.reload();
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
        children: [
          _CatalogTab(key: _catalogKey),
          _TariffsTab(key: _tariffsKey),
          _ImportTab(onCommitted: _reloadCatalogTabs),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab({super.key});

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

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
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

  Future<void> _addStation() async {
    final nameController = TextEditingController();
    final nameAmController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    String? dialogError;
    var saving = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add station'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Official station name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameAmController,
                  decoration: const InputDecoration(
                    labelText: 'Amharic name (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        setDialogState(
                          () => dialogError = 'Station name is required.',
                        );
                        return;
                      }
                      final lat = latController.text.trim().isEmpty
                          ? null
                          : double.tryParse(latController.text.trim());
                      final lng = lngController.text.trim().isEmpty
                          ? null
                          : double.tryParse(lngController.text.trim());
                      if ((latController.text.trim().isNotEmpty && lat == null) ||
                          (lngController.text.trim().isNotEmpty && lng == null)) {
                        setDialogState(
                          () => dialogError = 'Latitude/longitude must be numbers.',
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await _api.createStation(
                          name: name,
                          nameAm: nameAmController.text,
                          lat: lat,
                          lng: lng,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } on ApiException catch (error) {
                        setDialogState(() {
                          dialogError = error.message;
                          saving = false;
                        });
                      } catch (error) {
                        AppLogger.error('Station creation failed', error: error);
                        setDialogState(() {
                          dialogError = 'Unable to create the station.';
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create station'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    nameAmController.dispose();
    latController.dispose();
    lngController.dispose();
    if (created == true && mounted) {
      await reload();
    }
  }

  Future<void> _addRoute() async {
    if (_stations.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least two stations before creating a route.'),
        ),
      );
      return;
    }
    String? fromId = _stations.first.id;
    String? toId = _stations[1].id;
    String? dialogError;
    var saving = false;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add route'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: fromId,
                  decoration: const InputDecoration(
                    labelText: 'From station',
                    border: OutlineInputBorder(),
                  ),
                  items: _stations
                      .map(
                        (station) => DropdownMenuItem(
                          value: station.id,
                          child: Text(station.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => fromId = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: toId,
                  decoration: const InputDecoration(
                    labelText: 'To station',
                    border: OutlineInputBorder(),
                  ),
                  items: _stations
                      .map(
                        (station) => DropdownMenuItem(
                          value: station.id,
                          child: Text(station.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => toId = value),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (fromId == null || toId == null || fromId == toId) {
                        setDialogState(
                          () => dialogError =
                              'Choose two different stations.',
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await _api.createRoute(
                          fromStationId: fromId!,
                          toStationId: toId!,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } on ApiException catch (error) {
                        setDialogState(() {
                          dialogError = error.message;
                          saving = false;
                        });
                      } catch (error) {
                        AppLogger.error('Route creation failed', error: error);
                        setDialogState(() {
                          dialogError = 'Unable to create the route.';
                          saving = false;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create route'),
            ),
          ],
        ),
      ),
    );
    if (created == true && mounted) {
      await reload();
    }
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
        _sectionHeader(
          title: 'Stations (${_stations.length})',
          action: FilledButton.icon(
            onPressed: _addStation,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add station'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
            ),
          ),
        ),
        if (_stations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'No stations yet. Add the official stations or use CSV import.',
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
          action: FilledButton.icon(
            onPressed: _addRoute,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add route'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
            ),
          ),
        ),
        if (_routes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'No routes yet. Add them manually or use CSV import.',
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

  Widget _sectionHeader({required String title, required Widget action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          action,
        ],
      ),
    );
  }
}

class _TariffsTab extends StatefulWidget {
  const _TariffsTab({super.key});

  @override
  State<_TariffsTab> createState() => _TariffsTabState();
}

class _TariffsTabState extends State<_TariffsTab> {
  final StationTicketApiService _api = StationTicketApiService();
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Station> _stations = const [];
  List<AdminRoute> _routes = const [];
  List<TariffInfo> _tariffs = const [];
  String? _selectedRouteId;
  StationVehicleType _vehicleType = StationVehicleType.taxi;
  DateTime _effectiveFrom = DateTime.now();
  bool _loading = true;
  bool _loadingTariffs = false;
  bool _creating = false;
  String? _error;
  String? _tariffError;
  String? _createError;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _api.dispose();
    _fareController.dispose();
    _sourceController.dispose();
    _authorityController.dispose();
    super.dispose();
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

  String get _routeLabel {
    final routeId = _selectedRouteId;
    if (routeId == null) return 'No route selected';
    final stationNames = {
      for (final station in _stations) station.id: station.name,
    };
    for (final route in _routes) {
      if (route.id != routeId) continue;
      return '${stationNames[route.fromStationId] ?? 'Unknown'} → '
          '${stationNames[route.toStationId] ?? 'Unknown'}';
    }
    return 'Unknown route';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _effectiveFrom = picked);
    }
  }

  Future<void> _createTariff() async {
    final routeId = _selectedRouteId;
    final fare = double.tryParse(_fareController.text.trim());
    final source = _sourceController.text.trim();
    final authority = _authorityController.text.trim();
    if (routeId == null) {
      setState(() => _createError = 'Select a route.');
      return;
    }
    if (fare == null || fare <= 0) {
      setState(() => _createError = 'Enter a fare greater than zero.');
      return;
    }
    if (source.isEmpty) {
      setState(
        () => _createError =
            'A source reference (official document number and date) is required.',
      );
      return;
    }
    if (authority.isEmpty) {
      setState(
        () => _createError =
            'The approving authority or official is required.',
      );
      return;
    }
    setState(() {
      _creating = true;
      _createError = null;
    });
    try {
      await _api.createTariff(
        routeId: routeId,
        vehicleType: _vehicleType,
        fareEtb: fare,
        effectiveFrom: _dateFormat.format(_effectiveFrom),
        sourceReference: source,
        approvedBy: authority,
      );
      if (!mounted) return;
      _fareController.clear();
      _sourceController.clear();
      _authorityController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tariff version created and approved.')),
      );
      await _loadTariffs(routeId);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _createError = error.message);
    } catch (error) {
      AppLogger.error('Tariff creation failed', error: error);
      if (!mounted) return;
      setState(() => _createError = 'Unable to create the tariff.');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StationErrorView(message: _error!, onRetry: reload);
    }
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'sign-in required';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StationSectionCard(
          title: 'Create a tariff version',
          icon: Icons.gavel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_routes.isEmpty)
                const Text(
                  'Create a station route before adding tariffs.',
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
                const SizedBox(height: 10),
                DropdownButtonFormField<StationVehicleType>(
                  initialValue: _vehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle type',
                    border: OutlineInputBorder(),
                  ),
                  items: StationVehicleType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _vehicleType = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fareController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fare in ETB *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    'Effective from: ${_dateFormat.format(_effectiveFrom)}',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Source reference *',
                    hintText: 'Official document number and date',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _authorityController,
                  decoration: const InputDecoration(
                    labelText: 'Approving authority / official *',
                    hintText: 'Name and role of the authority who approved it',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your verified admin UID is stored separately as created_by: $adminUid',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (_createError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _createError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _creating ? null : _createTariff,
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Create tariff'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ],
          ),
        ),
        StationSectionCard(
          title: 'Tariff history · $_routeLabel',
          icon: Icons.history,
          child: _loadingTariffs
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _tariffError != null
              ? Column(
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
              : _tariffs.isEmpty
              ? const Text(
                  'No tariffs recorded for this route.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              : Column(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                Text('Recorded by admin: ${tariff.createdBy}'),
                              Text(tariff.label),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Map<String, String> get _stationNames => {
    for (final station in _stations) station.id: station.name,
  };
}

class _ImportTab extends StatefulWidget {
  const _ImportTab({required this.onCommitted});

  final VoidCallback onCommitted;

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  final StationTicketApiService _api = StationTicketApiService();
  final TextEditingController _stationsController = TextEditingController();
  final TextEditingController _routesController = TextEditingController();
  final TextEditingController _tariffsController = TextEditingController();

  CatalogImportResult? _result;
  String? _error;
  bool _running = false;
  bool _dryRunPassed = false;

  @override
  void dispose() {
    _api.dispose();
    _stationsController.dispose();
    _routesController.dispose();
    _tariffsController.dispose();
    super.dispose();
  }

  void _invalidateDryRun() {
    if (_dryRunPassed) {
      setState(() => _dryRunPassed = false);
    }
  }

  Future<void> _run({required bool commit}) async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _api.importCatalog(
        stationsCsv: _stationsController.text,
        routesCsv: _routesController.text,
        tariffsCsv: _tariffsController.text,
        commit: commit,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _dryRunPassed = !commit && result.valid;
      });
      if (commit && result.committed) {
        widget.onCommitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catalog import committed.')),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      AppLogger.error('Catalog import failed', error: error);
      if (!mounted) return;
      setState(() => _error = 'Unable to run the catalog import.');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminUid =
        FirebaseAuth.instance.currentUser?.uid ?? 'sign-in required';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StationSectionCard(
          title: 'Required CSV columns',
          icon: Icons.table_chart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'stations.csv',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'name (required), name_am, lat, lng',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                'routes.csv',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'from_station, to_station',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                'tariffs.csv',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'from_station, to_station, vehicle_type, fare_etb, '
                'effective_from, effective_to, source_reference, approved_by',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                'vehicle_type must be taxi, bajaj or minibus. Dates use YYYY-MM-DD. '
                'effective_to may be empty. approved_by is the approving authority or '
                'official (free text, required). Your verified admin UID is stored '
                'separately as created_by and must not be used as approved_by.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              SizedBox(height: 6),
              Text(
                'No sample rows are provided. Import only official city data.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Your verified admin UID is recorded automatically as created_by: $adminUid',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _csvField(
          label: 'stations.csv',
          controller: _stationsController,
          hint: 'name,name_am,lat,lng',
        ),
        const SizedBox(height: 12),
        _csvField(
          label: 'routes.csv',
          controller: _routesController,
          hint: 'from_station,to_station',
        ),
        const SizedBox(height: 12),
        _csvField(
          label: 'tariffs.csv',
          controller: _tariffsController,
          hint:
              'from_station,to_station,vehicle_type,fare_etb,effective_from,effective_to,source_reference,approved_by',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _running ? null : () => _run(commit: false),
                icon: const Icon(Icons.preview, size: 18),
                label: const Text('Dry run'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _running || !_dryRunPassed
                    ? null
                    : () => _run(commit: true),
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload, size: 18),
                label: const Text('Commit import'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                ),
              ),
            ),
          ],
        ),
        if (!_dryRunPassed && !_running)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Commit is enabled only after a dry run passes validation.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          _buildResult(_result!),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _csvField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      onChanged: (_) => _invalidateDryRun(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResult(CatalogImportResult result) {
    if (!result.valid) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.errors.length} validation error(s)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 6),
            ...result.errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '• $error',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (result.committed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2E7D32)),
        ),
        child: const Text(
          'Import committed successfully.',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    final summary = result.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E7D32)),
          ),
          child: Text(
            'Dry run passed: ${summary?['stations'] ?? 0} stations, '
            '${summary?['routes'] ?? 0} routes, '
            '${summary?['tariffs'] ?? 0} tariffs.',
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (result.stations.isNotEmpty)
          ExpansionTile(
            title: Text('Preview stations (${result.stations.length})'),
            children: result.stations
                .take(20)
                .map(
                  (station) => ListTile(
                    dense: true,
                    title: Text(station.name),
                    subtitle: Text(
                      '${station.nameAm ?? ''} '
                      '${station.lat != null ? '· ${station.lat}, ${station.lng}' : ''}',
                    ),
                  ),
                )
                .toList(),
          ),
        if (result.routes.isNotEmpty)
          ExpansionTile(
            title: Text('Preview routes (${result.routes.length})'),
            children: result.routes
                .take(20)
                .map(
                  (route) => ListTile(
                    dense: true,
                    title: Text(
                      '${route.fromStation} → ${route.toStation}',
                    ),
                  ),
                )
                .toList(),
          ),
        if (result.tariffs.isNotEmpty)
          ExpansionTile(
            title: Text('Preview tariffs (${result.tariffs.length})'),
            children: result.tariffs
                .take(20)
                .map(
                  (tariff) => ListTile(
                    dense: true,
                    title: Text(
                      '${tariff.fromStation} → ${tariff.toStation} · '
                      '${tariff.vehicleType.label} · ETB ${tariff.fareEtb}',
                    ),
                    subtitle: Text(
                      'From ${tariff.effectiveFrom} · ${tariff.sourceReference} · '
                      'Approved by ${tariff.approvedBy}',
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
