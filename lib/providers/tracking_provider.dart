import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class TrackingProvider with ChangeNotifier {
  LatLng? _currentPosition;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;

  LatLng? _navigationDestination;

  LatLng? get currentPosition => _currentPosition;
  List<Marker> get markers => _markers;
  List<Polyline> get polylines => _polylines;
  bool get isTracking => _isTracking;
  LatLng? get navigationDestination => _navigationDestination;

  TrackingProvider() {
    // Default to Hawassa until real position is found
    _currentPosition = const LatLng(7.0504, 38.4955);
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _isTracking = true;

    // Initial position
    Position position = await Geolocator.getCurrentPosition();
    _updatePosition(position);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updatePosition(position);
    });

    notifyListeners();
  }

  void _updatePosition(Position position) {
    _currentPosition = LatLng(position.latitude, position.longitude);
    _markers.clear();
    _markers.add(
      Marker(
        point: _currentPosition!,
        width: 40,
        height: 40,
        child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 40),
      ),
    );

    if (_navigationDestination != null) {
      _updateNavigationPolyline();
    }

    notifyListeners();
  }

  void _updateNavigationPolyline() {
    _polylines.clear();
    if (_currentPosition != null && _navigationDestination != null) {
      _polylines.add(
        Polyline(
          points: [_currentPosition!, _navigationDestination!],
          color: Colors.blue,
          strokeWidth: 4,
        ),
      );
    }
  }

  void navigateTo(LatLng dest) {
    _navigationDestination = dest;
    _updateNavigationPolyline();
    notifyListeners();
  }

  void clearNavigation() {
    _navigationDestination = null;
    _polylines.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
