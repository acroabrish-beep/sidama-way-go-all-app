import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/utils/logger.dart';
import '../models/admin_overview_models.dart';
import '../models/user_model.dart';
import '../services/api/admin_overview_api_service.dart';
import '../services/api/base_api_service.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/dashboard_base.dart';
import '../widgets/glass_card.dart';
import '../widgets/role_protected_widget.dart';
import 'citizen_reports_admin_screen.dart';
import 'emergency_dashboard.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final AdminOverviewApiService _api = AdminOverviewApiService();

  AdminOverview? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final overview = await _api.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } on ApiException catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load the super admin overview',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _loading = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected super admin overview failure',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load the admin overview. Please try again.';
        _loading = false;
      });
    }
  }

  String _friendlyError(ApiException error) {
    if (error.isUnauthorized) {
      return 'Your session has expired. Sign in again to load city metrics.';
    }
    if (error.isForbidden) {
      return 'This account does not have super administrator access.';
    }
    if (error.isTimeout || error.isNetworkUnavailable) {
      return 'Cannot reach the backend. Check your connection and retry.';
    }
    if ((error.statusCode ?? 0) >= 500) {
      return 'The admin overview service is unavailable. Retry in a moment.';
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      allowedRoles: const [UserRole.superAdmin],
      child: DashboardBase(
        title: 'Super Admin Dashboard',
        actions: [
          IconButton(
            tooltip: 'Refresh city metrics',
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
            padding: EdgeInsets.only(bottom: 16),
            child: AIInsightsCard(
              dashboardContext: 'super_admin',
              title: '🤖 City-Wide AI Insights',
            ),
          ),
          const Text(
            'City Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live counts from the Supabase get_admin_overview RPC.',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if (_loading)
            _buildLoading()
          else if (_error != null)
            _buildError()
          else if (_overview != null) ...[
            _buildStatGrid(_overview!),
            const SizedBox(height: 12),
            _buildEmergencyShortcut(),
            const SizedBox(height: 24),
            const Text(
              'Revenue Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildRevenueChart(_overview!),
            const SizedBox(height: 24),
            _buildLatestReports(_overview!),
            const SizedBox(height: 12),
            Text(
              'Last refreshed ${_formatDateTime(_overview!.generatedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return GlassCard(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Loading city metrics from the backend…',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return GlassCard(
      color: Colors.redAccent,
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'City metrics are unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(AdminOverview overview) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          _formatInt(overview.usersTotal),
          Icons.people,
          Colors.lightBlueAccent,
        ),
        _buildStatCard(
          'Citizen Reports',
          _formatInt(overview.citizenReportsTotal),
          Icons.report_problem,
          Colors.amberAccent,
        ),
        _buildStatCard(
          'Pending Reports',
          _formatInt(overview.citizenReportsPending),
          Icons.pending_actions,
          Colors.orangeAccent,
        ),
        _buildStatCard(
          'Tickets Issued',
          _formatInt(overview.ticketsTotal),
          Icons.confirmation_number,
          Colors.greenAccent,
        ),
        _buildStatCard(
          'Tickets Paid',
          _formatInt(overview.ticketsPaid),
          Icons.verified,
          Colors.tealAccent,
        ),
        _buildStatCard(
          'Paid Revenue',
          'ETB ${_formatMoney(overview.paidRevenueEtb)}',
          Icons.account_balance_wallet,
          Colors.lightGreenAccent,
        ),
        _buildStatCard(
          'Active Drivers',
          _formatInt(overview.activeDrivers),
          Icons.local_taxi,
          Colors.cyanAccent,
        ),
        _buildStatCard(
          'Hotel Reservations',
          _formatInt(overview.hotelReservationsTotal),
          Icons.hotel,
          Colors.purpleAccent,
        ),
        _buildStatCard(
          'SOS Incidents',
          _formatInt(overview.sosIncidentsTotal),
          Icons.emergency,
          Colors.redAccent,
        ),
        _buildStatCard(
          'Vehicles Waiting',
          _formatInt(overview.queueWaiting),
          Icons.hourglass_top,
          Colors.deepOrangeAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyShortcut() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.emergency, color: Colors.redAccent),
        title: const Text(
          'Emergency Response',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Review live SOS incidents and advance their status.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyDashboard()),
          );
        },
      ),
    );
  }

  Widget _buildRevenueChart(AdminOverview overview) {
    final days = overview.revenueByDay;
    if (days.isEmpty) {
      return const GlassCard(
        height: 180,
        child: Center(
          child: Text(
            'No revenue history was returned by the backend.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final total = days.fold<double>(0, (sum, day) => sum + day.amountEtb);
    if (total == 0) {
      return const GlassCard(
        height: 180,
        child: Center(
          child: Text(
            'No paid revenue recorded in the last 7 days.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxAmount = days.fold<double>(
      0,
      (max, day) => day.amountEtb > max ? day.amountEtb : max,
    );
    final spots = <FlSpot>[
      for (var index = 0; index < days.length; index++)
        FlSpot(index.toDouble(), days[index].amountEtb),
    ];

    return GlassCard(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 days · ETB ${_formatMoney(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxAmount == 0 ? 1 : maxAmount * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime.tryParse(days[index].date);
                        if (date == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.greenAccent,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestReports(AdminOverview overview) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Latest Citizen Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CitizenReportsAdminScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View all'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (overview.latestReports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No citizen reports have been submitted yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...overview.latestReports.map(_buildReportTile),
        ],
      ),
    );
  }

  Widget _buildReportTile(AdminLatestReport report) {
    final statusColor = _statusColor(report.status);
    final urgencyColor = _urgencyColor(report.urgency);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.2),
        child: Icon(Icons.report_problem_outlined, color: statusColor),
      ),
      title: Text(
        _label(report.category),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.description != null) ...[
            const SizedBox(height: 4),
            Text(
              report.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(_label(report.status), statusColor),
              if (report.urgency != null)
                _chip('Urgency: ${_label(report.urgency!)}', urgencyColor),
              if (report.createdAt != null)
                Text(
                  _formatDateTime(report.createdAt!),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'in_progress':
      case 'under_review':
      case 'assigned':
        return Colors.lightBlueAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  Color _urgencyColor(String? urgency) {
    switch ((urgency ?? '').toLowerCase()) {
      case 'critical':
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  String _label(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _formatInt(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    return '${_formatInt(int.parse(parts[0]))}.${parts[1]}';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
