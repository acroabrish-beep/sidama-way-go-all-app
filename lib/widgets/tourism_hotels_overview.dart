import 'package:flutter/material.dart';

import '../models/hotel_tourism_models.dart';
import '../services/api/base_api_service.dart';
import '../services/api/tourism_api_service.dart';
import 'glass_card.dart';

/// Read-only hotel/room overview for tourism dashboards. Hotel staff manage
/// hotels from [HotelDashboard]; tourism staff can only read them under RLS.
class TourismHotelsOverview extends StatefulWidget {
  const TourismHotelsOverview({super.key});

  @override
  State<TourismHotelsOverview> createState() => _TourismHotelsOverviewState();
}

class _TourismHotelsOverviewState extends State<TourismHotelsOverview> {
  final TourismApiService _service = TourismApiService();
  List<HotelModel>? _hotels;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hotels = await _service.getHotels();
      if (!mounted) return;
      setState(() {
        _hotels = hotels;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (_hotels == null) {
        setState(() {
          _error = error;
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
      final message = error is ApiException
          ? error.message
          : 'Could not refresh hotels. Please try again.';
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
    if (_loading && _hotels == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hotels == null) {
      final message = _error is ApiException
          ? (_error as ApiException).message
          : 'Could not load hotels. Please try again.';
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
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    final hotels = _hotels!;
    final roomCount =
        hotels.fold<int>(0, (total, hotel) => total + hotel.rooms.length);
    final availableCount = hotels.fold<int>(
      0,
      (total, hotel) => total + hotel.availableRooms.length,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summary('Hotels', hotels.length.toString()),
                _summary('Rooms', roomCount.toString()),
                _summary('Available', availableCount.toString()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (hotels.isEmpty)
            const GlassCard(
              child: Text(
                'No hotels are published yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...hotels.map(_buildHotelCard),
        ],
      ),
    );
  }

  Widget _summary(String label, String value) {
    return Column(
      children: [
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
        ),
      ],
    );
  }

  Widget _buildHotelCard(HotelModel hotel) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hotel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '★ ${hotel.ratingLabel}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hotel.locationLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (hotel.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hotel.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: 8),
          if (hotel.rooms.isEmpty)
            const Text(
              'No rooms listed.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            )
          else
            ...hotel.rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 15,
                      color: room.status == 'available'
                          ? Colors.greenAccent
                          : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${room.roomNumber} · ${room.roomType} · '
                        'sleeps ${room.capacity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      room.rateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      room.statusLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
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
}
