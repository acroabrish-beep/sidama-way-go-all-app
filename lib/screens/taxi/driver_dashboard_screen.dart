import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/taxi_models.dart';
import '../../services/taxi_service.dart';

class TaxiDriverDashboard extends StatefulWidget {
  const TaxiDriverDashboard({super.key});

  @override
  State<TaxiDriverDashboard> createState() => _TaxiDriverDashboardState();
}

class _TaxiDriverDashboardState extends State<TaxiDriverDashboard> {
  final _taxiService = TaxiService();
  final _auth = FirebaseAuth.instance;

  TaxiDriver? _driver;
  StreamSubscription<Position>? _positionSubscription;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  void _loadDriverData() {
    final user = _auth.currentUser;
    if (user != null) {
      _taxiService.getDriver(user.uid).listen((driver) {
        if (mounted) {
          setState(() {
            _driver = driver;
            _isOnline = driver?.online ?? false;
          });
          if (_isOnline) {
            _startLocationTracking();
          } else {
            _stopLocationTracking();
          }
        }
      });
    }
  }

  Future<void> _toggleOnline(bool value) async {
    if (_driver == null || _driver!.approvalStatus != DriverStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account must be approved to go online.'),
        ),
      );
      return;
    }
    final newStatus = value ? TaxiStatus.waiting : TaxiStatus.offline;
    await _taxiService.updateDriverStatus(_driver!.id, newStatus);
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (_driver != null) {
            final zone = TaxiService.detectZone(
              position.latitude,
              position.longitude,
            );
            _taxiService.updateDriverLocation(_driver!.id, position, zone);
          }
        });
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_driver == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeColor: Colors.greenAccent,
            inactiveThumbColor: Colors.redAccent,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: _isOnline ? _buildAssignedRideView() : _buildOfflineView(),
          ),
          _buildSOSButton(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driver!.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Status: ${_driver!.approvalStatus.toString().split('.').last.toUpperCase()}',
                  style: TextStyle(
                    color: _driver!.approvalStatus == DriverStatus.approved
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (_isOnline)
                  Text(
                    'Zone: ${_driver!.currentZone ?? 'Detecting...'}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
              ],
            ),
          ),
          _buildStat(
            'Rating',
            _driver!.rating.toString(),
            Icons.star,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'You are currently Offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go online to start receiving ride requests',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _toggleOnline(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('GO ONLINE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedRideView() {
    return StreamBuilder<List<RideRequest>>(
      stream: _taxiService.getDriverActiveRides(_driver!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final List<RideRequest> requests = snapshot.data as List<RideRequest>;

        if (requests.isEmpty) {
          return StreamBuilder<int>(
            stream: _taxiService.getDriverQueuePosition(
              _driver!.id,
              _driver!.stationId,
            ),
            builder: (context, queueSnapshot) {
              final position = queueSnapshot.data ?? 0;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      position > 0
                          ? 'You are queued at station ${_driver!.stationName}\nPosition: $position'
                          : 'Waiting for assignment...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The system will automatically assign you the next booking from your station queue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        }

        final req = requests.first;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            req.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${req.fare} ETB',
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _locationRow(Icons.my_location, 'Pickup', req.pickup),
                      const SizedBox(height: 8),
                      _locationRow(
                        Icons.location_on,
                        'Destination',
                        req.destination,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Status: ${req.status}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (req.status == 'Accepted')
                        ElevatedButton(
                          onPressed: () =>
                              _taxiService.completeRide(req.id, _driver!.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('MARK TRIP COMPLETE'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _locationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSOSButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            if (_driver != null && _driver!.location != null) {
              _taxiService.sendSOS(
                _driver!.id,
                _driver!.fullName,
                _driver!.location!,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS Alert Sent! Assistance is on the way.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.emergency),
          label: const Text(
            'EMERGENCY SOS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
