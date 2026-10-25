import 'package:flutter/material.dart';

import '../../core/utils/logger.dart';
import '../../models/station_ticket_models.dart';
import '../../services/api/base_api_service.dart';
import '../../services/api/station_ticket_api_service.dart';
import 'destination_select_screen.dart';
import 'station_ticket_history_screen.dart';
import 'station_ui.dart';

class StationTicketsScreen extends StatefulWidget {
  const StationTicketsScreen({super.key});

  @override
  State<StationTicketsScreen> createState() => _StationTicketsScreenState();
}

class _StationTicketsScreenState extends State<StationTicketsScreen> {
  final StationTicketApiService _api = StationTicketApiService();
  late Future<List<Station>> _stationsFuture;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _api.getStations();
  }

  Future<void> _refresh() async {
    final future = _api.getStations();
    setState(() {
      _stationsFuture = future;
    });
    await future.then<void>(
      (_) {},
      onError: (Object error) {
        AppLogger.warning('Station list refresh failed: $error');
      },
    );
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      if (error.isTimeout) {
        return 'The server took too long to respond. Check your connection and tap Try Again.';
      }
      if (error.isNetworkUnavailable) {
        return 'Cannot reach the station service. Check your connection and tap Try Again.';
      }
      if (error.statusCode == 401) {
        return 'Please sign in again to load stations.';
      }
      if (error.statusCode == 403) {
        return 'This account does not have access to the station list.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'The station service is temporarily unavailable. Tap Try Again.';
      }
      return error.message;
    }
    return 'Could not load stations. Check your connection and tap Try Again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Station Tickets'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'My tickets',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StationTicketHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Station>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return StationErrorView(
                title: 'Unable to load stations',
                message: _friendlyError(snapshot.error),
                onRetry: _refresh,
              );
            }
            final stations = snapshot.data ?? const <Station>[];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildIntroCard(),
                const SizedBox(height: 8),
                _buildMyTicketsTile(),
                const SizedBox(height: 20),
                const Text(
                  'Starting station',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose where your journey starts. The fare is confirmed by the server before payment.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (stations.isEmpty)
                  const StationEmptyView(
                    icon: Icons.location_off,
                    title: 'No stations configured',
                    message:
                        'The station catalog is empty. A taxi administrator must import the official station list before tickets can be sold.',
                  )
                else
                  ...stations.map(
                    (station) => _StationCard(
                      station: station,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DestinationSelectScreen(station: station),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.confirmation_number, color: Colors.white, size: 38),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buy a station ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Official fixed fares, signed QR tickets and a downloadable receipt.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTile() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
        ),
        title: const Text(
          'My tickets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Open tickets, QR codes and receipts'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StationTicketHistoryScreen()),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.onTap});

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
        ),
        title: Text(
          station.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: station.nameAm == null ? null : Text(station.nameAm!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
