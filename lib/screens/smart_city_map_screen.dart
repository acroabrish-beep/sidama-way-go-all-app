import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide MapEvent;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/glass_card.dart';
import '../utils/language_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../models/city_os_models.dart' hide RideRequest;
import '../models/taxi_models.dart';
import '../models/map_models.dart';
import '../services/taxi_service.dart';
import '../models/emergency_models.dart';
import '../services/emergency_dispatch_service.dart';
import 'crud_list_screen.dart';

class SmartCityMapScreen extends StatefulWidget {
  const SmartCityMapScreen({super.key});

  @override
  State<SmartCityMapScreen> createState() => _SmartCityMapScreenState();
}

class _SmartCityMapScreenState extends State<SmartCityMapScreen> {
  final MapController _mapController = MapController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final TaxiService _taxiService = TaxiService();
  final EmergencyDispatchService _emergencyService = EmergencyDispatchService();

  final LatLng _hawassaCenter = const LatLng(7.0622, 38.4763);
  LatLng? _currentLocation;

  bool _isListening = false;
  String _searchQuery = "";
  String _aiResponse = "";

  // GIS Layer visibility
  final Map<String, bool> _layers = {
    'Terminals': true,
    'Taxis': true,
    'Hotels': true,
    'Tourism': true,
    'Hospitals': true,
    'Pharmacies': true,
    'Emergency': true,
    'Government': true,
    'Eco-Shine': true,
    'Analytics': false,
  };

  final Map<String, List<Marker>> _markerData = {
    'Terminals': [],
    'Taxis': [],
    'Hotels': [],
    'Tourism': [],
    'Hospitals': [],
    'Pharmacies': [],
    'Emergency': [],
    'Government': [],
    'Eco-Shine': [],
    'Analytics': [],
  };

  List<Polyline> _polylines = [];

