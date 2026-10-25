import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/emergency_sos_models.dart';
import '../models/user_model.dart';
import '../services/api/base_api_service.dart';
import '../services/api/emergency_api_service.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import '../widgets/role_protected_widget.dart';

class EmergencyDashboard extends StatefulWidget {
  const EmergencyDashboard({super.key});

  @override
  State<EmergencyDashboard> createState() => _EmergencyDashboardState();
}

class _EmergencyDashboardState extends State<EmergencyDashboard> {
  final EmergencyApiService _service = EmergencyApiService();

  List<EmergencyIncidentModel> _recent = const [];
  List<EmergencyIncidentModel> _active = const [];
  var _loading = true;
  String? _error;
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.listIncidents(limit: 50),
        _service.listActiveIncidents(),
      ]);
      if (!mounted) return;
      setState(() {
        _recent = results[0];
        _active = results[1];
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load emergency incidents. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _advance(EmergencyIncidentModel incident) async {
    final nextStatus = _nextStatus(incident.status);
    if (nextStatus == null || _updatingId != null) return;

    setState(() => _updatingId = incident.id);
    try {
      final assigneeUid = FirebaseAuth.instance.currentUser?.uid;
      final updated = await _service.updateStatus(
        incidentId: incident.id,
        status: nextStatus,
        assigneeFirebaseUid:
            nextStatus == 'acknowledged' || nextStatus == 'in_progress'
            ? assigneeUid
            : null,
      );
      if (!mounted) return;
      setState(() {
        _recent = _recent
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
        _active = _active
            .where((item) => item.id != updated.id)
            .toList(growable: false);
        if (updated.isActive) {
          _active = [updated, ..._active];
        }
        _updatingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incident moved to ${updated.statusLabel}.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _updatingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the incident. Please retry.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'reported':
        return 'acknowledged';
      case 'acknowledged':
        return 'in_progress';
      case 'in_progress':
        return 'resolved';
      default:
        return null;
    }
  }

  String? _actionLabel(String status) {
    switch (status) {
      case 'reported':
        return 'ACKNOWLEDGE';
      case 'acknowledged':
        return 'DISPATCH';
      case 'in_progress':
        return 'RESOLVE';
      default:
        return null;
    }
  }

  Color _actionColor(String status) {
    switch (status) {
      case 'reported':
        return Colors.amber;
      case 'acknowledged':
        return Colors.orange;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin, UserRole.emergencyAdmin],
      child: DashboardBase(
        title: 'Emergency Response',
        actions: [
          IconButton(
            tooltip: 'Refresh incidents',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: AIInsightsCard(
              dashboardContext: 'emergency',
              title: '🤖 Emergency AI Insights',
            ),
          ),
          const Text(
            'Live Emergency Incidents',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live counts from Supabase. Citizens see only their own requests; '
            'emergency staff see every incident.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (_error != null) _buildError(),
          if (_loading && _recent.isEmpty)
            const GlassCard(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else ...[
            _buildStats(),
            const SizedBox(height: 20),
            const Text(
              'Recent Incidents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              const GlassCard(
                child: Text(
                  'No emergency incidents have been reported yet.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._recent.map(_buildIncidentTile),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return GlassCard(
      color: Colors.redAccent,
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final critical = _active.where((incident) => incident.isCritical).length;
    final awaiting = _active
        .where((incident) => incident.status == 'reported')
        .length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.9,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _statCard(
          'Active Requests',
          '${_active.length}',
          Icons.warning_amber,
          Colors.redAccent,
        ),
        _statCard(
          'Critical Active',
          '$critical',
          Icons.priority_high,
          Colors.orangeAccent,
        ),
        _statCard(
          'Awaiting Ack.',
          '$awaiting',
          Icons.pending_actions,
          Colors.amberAccent,
        ),
        _statCard(
          'Recent Loaded',
          '${_recent.length}',
          Icons.history,
          Colors.lightBlueAccent,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
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
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTile(EmergencyIncidentModel incident) {
    final (icon, color) = _typeVisual(incident.emergencyType);
    final actionLabel = _actionLabel(incident.status);
    final isUpdating = _updatingId == incident.id;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (incident.incidentCode.isNotEmpty)
                      Text(
                        incident.incidentCode,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              _statusChip(incident.statusLabel, _statusColor(incident.status)),
            ],
          ),
          if (incident.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              incident.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(
                incident.priorityLabel,
                incident.isCritical ? Colors.redAccent : Colors.white70,
              ),
              Text(
                incident.coordinatesLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (incident.createdAt != null)
                Text(
                  _formatDateTime(incident.createdAt!),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isUpdating ? null : () => _advance(incident),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _actionColor(incident.status),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        actionLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'reported':
        return Colors.amberAccent;
      case 'acknowledged':
        return Colors.orangeAccent;
      case 'in_progress':
        return Colors.lightBlueAccent;
      case 'resolved':
      case 'closed':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  (IconData, Color) _typeVisual(String type) {
    switch (type) {
      case 'ambulance':
        return (Icons.local_hospital, Colors.redAccent);
      case 'police':
        return (Icons.local_police, Colors.lightBlueAccent);
      case 'fire':
        return (Icons.local_fire_department, Colors.orangeAccent);
      case 'road_assist':
        return (Icons.car_crash, Colors.yellowAccent);
      default:
        return (Icons.emergency, Colors.redAccent);
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
