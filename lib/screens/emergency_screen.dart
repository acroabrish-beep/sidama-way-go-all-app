import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/emergency_sos_models.dart';
import '../providers/auth_provider.dart' as custom_auth;
import '../services/api/base_api_service.dart';
import '../services/api/emergency_api_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final EmergencyApiService _service = EmergencyApiService();

  EmergencyIncidentModel? _activeRequest;
  var _restoring = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _restoreActiveRequest();
  }

  Future<void> _restoreActiveRequest() async {
    try {
      final active = await _service.findActiveRequest();
      if (!mounted) return;
      setState(() {
        _activeRequest = active;
        _restoring = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _restoring = false);
    }
  }

  void _showEmergencyDialog(
    BuildContext context,
    EmergencyRequestType type,
    Color color,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm ${type.label} Request'),
        content: const Text(
          'Are you sure you want to send an emergency request? '
          'Help will be dispatched to your GPS location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _sendEmergencyRequest(type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('YES, DISPATCH HELP'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencyRequest(EmergencyRequestType type) async {
    if (_sending) return;
    setState(() => _sending = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = Provider.of<custom_auth.AuthProvider>(
        context,
        listen: false,
      ).userModel;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));

      final incident = await _service.createRequest(
        type: type,
        latitude: position.latitude,
        longitude: position.longitude,
        description: user == null
            ? type.defaultDescription
            : '${type.defaultDescription} Reported by ${user.fullName}.',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _activeRequest = incident);
    } on PermissionDeniedException {
      _finishWithError(
        'Location permission is required to dispatch emergency help.',
      );
    } on LocationServiceDisabledException {
      _finishWithError('Turn on location services and try again.');
    } on TimeoutException {
      _finishWithError(
        'Getting your GPS location timed out. Move to an open area and retry.',
      );
    } on ApiException catch (error) {
      _finishWithError(error.message);
    } catch (error) {
      _finishWithError(
        'The emergency request could not be sent. Please retry.',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _finishWithError(String message) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeRequest;
    if (active != null) {
      return _ActiveEmergencyScreen(
        service: _service,
        initialIncident: active,
        onClose: () => setState(() => _activeRequest = null),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: _restoring
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Checking for an active emergency request...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Tap a button below for immediate assistance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: [
                        _emergencyCard(
                          context,
                          EmergencyRequestType.ambulance,
                          Icons.local_hospital,
                          Colors.red,
                        ),
                        _emergencyCard(
                          context,
                          EmergencyRequestType.police,
                          Icons.local_police,
                          Colors.blue,
                        ),
                        _emergencyCard(
                          context,
                          EmergencyRequestType.fire,
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _emergencyCard(
                          context,
                          EmergencyRequestType.roadAssist,
                          Icons.car_crash,
                          Colors.yellow[800]!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Requests are stored in Supabase. Only you and emergency '
                    'staff can see your request.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _emergencyCard(
    BuildContext context,
    EmergencyRequestType type,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: _sending
            ? null
            : () => _showEmergencyDialog(context, type, color),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              type.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveEmergencyScreen extends StatefulWidget {
  const _ActiveEmergencyScreen({
    required this.service,
    required this.initialIncident,
    required this.onClose,
  });

  final EmergencyApiService service;
  final EmergencyIncidentModel initialIncident;
  final VoidCallback onClose;

  @override
  State<_ActiveEmergencyScreen> createState() => _ActiveEmergencyScreenState();
}

class _ActiveEmergencyScreenState extends State<_ActiveEmergencyScreen> {
  late EmergencyIncidentModel _incident = widget.initialIncident;
  Timer? _timer;
  var _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_incident.isResolved) {
      _timer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _refresh(silent: true),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing || _incident.isResolved) return;
    if (!silent) {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final incident = await widget.service.getRequest(_incident.id);
      if (!mounted) return;
      setState(() {
        _incident = incident;
        _refreshing = false;
        _error = null;
      });
      if (incident.isResolved) _timer?.cancel();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      if (!silent) setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      if (!silent) {
        setState(
          () =>
              _error = 'Could not refresh the request. Check your connection.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = _incident;
    if (incident.isResolved) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E7D32),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Resolved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Emergency staff marked incident ${incident.incidentCode.isEmpty ? incident.id : incident.incidentCode} as ${incident.statusLabel.toLowerCase()}.',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('BACK TO EMERGENCY HOME'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFC62828),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(incident.typeLabel),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Icon(Icons.emergency, color: Colors.white, size: 72),
              const SizedBox(height: 24),
              const Text(
                'HELP IS ON THE WAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _detail('Type', incident.typeLabel),
              _detail('Status', incident.statusLabel),
              _detail('Priority', incident.priorityLabel),
              if (incident.incidentCode.isNotEmpty)
                _detail('Incident', incident.incidentCode),
              _detail('Location', incident.coordinatesLabel),
              if (incident.createdAt != null)
                _detail('Reported', _formatDateTime(incident.createdAt!)),
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  incident.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              const LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency services have been notified. This screen checks '
                'for status updates every 10 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: widget.onClose,
                child: const Text(
                  'MINIMIZE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
