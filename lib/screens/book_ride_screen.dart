import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/smart_services.dart';
import '../services/ride_service.dart';
import '../models/ride_request_model.dart';
import '../providers/auth_provider.dart';

enum RideState { idle, searching, driverFound, tracking, completed }

class BookRideScreen extends StatefulWidget {
  final String? preselectedDestination;
  const BookRideScreen({super.key, this.preselectedDestination});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  RideState _state = RideState.idle;
  late TextEditingController _destController;
  String? _selectedDest;
  String? _aiRecommendation;
  final RideService _rideService = RideService();
  String? _currentRideId;
  double? _estimatedFare;
  double? _estimatedDistance;
  StreamSubscription<RideRequest?>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDest = widget.preselectedDestination;
    _destController = TextEditingController(text: _selectedDest);
    _loadAIRecommendation();
  }

  @override
  void dispose() {
    _destController.dispose();
    _rideSubscription?.cancel();
    super.dispose();
  }

  void _loadAIRecommendation() async {
    final rec = await SmartAIService.getRouteRecommendation('any');
    setState(() => _aiRecommendation = rec);
  }

  Future<void> _startSearch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a ride')),
      );
      return;
    }

    setState(() => _state = RideState.searching);

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create ride request
      final rideId = await _rideService.createRideRequest(
        riderId: user.uid,
        riderName: user.fullName,
        riderPhone: user.phone,
        pickupLocation: 'Current Location',
        pickupCoordinates: GeoPoint(position.latitude, position.longitude),
        destination: _selectedDest ?? 'Unknown',
      );

      _currentRideId = rideId;

      // Listen to ride status updates
      _rideSubscription = _rideService.getRideRequest(rideId).listen((ride) {
        if (ride == null) return;
        
        setState(() {
          _estimatedFare = ride.estimatedFare;
          _estimatedDistance = ride.estimatedDistanceKm;
        });

        if (ride.status == RideStatus.accepted) {
          setState(() => _state = RideState.driverFound);
        } else if (ride.status == RideStatus.driverEnRoute) {
          setState(() => _state = RideState.tracking);
        } else if (ride.status == RideStatus.completed) {
          setState(() => _state = RideState.completed);
        }
      });
    } catch (e) {
      setState(() => _state = RideState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMART RIDE')),
      body: Column(
        children: [
          if (_aiRecommendation != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_aiRecommendation!, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          Expanded(
            child: _state == RideState.idle ? _buildIdle() : _buildActive(),
          ),
        ],
      ),
    );
  }

  Widget _buildIdle() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('WHERE ARE YOU GOING?', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        TextField(
          controller: _destController,
          decoration: InputDecoration(
            hintText: 'Enter destination...',
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _selectedDest = v),
        ),
        const SizedBox(height: 32),
        const Text('AVAILABLE TAXI STATIONS', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        _buildStationsStream(),
        const SizedBox(height: 40),
        if (_estimatedFare != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimated Distance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_estimatedDistance?.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Estimated Fare', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_estimatedFare?.toStringAsFixed(0)} ETB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedDest != null ? _startSearch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('REQUEST RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStationsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('taxi_stations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No stations available.');

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Station';
            return ListTile(
              leading: const Icon(Icons.local_taxi, color: Colors.orange),
              title: Text(name),
              subtitle: Text('Capacity: ${data['capacity'] ?? 0}'),
              onTap: () {
                setState(() {
                  _selectedDest = name;
                  _destController.text = name;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActive() {
    return StreamBuilder<RideRequest?>(
      stream: _currentRideId != null ? _rideService.getRideRequest(_currentRideId!) : null,
      builder: (context, snapshot) {
        final ride = snapshot.data;
        
        if (_state == RideState.searching) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 24),
                const Text('Searching for nearby drivers...'),
                const SizedBox(height: 8),
                Text('Your fare: ${_estimatedFare?.toStringAsFixed(0)} ETB', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        if (ride == null) {
          return const Center(child: Text('Loading ride details...'));
        }
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(ride.status),
                  color: _getStatusColor(ride.status),
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  _getStatusText(ride.status),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (ride.driverName != null) ...[
                  const SizedBox(height: 8),
                  Text('Driver: ${ride.driverName}'),
                  if (ride.vehiclePlateNumber != null)
                    Text('Vehicle: ${ride.vehiclePlateNumber}'),
                ],
                const SizedBox(height: 16),
                Text('Fare: ${ride.estimatedFare.toStringAsFixed(0)} ETB'),
                const SizedBox(height: 32),
                if (ride.status == RideStatus.accepted || ride.status == RideStatus.driverEnRoute)
                  ElevatedButton(
                    onPressed: () => _cancelRide(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Ride'),
                  ),
                if (ride.status == RideStatus.completed)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Icons.search;
      case RideStatus.accepted:
        return Icons.person_pin_circle;
      case RideStatus.driverEnRoute:
        return Icons.directions_car;
      case RideStatus.inProgress:
        return Icons.local_taxi;
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.cancelled:
        return Icons.cancel;
      case RideStatus.rejected:
        return Icons.close;
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.driverEnRoute:
        return Colors.green;
      case RideStatus.inProgress:
        return Colors.purple;
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
      case RideStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return 'Requesting ride...';
      case RideStatus.accepted:
        return 'Driver Accepted!';
      case RideStatus.driverEnRoute:
        return 'Driver is on the way';
      case RideStatus.inProgress:
        return 'Trip in progress';
      case RideStatus.completed:
        return 'Trip completed';
      case RideStatus.cancelled:
        return 'Ride cancelled';
      case RideStatus.rejected:
        return 'No drivers available';
    }
  }

  Future<void> _cancelRide() async {
    if (_currentRideId != null) {
      await _rideService.cancelRideRequest(_currentRideId!);
      setState(() {
        _state = RideState.idle;
        _currentRideId = null;
        _estimatedFare = null;
        _estimatedDistance = null;
      });
    }
  }


}
