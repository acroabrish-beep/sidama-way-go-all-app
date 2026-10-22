import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'station_ui.dart';
import 'ticket_qr_scanner_screen.dart';
import 'verification_result_card.dart';

class DriverStationScreen extends StatefulWidget {
  const DriverStationScreen({super.key});

  @override
  State<DriverStationScreen> createState() => _DriverStationScreenState();
}

class _DriverStationScreenState extends State<DriverStationScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  final TextEditingController _codeController = TextEditingController();
  final DateFormat _timeFormat = DateFormat('HH:mm');

  List<DriverVehicle> _vehicles = const [];
  List<Station> _stations = const [];
  DriverVehicle? _vehicle;
  Station? _station;
  QueueSnapshot? _queue;
  bool _loading = true;
  bool _queueLoading = false;
  bool _joining = false;
  bool _leaving = false;
  bool _verifyingCode = false;
  String? _loadError;
  String? _queueError;
  String? _manualError;
  VerificationOutcome? _manualOutcome;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSetup();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _station == null || _loading) return;
      _loadQueue();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _codeController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadSetup() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _api.getDriverVehicles(),
        _api.getStations(),
      ]);
      if (!mounted) return;
      final vehicles = results[0] as List<DriverVehicle>;
      final stations = results[1] as List<Station>;
      DriverVehicle? vehicle;
      if (vehicles.isNotEmpty) {
        final previousId = _vehicle?.id;
        vehicle = vehicles.firstWhere(
          (item) => item.id == previousId,
          orElse: () => vehicles.first,
        );
      }
      Station? station;
      if (stations.isNotEmpty) {
        final previousId = _station?.id;
        station = stations.firstWhere(
          (item) => item.id == previousId,
          orElse: () => stations.first,
        );
      }
      setState(() {
        _vehicles = vehicles;
        _stations = stations;
        _vehicle = vehicle;
        _station = station;
        _loading = false;
      });
      if (station != null) {
        await _loadQueue();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    } catch (error) {
      AppLogger.error('Driver station setup failed', error: error);
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load the driver station.';
        _loading = false;
      });
    }
  }

  Future<void> _loadQueue() async {
    final station = _station;
    if (station == null) return;
    setState(() {
      _queueLoading = true;
      _queueError = null;
    });
    try {
      final snapshot = await _api.getQueue(
        station.id,
        vehicleId: _vehicle?.id,
      );
      if (!mounted || _station?.id != station.id) return;
      setState(() {
        _queue = snapshot;
        _queueLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _queueError = error.message;
        _queueLoading = false;
      });
    } catch (error) {
      AppLogger.error('Queue load failed', error: error);
      if (!mounted) return;
      setState(() {
        _queueError = 'Unable to load the smart queue.';
        _queueLoading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    final station = _station;
    final vehicle = _vehicle;
    if (station == null || vehicle == null || _joining) return;
    setState(() {
      _joining = true;
      _queueError = null;
    });
    try {
      await _api.checkIn(stationId: station.id, vehicleId: vehicle.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vehicle.registrationNumber} joined the smart queue.')),
      );
      await _loadQueue();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _queueError = error.message);
    } catch (error) {
      AppLogger.error('Queue check-in failed', error: error);
      if (!mounted) return;
      setState(() => _queueError = 'Unable to join the queue.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _checkOut() async {
    final vehicle = _vehicle;
    if (vehicle == null || _leaving) return;
    setState(() {
      _leaving = true;
      _queueError = null;
    });
    try {
      await _api.checkOut(vehicle.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle left the queue.')),
      );
      await _loadQueue();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _queueError = error.message);
    } catch (error) {
      AppLogger.error('Queue check-out failed', error: error);
      if (!mounted) return;
      setState(() => _queueError = 'Unable to leave the queue.');
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _verifyCode() async {
    final vehicle = _vehicle;
    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle is assigned to your account.'),
        ),
      );
      return;
    }
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _manualError = 'Enter the passenger ticket code.');
      return;
    }
    setState(() {
      _verifyingCode = true;
      _manualError = null;
      _manualOutcome = null;
    });
    try {
      final outcome = await _api.verifyCode(
        code: code,
        vehicleId: vehicle.id,
      );
      if (!mounted) return;
      setState(() => _manualOutcome = outcome);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _manualError = error.message);
    } catch (error) {
      AppLogger.error('Code verification failed', error: error);
      if (!mounted) return;
      setState(() => _manualError = 'Unable to verify the ticket code.');
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  void _openScanner() {
    final vehicle = _vehicle;
    if (vehicle == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketQrScannerScreen(
          vehicleId: vehicle.id,
          vehicleLabel: vehicle.registrationNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Driver Station'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSetup();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return StationErrorView(message: _loadError!, onRetry: _loadSetup);
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _loadSetup();
        await _loadQueue();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVehicleCard(),
          _buildQueueCard(),
          _buildVerificationCard(),
          const SizedBox(height: 12),
          const Text(
            'Smart queue is a first-in, first-out list based on driver check-in time. '
            'It is a deterministic queue, not AI.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return StationSectionCard(
      title: 'Assigned vehicle',
      icon: Icons.local_taxi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_vehicles.isEmpty)
            const Text(
              'No vehicle is assigned to your driver account. A taxi administrator must assign a vehicle before you can join the queue or verify tickets.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )
          else if (_vehicles.length == 1)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.directions_car, color: Color(0xFF2E7D32)),
              ),
              title: Text(
                _vehicles.first.registrationNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_vehicles.first.vehicleType.label} · status: ${_vehicles.first.status}',
              ),
            )
          else
            DropdownButton<DriverVehicle>(
              isExpanded: true,
              value: _vehicle,
              items: _vehicles
                  .map(
                    (vehicle) => DropdownMenuItem(
                      value: vehicle,
                      child: Text(
                        '${vehicle.registrationNumber} · ${vehicle.vehicleType.label}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (vehicle) {
                if (vehicle == null) return;
                setState(() {
                  _vehicle = vehicle;
                  _manualOutcome = null;
                  _manualError = null;
                });
                _loadQueue();
              },
            ),
          const SizedBox(height: 6),
          const Text(
            'Boarding verifications are recorded against the selected vehicle, and only its assigned driver can verify.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard() {
    final station = _station;
    final queue = _queue;
    final myEntry = queue?.myEntry;
    final canJoin =
        station != null && _vehicle != null && myEntry == null && !_joining;

    return StationSectionCard(
      title: 'Smart queue',
      icon: Icons.people_alt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stations.isEmpty)
            const Text(
              'No stations are configured. A taxi administrator must import the station catalog.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )
          else ...[
            DropdownButton<Station>(
              isExpanded: true,
              value: station,
              items: _stations
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _station = value;
                  _queue = null;
                  _queueError = null;
                });
                _loadQueue();
              },
            ),
            const SizedBox(height: 10),
            if (_queueLoading && queue == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (queue != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StationVehicleType.values
                    .map(
                      (type) => Chip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          '${type.label}: ${queue.counts[type] ?? 0} waiting',
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              if (myEntry != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'In queue — position #${myEntry.position ?? '–'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        'Checked in at ${_timeFormat.format(myEntry.checkedInAt)} · ${myEntry.vehicleType.label}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_queueError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _queueError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canJoin ? _checkIn : null,
                      icon: _joining
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Join queue'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: myEntry != null && !_leaving
                          ? _checkOut
                          : null,
                      icon: const Icon(Icons.logout),
                      label: const Text('Leave queue'),
                    ),
                  ),
                ],
              ),
              if (queue.nextWaitingVehicles.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Next waiting vehicles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ...queue.nextWaitingVehicles.take(5).map(
                  (waiting) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            waiting.registrationNumber ??
                                'Plate not recorded',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${waiting.vehicleType.label} · ${_timeFormat.format(waiting.checkedInAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else if (_queueError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _queueError!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadQueue,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry queue'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return StationSectionCard(
      title: 'Verify boarding',
      icon: Icons.qr_code_scanner,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _vehicle == null ? null : _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan ticket QR'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Or enter the short ticket code',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. ABC123',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _verifyCode(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _verifyingCode ? null : _verifyCode,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(84, 48),
                ),
                child: _verifyingCode
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ],
          ),
          if (_manualError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _manualError!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 12),
              ),
            ),
          if (_manualOutcome != null) ...[
            const SizedBox(height: 12),
            VerificationResultCard(outcome: _manualOutcome!),
          ],
          const SizedBox(height: 8),
          const Text(
            'A ticket can be used only once. Each verification is audited on the server.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