  final Map<String, StreamSubscription?> _layerSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initGISStreams();
    _startLocationUpdatesIfDriver();
  }

  void _startLocationUpdatesIfDriver() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null && (user.role == UserRole.taxiAdmin || user.role == UserRole.taxiDriver)) {
      Timer.periodic(const Duration(seconds: 15), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        try {
          final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
          await FirebaseFirestore.instance.collection(CityOSCollection.drivers).doc(user.uid).update({
            'location': GeoPoint(pos.latitude, pos.longitude),
            'lastUpdate': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      });
    }
  }

  Future<void> _triggerSOS() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final pos = await Geolocator.getCurrentPosition();

    await FirebaseFirestore.instance.collection(CityOSCollection.emergencyRequests).add({
      'userId': user?.uid ?? 'anonymous',
      'userName': user?.fullName ?? 'Anonymous',
      'location': GeoPoint(pos.latitude, pos.longitude),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'Map SOS',
      'locationName': 'GPS Trigger',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Alert Sent to Emergency Hub!'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    for (var sub in _layerSubscriptions.values) {
      sub?.cancel();
    }
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 14.0);
    }
  }

  void _initGISStreams() {
    _layers.forEach((key, visible) {
      if (visible) _updateSubscription(key, true);
    });
  }

  void _updateSubscription(String layer, bool active) {
    if (active) {
      if (_layerSubscriptions[layer] != null) return;

      switch (layer) {
        case 'Terminals':
          _layerSubscriptions[layer] = _taxiService.getLiveHubs().listen((hubs) {
            if (!mounted) return;
            setState(() {
              _markerData[layer] = hubs.where((h) => _isInViewport(h.location)).map((h) => Marker(
                point: LatLng(h.location.latitude, h.location.longitude),
                width: 60, height: 60,
                child: GestureDetector(
                  onTap: () => _showHubInfo(h),
                  child: _buildHubMarker(h),
                ),
              )).toList();
            });
          });
          break;
        case 'Taxis':
          _layerSubscriptions[layer] = _taxiService.getLiveFleet().listen((fleet) {
            if (!mounted) return;
            setState(() {
              _markerData[layer] = fleet.where((v) => v.gpsLocation != null && _isInViewport(v.gpsLocation!)).map((v) => Marker(
                point: LatLng(v.gpsLocation!.latitude, v.gpsLocation!.longitude),
                width: 50, height: 50,
                child: GestureDetector(
                  onTap: () => _showVehicleInfo(v),
                  child: _buildVehicleMarker(v),
                ),
              )).toList();
            });
          });
          break;
        case 'Hotels':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.hotels, Icons.hotel, Colors.purple, 'Hotels');
          break;
        case 'Tourism':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.tourismSites, Icons.landscape, Colors.teal, 'Tourism');
          break;
        case 'Hospitals':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.hospitals, Icons.local_hospital, Colors.red, 'Hospitals');
          break;
        case 'Pharmacies':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.pharmacies, Icons.local_pharmacy, Colors.green, 'Pharmacies');
          break;
        case 'Emergency':
          _layerSubscriptions['emergency_centers'] = _subscribe(CityOSCollection.emergencyCenters, Icons.emergency, Colors.redAccent, 'Emergency');
          _layerSubscriptions['live_events'] = _taxiService.getLiveEvents().listen((events) {
            if (!mounted) return;
            setState(() {
              final newMarkers = events.where((e) => _isInViewport(e.location)).map((e) => Marker(
                point: LatLng(e.location.latitude, e.location.longitude),
                width: 55, height: 55,
                child: GestureDetector(
                  onTap: () => _showEventInfo(e),
                  child: _buildEventMarker(e),
                ),
              )).toList();
              _markerData['Emergency'] = [..._markerData['Emergency']!.where((m) => m.key != const Key('live_event')), ...newMarkers];
            });
          });
          _layerSubscriptions['emergency_incidents'] = _emergencyService.getActiveIncidents().listen((incidents) {
            if (!mounted) return;
            setState(() {
               final incMarkers = incidents.where((i) => _isInViewport(i.location)).map((i) => Marker(
                 point: LatLng(i.location.latitude, i.location.longitude),
                 width: 65, height: 65,
                 child: GestureDetector(
                   onTap: () => _showIncidentInfo(i),
                   child: _buildIncidentMarker(i),
                 ),
               )).toList();
               _markerData['Emergency'] = [..._markerData['Emergency']!, ...incMarkers];
            });
          });
          _layerSubscriptions['sos_requests'] = _subscribe(CityOSCollection.sosRequests, Icons.warning, Colors.redAccent, 'Emergency', activeOnly: true);
          break;
        case 'Government':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.governmentOffices, Icons.account_balance, Colors.indigo, 'Government');
          break;
        case 'Eco-Shine':
          _layerSubscriptions[layer] = _subscribe(CityOSCollection.ecoShineLocations, Icons.wb_sunny, Colors.amber, 'Eco-Shine');
          break;
        case 'Analytics':
          _layerSubscriptions[layer] = _taxiService.getCityHeatmap('demand').listen((heatmap) {
            if (!mounted) return;
            setState(() {
              _markerData[layer] = heatmap.map((h) => Marker(
                point: LatLng(h.center.latitude, h.center.longitude),
                width: 100 * h.intensity,
                height: 100 * h.intensity,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.3 * h.intensity),
                  ),
                ),
              )).toList();
            });
          });
          break;
      }
    } else {
      _layerSubscriptions[layer]?.cancel();
      _layerSubscriptions.remove(layer);
      if (layer == 'Emergency') {
         _layerSubscriptions['live_events']?.cancel(); _layerSubscriptions.remove('live_events');
         _layerSubscriptions['emergency_centers']?.cancel(); _layerSubscriptions.remove('emergency_centers');
         _layerSubscriptions['sos_requests']?.cancel(); _layerSubscriptions.remove('sos_requests');
      }
      if (layer == 'Taxis') {
         _layerSubscriptions.remove('Taxis');
      }
      _markerData[layer] = [];
    }
  }

  bool _isInViewport(GeoPoint loc) {
    try {
      return _mapController.camera.visibleBounds.contains(LatLng(loc.latitude, loc.longitude));
    } catch (_) {
      return true;
    }
  }

  Widget _buildVehicleMarker(FleetVehicle v) {
    Color color = _getVehicleColor(v);
    IconData icon = _getVehicleIcon(v.vehicleType);

    return Transform.rotate(
      angle: v.heading * (3.14159 / 180),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            width: 45, height: 45,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: color, size: 20),
          ),
          if (v.status == VehicleStatus.busy)
            Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 8))),
        ],
      ),
    );
  }

  Widget _buildHubMarker(TransportHub h) {
    Color healthColor = _getHubHealthColor(h.healthStatus);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: healthColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          width: 55, height: 55,
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: healthColor, width: 3),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bus, color: healthColor, size: 20),
              Text('${h.availableVehicles}', style: TextStyle(color: healthColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentMarker(EmergencyIncident i) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _SOSRipple(color: Colors.red),
        Container(
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          padding: const EdgeInsets.all(8),
          child: Icon(_getIncidentIcon(i.type), color: Colors.white, size: 28),
        ),
      ],
    );
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.medical: return Icons.medical_services;
      case IncidentType.fire: return Icons.local_fire_department;
      case IncidentType.police: return Icons.policy;
      case IncidentType.trafficAccident: return Icons.car_crash;
      default: return Icons.warning;
    }
  }

  Widget _buildEventMarker(MapEvent e) {
    Color color = e.severity == MapEventSeverity.critical ? Colors.red : (e.severity == MapEventSeverity.high ? Colors.orange : Colors.yellow);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          padding: const EdgeInsets.all(6),
          child: Icon(_getEventIcon(e.type), color: Colors.white, size: 22),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
          child: Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 8), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Color _getVehicleColor(FleetVehicle v) {
    if (v.vehicleType == VehicleType.ambulance || v.vehicleType == VehicleType.fireTruck || v.vehicleType == VehicleType.policeVehicle) return Colors.red;
    if (v.vehicleType == VehicleType.governmentVehicle) return Colors.purple;

    switch (v.status) {
      case VehicleStatus.available: return Colors.green;
      case VehicleStatus.moving: return Colors.blue;
      case VehicleStatus.busy: return Colors.orange;
      case VehicleStatus.waiting: return Colors.yellow;
      case VehicleStatus.offline: return Colors.grey;
      case VehicleStatus.maintenance: return Colors.brown;
      case VehicleStatus.suspended: return Colors.black;
      case VehicleStatus.emergency: return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.taxi: return Icons.local_taxi;
      case VehicleType.bajaj: return Icons.electric_rickshaw;
      case VehicleType.cityBus: return Icons.directions_bus;
      case VehicleType.ambulance: return Icons.medical_services;
      case VehicleType.policeVehicle: return Icons.local_police;
      default: return Icons.directions_car;
    }
  }

  Color _getHubHealthColor(StationHealth health) {
    switch (health) {
      case StationHealth.normal: return Colors.green;
      case StationHealth.busy: return Colors.orange;
      case StationHealth.congested: return Colors.deepOrange;
      case StationHealth.critical: return Colors.red;
      case StationHealth.full: return Colors.redAccent;
      case StationHealth.closed: return Colors.grey;
    }
  }

  IconData _getEventIcon(MapEventType type) {
    switch (type) {
      case MapEventType.trafficCongestion: return Icons.traffic;
      case MapEventType.accident: return Icons.car_crash;
      case MapEventType.roadClosure: return Icons.block;
      case MapEventType.emergencyAlert: return Icons.warning;
      default: return Icons.info;
    }
  }

  StreamSubscription _subscribe(String collection, IconData icon, Color color, String layer, {String? statusField, bool activeOnly = false, bool isAnalytics = false}) {
    Query query = FirebaseFirestore.instance.collection(collection).limit(50);
    if (activeOnly) {
      query = query.where('status', isNotEqualTo: 'resolved');
    }

    return query.snapshots().listen((snapshot) {
      if (!mounted) return;

      final newMarkers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        GeoPoint? gp = data['location'] as GeoPoint?;
        double lat = gp?.latitude ?? (data['latitude'] ?? data['lat'] ?? 7.0622).toDouble();
        double lng = gp?.longitude ?? (data['longitude'] ?? data['lng'] ?? 38.4763).toDouble();

        if (isAnalytics) {
           return Marker(
             point: LatLng(lat, lng),
             width: 80, height: 80,
             child: Container(
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: color.withValues(alpha: 0.3),
               ),
             ),
           );
        }

        Color mColor = color;
        if (statusField != null) {
          String s = (data[statusField] ?? '').toString().toLowerCase();
          if (s == 'busy' || s == 'ontrip') mColor = Colors.red;
          else if (s == 'offline') mColor = Colors.grey;
          else if (s == 'waiting' || s == 'available') mColor = Colors.green;
        }

        return Marker(
          point: LatLng(lat, lng),
          width: 50, height: 50,
          child: GestureDetector(
            onTap: () => _showLocationInfo(data, layer, mColor),
            child: _buildGisMarker(icon, mColor, layer == 'Emergency'),
          ),
        );
      }).toList();

      setState(() {
        if (collection == 'drivers' || collection == 'sos_requests' || collection == 'taxi_stations') {
           // Basic deduplication or layering logic could go here
           _markerData[layer] = [..._markerData[layer]!, ...newMarkers].take(100).toList();
        } else {
           _markerData[layer] = newMarkers;
        }
      });
    });
  }

  Widget _buildGisMarker(IconData icon, Color color, bool isSOS) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSOS) _SOSRipple(color: color),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }

  void _showLocationInfo(Map<String, dynamic> data, String layer, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GISInfoSheet(data: data, layer: layer, themeColor: themeColor),
    );
  }

  void _startAIVoice() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() => _searchQuery = val.recognizedWords);
          if (val.finalResult) _processAICommand(val.recognizedWords);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processAICommand(String cmd) {
    setState(() => _isListening = false);
    final q = cmd.toLowerCase();
    String response = "";

    if (q.contains("hospital") || q.contains("ሆስፒታል")) {
      _filterToLayer('Hospitals');
      response = "Highlighting nearest hospitals in Hawassa.";
    } else if (q.contains("taxi") || q.contains("ታክሲ")) {
      _filterToLayer('Taxis');
      response = "Showing active taxi fleet and stations.";
    } else if (q.contains("emergency") || q.contains("ድንገተኛ")) {
      _filterToLayer('Emergency');
      response = "Locating emergency centers and active SOS requests.";
    } else if (q.contains("tourism") || q.contains("ቱሪስት")) {
      _filterToLayer('Tourism');
      response = "Showing top tourism attractions near you.";
    } else {
      response = "Showing all Smart City layers.";
      _layers.updateAll((k, v) => true);
    }

    setState(() => _aiResponse = response);
    _flutterTts.speak(response);
  }

  void _filterToLayer(String key) {
    setState(() {
      _layers.forEach((k, v) => _updateSubscription(k, k == key));
      _layers.updateAll((k, v) => k == key);
    });
  }

  List<Marker> _getVisibleMarkers() {
    List<Marker> list = [];
    _layers.forEach((k, v) { if (v) list.addAll(_markerData[k] ?? []); });
    if (_currentLocation != null) {
      list.add(Marker(
        point: _currentLocation!,
        width: 60, height: 60,
        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 45),
      ));
    }
    return list;
  }

  void _showVehicleInfo(FleetVehicle v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DigitalTwinInfoSheet(
        title: v.plateNumber,
        subtitle: '${v.vehicleType.name.toUpperCase()} | ${v.brand} ${v.model}',
        status: v.status.name.toUpperCase(),
        themeColor: _getVehicleColor(v),
        metrics: [
          _TwinMetric(Icons.person, 'Driver', v.assignedDriverId.isEmpty ? 'Unassigned' : 'Active ID: ${v.assignedDriverId}'),
          _TwinMetric(Icons.local_gas_station, 'Fuel/Energy', '${v.fuelLevel}% / ${v.batteryLevel}%'),
          _TwinMetric(Icons.speed, 'Current State', '${v.speed} km/h | Heading ${v.heading}°'),
          _TwinMetric(Icons.gps_fixed, 'GPS Health', v.gpsHealth ? 'Operational' : 'Signal Lost', isWarning: !v.gpsHealth),
        ],
        actions: [
          ElevatedButton.icon(onPressed: () => _simulateRouting(v.gpsLocation!), icon: const Icon(Icons.route), label: const Text('DISPATCH ROUTE')),
        ],
      ),
    );
  }

  void _showHubInfo(TransportHub h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DigitalTwinInfoSheet(
        title: h.stationName,
        subtitle: 'Multi-Modal Transport Hub | ${h.city}',
        status: h.healthStatus.name.toUpperCase(),
        themeColor: _getHubHealthColor(h.healthStatus),
        metrics: [
          _TwinMetric(Icons.pie_chart, 'Occupancy', '${h.occupancyPercentage.toStringAsFixed(1)}% (${h.currentVehicleCount}/${h.maximumVehicleCapacity})'),
          _TwinMetric(Icons.groups, 'Citizen Queue', '${h.queueLength} waiting', isWarning: h.queueLength > 20),
          _TwinMetric(Icons.timer, 'Avg Wait Time', '${h.averageWaitingTime} mins'),
          _TwinMetric(Icons.health_and_safety, 'Platform Health', h.platforms.isNotEmpty ? h.platforms.first.health.name : 'Stable'),
        ],
        actions: [
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.analytics), label: const Text('HUB ANALYTICS')),
        ],
      ),
    );
  }

  void _showEventInfo(MapEvent e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DigitalTwinInfoSheet(
        title: e.title,
        subtitle: '${e.type.name.toUpperCase()} | Severity: ${e.severity.name}',
        status: e.isActive ? 'ACTIVE' : 'RESOLVED',
        themeColor: e.severity == MapEventSeverity.critical ? Colors.red : Colors.orange,
        metrics: [
          _TwinMetric(Icons.description, 'Details', e.description),
          _TwinMetric(Icons.access_time, 'Reported At', e.timestamp.toIso8601String()),
        ],
        actions: [
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check_circle), label: const Text('ACKNOWLEDGE')),
        ],
      ),
    );
  }

  void _showIncidentInfo(EmergencyIncident i) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DigitalTwinInfoSheet(
        title: 'Emergency: ${i.type.name.toUpperCase()}',
        subtitle: 'Priority: ${i.priority.name.toUpperCase()} | Reported by ${i.reportedBy}',
        status: i.status.name.toUpperCase(),
        themeColor: Colors.red,
        metrics: [
          _TwinMetric(Icons.description, 'Description', i.description),
          _TwinMetric(Icons.timer, 'Response ETA', '${i.responseEtaMinutes} mins'),
          _TwinMetric(Icons.medical_information, 'Assigned Unit', i.assignedUnitId.isEmpty ? 'Searching...' : i.assignedUnitId),
        ],
        actions: [
          ElevatedButton.icon(onPressed: () => _simulateRouting(i.location), icon: const Icon(Icons.emergency_share), label: const Text('DISPATCH UNIT')),
        ],
      ),
    );
  }

  Future<void> _simulateRouting(GeoPoint start) async {
    final end = GeoPoint(_hawassaCenter.latitude, _hawassaCenter.longitude);
    final route = await _taxiService.calculateRoute(start, end, VehicleType.taxi);

    setState(() {
      _polylines = [
        Polyline(
          points: [LatLng(start.latitude, start.longitude), LatLng(end.latitude, end.longitude)],
          color: Colors.blue,
          strokeWidth: 4.0,
        )
      ];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Route Calculated: ${route['distanceKm'].toStringAsFixed(1)}km | ETA: ${route['etaMinutes']}m | Fare: ${route['estimatedFare']} ETB'),
        backgroundColor: Colors.blue,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _hawassaCenter,
              initialZoom: 14.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  // Re-filter markers on move for optimization
                  setState(() {});
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _getVisibleMarkers()),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildGisHeader(lang),
                  const SizedBox(height: 12),
                  _buildLayerSelector(),
                  if (_aiResponse.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GlassCard(padding: const EdgeInsets.all(12), child: Text(_aiResponse, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                ],
              ),
            ),
          ),

          Positioned(bottom: 24, right: 16, child: _buildGisControls(user)),
          if (_isListening) _buildVoiceOverlay(),
        ],
      ),
    );
  }

  Widget _buildGisHeader(LanguageProvider lang) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: lang.t('search_city'), hintStyle: const TextStyle(color: Colors.white54), border: InputBorder.none),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          IconButton(icon: Icon(_isListening ? Icons.graphic_eq : Icons.mic, color: _isListening ? Colors.redAccent : Colors.white), onPressed: _startAIVoice),
        ],
      ),
    );
  }

  Widget _buildLayerSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _layers.keys.map((l) {
          bool active = _layers[l]!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _layers[l] = !active);
                _updateSubscription(l, !active);
              },
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: active ? Colors.green.withValues(alpha: 0.7) : null,
                child: Center(child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGisControls(UserModel? user) {
    return Column(
      children: [
        if (user?.role == UserRole.superAdmin)
          FloatingActionButton.small(
            heroTag: 'add_loc',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CRUDListScreen(collection: 'locations', title: 'Add Location', fields: ['name', 'latitude', 'longitude', 'category', 'phone', 'address']))),
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.add_location, color: Colors.white),
          ),
        const SizedBox(height: 12),
        FloatingActionButton.small(heroTag: 'gps_btn', onPressed: _determinePosition, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Colors.blue)),
        const SizedBox(height: 12),
        FloatingActionButton(heroTag: 'sos_map_btn', onPressed: _triggerSOS, backgroundColor: Colors.red, child: const Icon(Icons.sos, color: Colors.white, size: 32)),
      ],
    );
  }

  Widget _buildVoiceOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 80),
            const SizedBox(height: 24),
            Text(_searchQuery.isEmpty ? "Listening..." : _searchQuery, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GISInfoSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String layer;
  final Color themeColor;

  const _GISInfoSheet({required this.data, required this.layer, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? data['type'] ?? 'City Service', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(layer.toUpperCase(), style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              if (data['imageUrl'] != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: data['imageUrl'], width: 80, height: 80, fit: BoxFit.cover, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error))),
            ],
          ),
          const SizedBox(height: 20),
          _gisRow(Icons.location_on, data['address'] ?? data['location'] ?? 'Hawassa, Sidama'),
          if (data['phone'] != null) _gisRow(Icons.phone, data['phone']),
          if (data['openingHours'] != null) _gisRow(Icons.access_time, data['openingHours']),
          if (data['description'] != null) ...[const SizedBox(height: 12), Text(data['description'], style: const TextStyle(color: Colors.white70, fontSize: 14))],
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _nav(data['latitude'] ?? data['lat'], data['longitude'] ?? data['lng']), icon: const Icon(Icons.navigation), label: const Text('DIRECTIONS'), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white))),
              const SizedBox(width: 12),
              if (data['phone'] != null) Expanded(child: OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse('tel:${data['phone']}')), icon: const Icon(Icons.call), label: const Text('CALL'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)))),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _gisRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
      ],
    ),
  );

  void _nav(dynamic lat, dynamic lng) async {
    final url = 'google.navigation:q=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

class _DigitalTwinInfoSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color themeColor;
  final List<_TwinMetric> metrics;
  final List<Widget> actions;

  const _DigitalTwinInfoSheet({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.themeColor,
    required this.metrics,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor)),
                child: Text(status, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          ...metrics.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(m.icon, color: m.isWarning ? Colors.redAccent : Colors.white54, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(m.value, style: TextStyle(color: m.isWarning ? Colors.redAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),
          Row(children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a))).toList()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TwinMetric {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  _TwinMetric(this.icon, this.label, this.value, {this.isWarning = false});
}

class _SOSRipple extends StatefulWidget {
  final Color color;
  const _SOSRipple({required this.color});
  @override
  State<_SOSRipple> createState() => _SOSRippleState();
}

class _SOSRippleState extends State<_SOSRipple> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return FadeTransition(opacity: Tween(begin: 1.0, end: 0.0).animate(_c), child: ScaleTransition(scale: Tween(begin: 1.0, end: 4.0).animate(_c), child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.4))))); }
}
