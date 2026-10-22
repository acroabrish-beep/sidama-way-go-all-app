import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(7.0504, 38.4955); // Default Hawassa
  bool _isLoading = true;

  final Set<String> _selectedFilters = {"Me", "Taxi", "Bus", "Hotel", "Pharmacy", "Hospital", "Eco-Shine"};

  final Map<String, List<Marker>> _markers = {
    "Taxi": [],
    "Bus": [],
    "Hotel": [],
    "Pharmacy": [],
    "Hospital": [],
    "Eco-Shine": [],
  };

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _listenToMarkers();
  }

  @override
  void dispose() {
    for (var sub in _subs) { sub.cancel(); }
    super.dispose();
  }

  void _listenToMarkers() {
    _listenToCategory("locations", "Taxi", Icons.local_taxi, Colors.orange);
    _listenToCategory("locations", "Bus", Icons.directions_bus, Colors.blue);
    _listenToCategory("locations", "Hotel", Icons.hotel, Colors.purple);
    _listenToCategory("locations", "Pharmacy", Icons.local_pharmacy, Colors.red);
    _listenToCategory("locations", "Hospital", Icons.local_hospital, Colors.red);
    _listenToCategory("locations", "Eco-Shine", Icons.wb_sunny, Colors.green);
  }

  void _listenToCategory(String collection, String category, IconData icon, Color color) {
    final sub = FirebaseFirestore.instance.collection(collection)
        .where("category", isEqualTo: category)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _markers[category] = snap.docs.map((doc) {
          final data = doc.data();
          return Marker(
            point: LatLng((data['latitude'] ?? 0.0).toDouble(), (data['longitude'] ?? 0.0).toDouble()),
            width: 40, height: 40,
            child: GestureDetector(
              onTap: () => _showMarkerInfo(data['name'] ?? category),
              child: Icon(icon, color: color, size: 30),
            ),
          );
        }).toList();
      });
    });
    _subs.add(sub);
  }



  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_userLocation, 14);
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showMarkerInfo(String name) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.navigation),
                label: const Text("Navigate"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];

    if (_selectedFilters.contains("Me")) {
      markers.add(
        Marker(
          point: _userLocation,
          width: 40,
          height: 40,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
        ),
      );
    }

    _markers.forEach((category, list) {
      if (_selectedFilters.contains(category)) {
        markers.addAll(list);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("City Map"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sidama.sidama_way_go',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Category Filter Chips
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: _selectedFilters.union(_markers.keys.toSet()).map((category) {
                  final isSelected = _selectedFilters.contains(category);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedFilters.add(category);
                          } else {
                            _selectedFilters.remove(category);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFF2E7D32),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),

          // Coordinates at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white.withValues(alpha: 0.9),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "Lat: ${_userLocation.latitude.toStringAsFixed(4)}, Lng: ${_userLocation.longitude.toStringAsFixed(4)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
