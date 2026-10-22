import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/ai_insights_card.dart';
import '../../widgets/realtime_indicator.dart';
import 'admin_station_catalog_screen.dart';
import 'driver_station_screen.dart';
import 'station_ui.dart';

class StationMetricsOverview extends StatefulWidget {
  const StationMetricsOverview({super.key});

  @override
  State<StationMetricsOverview> createState() => _StationMetricsOverviewState();
}

class _StationMetricsOverviewState extends State<StationMetricsOverview> {
  final StationTicketApiService _api = StationTicketApiService();
  final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  final DateFormat _hourFormat = DateFormat('HH:mm');

  StationMetrics? _metrics;
  RealtimeService<StationMetrics>? _realtime;
  RealtimeStatus _realtimeStatus = RealtimeStatus.idle;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _realtime?.dispose();
    _api.dispose();
    super.dispose();
  }

  void _startPolling() {
    _realtime?.dispose();
    final service = RealtimeService<StationMetrics>(
      fetch: _api.getTaxiMetrics,
      onData: (metrics) {
        if (!mounted) return;
        setState(() {
          _metrics = metrics;
          _error = null;
          _loading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error is ApiException
              ? error.message
              : 'Unable to load station metrics.';
          _loading = false;
        });
      },
      onStatusChanged: (status) {
        if (!mounted) return;
        setState(() => _realtimeStatus = status);
      },
      interval: const Duration(seconds: 5),
    );
    _realtime = service;
    service.start();
  }

  Future<void> _refresh() async {
    if (_realtime == null) {
      _startPolling();
      return;
    }
    await _realtime!.refreshNow();
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AIInsightsCard(
              dashboardContext: 'taxi_services',
              title: '🤖 Taxi Services AI Insights',
            ),
            const SizedBox(height: 12),
            _buildOperationsCard(),
            const SizedBox(height: 16),
            if (_loading && _metrics == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _metrics == null)
              StationErrorView(
                title: 'Metrics unavailable',
                message: _error!,
                onRetry: _retry,
              )
            else if (_metrics != null) ...[
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Latest refresh failed: $_error',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
              _buildStatsGrid(_metrics!),
              const SizedBox(height: 24),
              _buildHourlyChart(_metrics!),
              const SizedBox(height: 24),
              _buildTopRoutes(_metrics!),
              const SizedBox(height: 24),
              _buildLiveQueue(_metrics!),
              const SizedBox(height: 24),
              _buildReconciliation(_metrics!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Color(0xFF1A237E)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Station operations',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                RealtimeIndicator(status: _realtimeStatus),
                IconButton(
                  tooltip: 'Refresh metrics',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _retry,
                ),
              ],
            ),
            const Text(
              'All figures below come from stored station tickets, verified payments and queue entries. No demo data is included.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStationCatalogScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Stations, tariffs & CSV import'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverStationScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Driver station'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(StationMetrics metrics) {
    final waitingVehicles = metrics.liveQueue.fold<int>(
      0,
      (sum, queue) => sum + queue.count,
    );
    final verificationRate = metrics.verificationRate;
    final cards = [
      _StatData(
        'Tickets today',
        metrics.ticketsSoldToday.toString(),
        Icons.confirmation_number,
        Colors.blue,
      ),
      _StatData(
        'Revenue today',
        'ETB ${_numberFormat.format(metrics.revenueToday)}',
        Icons.payments,
        Colors.indigo,
      ),
      _StatData(
        'Tickets 7d',
        metrics.ticketsSold7d.toString(),
        Icons.calendar_view_week,
        Colors.teal,
      ),
      _StatData(
        'Revenue 7d',
        'ETB ${_numberFormat.format(metrics.revenue7d)}',
        Icons.account_balance_wallet,
        Colors.green,
      ),
      _StatData(
        'Active drivers',
        metrics.activeDrivers.toString(),
        Icons.local_taxi,
        Colors.orange,
      ),
      _StatData(
        'Verified (30d)',
        verificationRate == null
            ? 'No sales'
            : '${(verificationRate * 100).toStringAsFixed(1)}%',
        Icons.verified,
        Colors.purple,
      ),
      _StatData(
        'Vehicles waiting',
        waitingVehicles.toString(),
        Icons.hourglass_top,
        Colors.brown,
      ),
      _StatData(
        'Expired (30d)',
        metrics.expiredTickets.toString(),
        Icons.timer_off,
        Colors.red,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _buildStatCard(cards[index]),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: data.color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: data.color, size: 20),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                data.value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              data.label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart(StationMetrics metrics) {
    final hours = metrics.ticketsPerHour;
    final maxTickets = hours.fold<int>(
      0,
      (max, item) => math.max(max, item.tickets),
    );
    return _sectionCard(
      title: 'Tickets per hour (last 24h)',
      icon: Icons.bar_chart,
      child: hours.isEmpty || maxTickets == 0
          ? const Text(
              'No paid tickets were recorded in the last 24 hours.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY: (maxTickets * 1.2).ceilToDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: math.max(1, (maxTickets / 4).ceilToDouble()),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= hours.length ||
                              index % 6 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _hourFormat.format(hours[index].hour),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < hours.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: hours[index].tickets.toDouble(),
                            color: const Color(0xFF1A237E),
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopRoutes(StationMetrics metrics) {
    return _sectionCard(
      title: 'Top routes (paid tickets, 30 days)',
      icon: Icons.route,
      child: metrics.topRoutes.isEmpty
          ? const Text(
              'No paid tickets in the last 30 days.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : Column(
              children: metrics.topRoutes
                  .map(
                    (route) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.alt_route,
                        size: 18,
                        color: Color(0xFF1A237E),
                      ),
                      title: Text(
                        '${route.from ?? 'Unknown'} → ${route.to ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        '${route.tickets}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildLiveQueue(StationMetrics metrics) {
    return _sectionCard(
      title: 'Live smart queues',
      icon: Icons.people_alt,
      child: metrics.liveQueue.isEmpty
          ? const Text(
              'No vehicles are waiting at any station.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : Column(
              children: metrics.liveQueue
                  .map(
                    (queue) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.directions_car,
                        size: 18,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Text(
                        queue.station ?? 'Unknown station',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(queue.vehicleType.label),
                      trailing: Text(
                        '${queue.count} waiting',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildReconciliation(StationMetrics metrics) {
    final rows = metrics.reconciliation;
    final mismatches = rows.where((row) => row.mismatch).toList();
    return _sectionCard(
      title: 'Payment reconciliation (latest 100)',
      icon: Icons.fact_check,
      child: rows.isEmpty
          ? const Text(
              'No payments have been recorded yet.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mismatches.isEmpty)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF2E7D32),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No mismatches between payments and tickets.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    '${mismatches.length} payment(s) need review. A paid payment must match a paid ticket and the ticket fare.',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...mismatches
                      .take(10)
                      .map(
                        (row) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          title: Text(
                            row.ticketCode ?? 'Ticket not found',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            'Payment ${row.paymentStatus} · '
                            'ETB ${row.paymentAmountEtb?.toStringAsFixed(2) ?? '?'} · '
                            'Ticket ${row.ticketStatus ?? 'missing'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF1A237E)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
