import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _service = LocationService();

  Position? _currentPosition;
  final List<Marker> _markers = [];
  bool _isLoading = true;

  Position? get currentPosition => _currentPosition;
  List<Marker> get markers => _markers;
  bool get isLoading => _isLoading;

  LocationProvider() {
    _init();
  }

  Future<void> _init() async {
    _currentPosition = await _service.getCurrentLocation();
    if (_currentPosition != null) {
      _service.startLiveTracking('user');
      _addMarker('user', LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 'My Location', Colors.blue);
    }
    _isLoading = false;
    notifyListeners();
  }

  void _addMarker(String id, LatLng position, String title, Color color) {
    _markers.add(
      Marker(
        point: position,
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
              child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.location_on, color: color, size: 40),
          ],
        ),
      ),
    );
  }

  void listenToCityLive() {
    _service.getAllCityLocations().listen((locations) {
      _markers.clear();
      if (_currentPosition != null) {
        _addMarker('user', LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 'My Location', Colors.blue);
      }

      for (var loc in locations) {
        Color color = Colors.red;
        String type = loc['type'] ?? 'unknown';

        if (type == 'taxi') {
          color = Colors.yellow;
        } else if (type == 'bus') {
          color = Colors.blue;
        } else if (type == 'hotel') {
          color = Colors.green;
        } else if (type == 'pharmacy') {
          color = Colors.pink;
        } else if (type == 'hospital') {
          color = Colors.red;
        } else if (type == 'tourism') {
          color = Colors.orange;
        }

        _addMarker(
          loc['id'] ?? UniqueKey().toString(),
          LatLng(loc['latitude'] as double, loc['longitude'] as double),
          loc['name'] ?? type.toUpperCase(),
          color
        );
      }
      notifyListeners();
    });
  }

  Future<void> updateStaticLocation(String type, String name, double lat, double lng) async {
    await _service.saveStaticLocation('${type}_locations', name, {
      'type': type,
      'name': name,
      'latitude': lat,
      'longitude': lng,
    });
    await _service.saveStaticLocation('locations', name, {
      'type': type,
      'name': name,
      'latitude': lat,
      'longitude': lng,
    });
  }
}
