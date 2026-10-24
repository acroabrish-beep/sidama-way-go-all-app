import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/logger.dart';
import '../models/citizen_report_model.dart';
import '../providers/auth_provider.dart';
import '../services/api/base_api_service.dart';
import '../services/api/citizen_reporting_api_service.dart';
import '../services/realtime_service.dart';
import '../widgets/realtime_indicator.dart';

class CitizenReportsAdminScreen extends StatefulWidget {
  const CitizenReportsAdminScreen({super.key});

  @override
  State<CitizenReportsAdminScreen> createState() =>
      _CitizenReportsAdminScreenState();
}

class _CitizenReportsAdminScreenState extends State<CitizenReportsAdminScreen> {
  static const _pollInterval = Duration(seconds: 5);

  final CitizenReportingApiService _api = CitizenReportingApiService();
  final Map<String, CitizenReport> _reports = {};

  RealtimeService<ReportsPage>? _realtime;
  RealtimeStatus _realtimeStatus = RealtimeStatus.idle;
  String? _statusFilter;
  DateTime? _since;
  String? _errorMessage;
  String? _updatingId;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _realtime?.dispose();
    super.dispose();
  }

  void _startPolling() {
    final uid = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userModel?.uid;
    _realtime?.dispose();
    _realtime = null;

    if (uid == null) {
      _initialLoading = false;
      _errorMessage = 'Sign in with an administrator account to view reports.';
      return;
    }

    final service = RealtimeService<ReportsPage>(
      fetch: () => _api.getReportsForAdmin(
        status: _statusFilter,
        updatedSince: _since,
      ),
      onData: (page) {
        if (!mounted) return;
        setState(() {
          if (_statusFilter == null) {
            // Incremental view: merge new and changed rows.
            _since = page.serverTime;
            for (final report in page.reports) {
              _reports[report.id] = report;
            }
          } else {
            // A filtered view is a full snapshot, so rows that leave the
            // filter disappear instead of lingering on screen.
            _since = null;
            _reports
              ..clear()
              ..addEntries(
                page.reports.map((report) => MapEntry(report.id, report)),
              );
          }
          _initialLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _initialLoading = false;
          _errorMessage = error is ApiException
              ? error.message
              : 'Could not load citizen reports.';
        });
      },
      onStatusChanged: (status) {
        if (!mounted) return;
        setState(() => _realtimeStatus = status);
      },
      interval: _pollInterval,
    );
    _realtime = service;
    service.start();
  }

  void _selectFilter(String? status) {
    if (_statusFilter == status) return;
    setState(() {
      _statusFilter = status;
      _reports.clear();
      _since = null;
      _initialLoading = true;
      _errorMessage = null;
    });
    _startPolling();
  }

  Future<void> _retry() async {
    setState(() {
      _errorMessage = null;
      _initialLoading = true;
    });
    if (_realtime == null) {
      _startPolling();
    } else {
      await _realtime!.refreshNow();
    }
  }

  Future<void> _applyUpdate(
    CitizenReport report, {
    String? status,
    String? finalCategory,
    required String successMessage,
  }) async {
    setState(() => _updatingId = report.id);
    try {
      final updated = await _api.updateReport(
        reportId: report.id,
        status: status,
        finalCategory: finalCategory,
      );
      if (!mounted) return;
      setState(() {
        final leavesFilter =
            _statusFilter != null &&
            CitizenReport.statusToString(updated.status) != _statusFilter;
        if (leavesFilter) {
          _reports.remove(updated.id);
        } else {
          _reports[updated.id] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (error) {
      AppLogger.error('Report update failed', error: error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the report.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _showCategoryDialog(CitizenReport report) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Override category'),
        children: [
          for (final category in CitizenReport.categories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, category),
              child: Text(CitizenReport.categoryLabel(category)),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    await _applyUpdate(
      report,
      finalCategory: selected,
      successMessage:
          'Category set to ${CitizenReport.categoryLabel(selected).toLowerCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Reports'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [RealtimeIndicator(status: _realtimeStatus)],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody(reports)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <(String, String?)>[
      ('All', null),
      ('Pending', 'pending'),
      ('In progress', 'in_progress'),
      ('Resolved', 'resolved'),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, value) = filters[index];
          return ChoiceChip(
            label: Text(label),
            selected: _statusFilter == value,
            onSelected: (_) => _selectFilter(value),
          );
        },
      ),
    );
  }

  Widget _buildBody(List<CitizenReport> reports) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reports.isEmpty) {
      if (_errorMessage != null) {
        return _messageState(
          icon: Icons.cloud_off,
          title: 'Could not load citizen reports',
          message: _errorMessage!,
          actionLabel: 'Retry',
          onAction: _retry,
        );
      }
      return _messageState(
        icon: Icons.inbox_outlined,
        title: 'No reports to show',
        message: _statusFilter == null
            ? 'Citizen reports will appear here as soon as they are submitted.'
            : 'No reports currently have this status.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _realtime?.refreshNow() ?? Future<void>.value(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: reports.length,
        itemBuilder: (context, index) => _buildReportCard(reports[index]),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(CitizenReport report) {
    final urgency = report.effectiveUrgency;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    CitizenReport.categoryLabel(report.effectiveCategory),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusChip(report.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _tag(
                  urgency == null
                      ? 'AI triage pending'
                      : CitizenReport.urgencyLabel(urgency),
                  _urgencyColor(urgency),
                ),
                if (report.aiLanguage != null)
                  _tag(
                    CitizenReport.languageLabel(report.aiLanguage),
                    Colors.blueGrey,
                  ),
                if (report.finalCategory != null)
                  _tag('Category overridden', Colors.indigo),
              ],
            ),
            if (report.hasAiSummary) ...[
              const SizedBox(height: 10),
              Text(
                'AI summary (English)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(report.aiSummary!),
            ],
            if (report.description != null &&
                report.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                report.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
            if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report.photoUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Row(
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Photo unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${report.latitude.toStringAsFixed(5)}, '
                    '${report.longitude.toStringAsFixed(5)} · '
                    '${_formatDate(report.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                if (report.aiStatus == 'failed' || report.aiStatus == 'skipped')
                  Text(
                    'AI ${report.aiStatus}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                if (_updatingId == report.id)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Update report',
                    onSelected: (value) {
                      if (value == 'override_category') {
                        _showCategoryDialog(report);
                        return;
                      }
                      _applyUpdate(
                        report,
                        status: value,
                        successMessage:
                            'Status set to ${_statusLabel(value).toLowerCase()}',
                      );
                    },
                    itemBuilder: (context) => [
                      for (final status in const [
                        'pending',
                        'in_progress',
                        'resolved',
                      ])
                        if (status !=
                            CitizenReport.statusToString(report.status))
                          PopupMenuItem(
                            value: status,
                            child: Text(
                              'Mark ${_statusLabel(status).toLowerCase()}',
                            ),
                          ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'override_category',
                        child: Text('Override category…'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ReportStatus status) {
    final (label, color) = switch (status) {
      ReportStatus.pending => ('Pending', Colors.orange),
      ReportStatus.inProgress => ('In progress', Colors.blue),
      ReportStatus.resolved => ('Resolved', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.deepOrange;
      case 'low':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Pending';
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
