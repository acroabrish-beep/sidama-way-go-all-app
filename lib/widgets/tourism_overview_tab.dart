import 'package:flutter/material.dart';

import '../services/api/base_api_service.dart';
import '../services/api/tourism_api_service.dart';
import 'glass_card.dart';

class TourismOverviewTab extends StatefulWidget {
  const TourismOverviewTab({super.key});

  @override
  State<TourismOverviewTab> createState() => _TourismOverviewTabState();
}

class _TourismOverviewTabState extends State<TourismOverviewTab> {
  final TourismApiService _service = TourismApiService();
  List<int>? _counts;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (sites, hotels) = await (
        _service.getTouristSites(),
        _service.getHotels(),
      ).wait;
      if (!mounted) return;
      final roomCount = hotels.fold<int>(
        0,
        (total, hotel) => total + hotel.rooms.length,
      );
      final availableRooms = hotels.fold<int>(
        0,
        (total, hotel) => total + hotel.availableRooms.length,
      );
      setState(() {
        _counts = [sites.length, hotels.length, roomCount, availableRooms];
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_counts == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
      final message = error is ApiException
          ? error.message
          : 'Could not refresh tourism statistics.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _counts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_counts == null) {
      final message = _error is ApiException
          ? (_error as ApiException).message
          : 'Could not load tourism statistics.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _retry,
                style:
                    OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _statCard(
                'Tourist sites',
                _counts![0].toString(),
                Icons.landscape,
                Colors.tealAccent,
              ),
              _statCard(
                'Hotels',
                _counts![1].toString(),
                Icons.hotel,
                Colors.purpleAccent,
              ),
              _statCard(
                'Hotel rooms',
                _counts![2].toString(),
                Icons.meeting_room,
                Colors.blueAccent,
              ),
              _statCard(
                'Available rooms',
                _counts![3].toString(),
                Icons.event_available,
                Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'PHASE 2 COVERAGE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const GlassCard(
            padding: EdgeInsets.all(14),
            child: Text(
              'Tourist sites and hotels are served directly by Supabase. '
              'Tour packages, guides, operators, tour bookings, contract rides, '
              'events, reviews, airports, and emergency contacts still depend '
              'on legacy Firestore data and are disabled until a later phase.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
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
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
