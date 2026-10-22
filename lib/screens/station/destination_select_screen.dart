import 'package:flutter/material.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ui.dart';
import 'ticket_checkout_screen.dart';

class DestinationSelectScreen extends StatefulWidget {
  const DestinationSelectScreen({super.key, required this.station});

  final Station station;

  @override
  State<DestinationSelectScreen> createState() =>
      _DestinationSelectScreenState();
}

class _DestinationSelectScreenState extends State<DestinationSelectScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  List<StationDestination>? _destinations;
  String? _error;
  bool _loading = true;
  String? _selectedRouteId;
  StationVehicleType? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final destinations = await _api.getDestinations(widget.station.id);
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Destination load failed', error: error);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load destinations.';
        _loading = false;
      });
    }
  }

  _SelectedTariff? get _selected {
    final routeId = _selectedRouteId;
    final vehicleType = _selectedVehicleType;
    if (routeId == null || vehicleType == null) return null;
    for (final destination in _destinations ?? const <StationDestination>[]) {
      if (destination.routeId != routeId) continue;
      for (final tariff in destination.tariffs) {
        if (tariff.vehicleType == vehicleType) {
          return _SelectedTariff(destination: destination, tariff: tariff);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose destination'),
            Text(
              widget.station.name,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StationErrorView(message: _error!, onRetry: _load);
    }
    final destinations = _destinations ?? const <StationDestination>[];
    if (destinations.isEmpty) {
      return const StationEmptyView(
        icon: Icons.route,
        title: 'No destinations yet',
        message:
            'No active route leaves this station. The official routes must be imported by a taxi administrator.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final destination in destinations)
            _buildDestinationCard(destination),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(StationDestination destination) {
    final hasOfficialTariff = destination.tariffs.any(
      (tariff) => tariff.isOfficial,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _selectedRouteId == destination.routeId
              ? const Color(0xFF2E7D32)
              : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.station.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (destination.station.nameAm != null)
                        Text(
                          destination.station.nameAm!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!hasOfficialTariff)
                  const StationStatusChip(status: 'Tariff pending approval'),
              ],
            ),
            if (destination.tariffs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Tariff not set — purchase is blocked until an official tariff is approved.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else
              RadioGroup<StationVehicleType>(
                groupValue: _selectedRouteId == destination.routeId
                    ? _selectedVehicleType
                    : null,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedRouteId = destination.routeId;
                    _selectedVehicleType = value;
                  });
                },
                child: Column(
                  children: destination.tariffs.map(
                (tariff) => RadioListTile<StationVehicleType>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: tariff.vehicleType,
                  title: Row(
                    children: [
                      Text(tariff.vehicleType.label),
                      const SizedBox(width: 8),
                      Text(
                        '${destination.queueCounts[tariff.vehicleType] ?? 0} waiting',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ETB ${tariff.fareEtb.toStringAsFixed(2)} · ${tariff.label}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tariff.isOfficial
                              ? const Color(0xFF2E7D32)
                              : Colors.orange.shade800,
                        ),
                      ),
                      if (tariff.sourceReference != null)
                        Text(
                          'Ref: ${tariff.sourceReference}',
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  secondary: tariff.isOfficial
                      ? null
                      : const Icon(Icons.lock_outline, color: Colors.orange),
                ),
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selected = _selected;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: selected == null
                  ? const Text(
                      'Select a fare to continue',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ETB ${selected.tariff.fareEtb.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${selected.tariff.vehicleType.label} to ${selected.destination.station.name}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: selected == null || !selected.tariff.isOfficial
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketCheckoutScreen(
                          station: widget.station,
                          destination: selected.destination,
                          tariff: selected.tariff,
                        ),
                      ),
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text('Review ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedTariff {
  const _SelectedTariff({required this.destination, required this.tariff});

  final StationDestination destination;
  final TariffInfo tariff;
}
