import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/demo_taxi_model.dart';
import '../models/demo_ride_model.dart';
import '../services/taxi_demo_service.dart';

class TaxiDemoProvider with ChangeNotifier {
  List<DemoTaxi> _fleet = TaxiDemoService.generateInitialFleet();
  DemoRideStatus _status = DemoRideStatus.idle;
  DemoTaxi? _selectedTaxi;
  DemoLocation? _pickup;
  DemoLocation? _destination;
  
  double _distanceRemainingKm = 0.0;
  int _etaMinutes = 0;
  double _estimatedFare = 0.0;
  
  LatLng? _currentTaxiLocation;
  Timer? _movementTimer;
  
  String _aiSelectionReason = '';

  // Getters
  List<DemoTaxi> get fleet => _fleet;
  DemoRideStatus get status => _status;
  DemoTaxi? get selectedTaxi => _selectedTaxi;
  DemoLocation? get pickup => _pickup;
  DemoLocation? get destination => _destination;
  double get distanceRemainingKm => _distanceRemainingKm;
  int get etaMinutes => _etaMinutes;
  double get estimatedFare => _estimatedFare;
  LatLng? get currentTaxiLocation => _currentTaxiLocation;
  String get aiSelectionReason => _aiSelectionReason;

  void setPickup(DemoLocation location) {
    _pickup = location;
    _calculateInitialEstimates();
    notifyListeners();
  }

  void setDestination(DemoLocation location) {
    if (_pickup != null && _pickup!.name == location.name) return;
    _destination = location;
    _calculateInitialEstimates();
    notifyListeners();
  }

  void _calculateInitialEstimates() {
    if (_pickup != null && _destination != null) {
      final dist = TaxiDemoService.calculateDistance(_pickup!.coordinates, _destination!.coordinates);
      _etaMinutes = TaxiDemoService.estimateTime(dist);
      _estimatedFare = TaxiDemoService.calculateFare(dist, _etaMinutes);
      _distanceRemainingKm = dist;
    }
  }

  Future<void> findTaxi() async {
    if (_pickup == null || _destination == null) return;
    
    _status = DemoRideStatus.searching;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    _fleet.sort((a, b) {
      final distA = TaxiDemoService.calculateDistance(a.location, _pickup!.coordinates);
      final distB = TaxiDemoService.calculateDistance(b.location, _pickup!.coordinates);
      return distA.compareTo(distB);
    });
    
    _selectedTaxi = _fleet.firstWhere((t) => t.available, orElse: () => _fleet.first);
    _status = DemoRideStatus.matched;
    _currentTaxiLocation = _selectedTaxi!.location;
    
    _aiSelectionReason = 'Taxi ${_selectedTaxi!.id} was selected because it is the closest available taxi with a rating of ${_selectedTaxi!.rating}.';
    
    notifyListeners();
  }

  void startApproaching() {
    if (_selectedTaxi == null || _pickup == null) return;
    
    _status = DemoRideStatus.approaching;
    notifyListeners();
    
    _startMovementAnimation(_selectedTaxi!.location, _pickup!.coordinates, () {
      _status = DemoRideStatus.arrived;
      notifyListeners();
    });
  }

  void startRide() {
    if (_selectedTaxi == null || _pickup == null || _destination == null) return;
    
    _status = DemoRideStatus.inProgress;
    notifyListeners();
    
    _startMovementAnimation(_pickup!.coordinates, _destination!.coordinates, () {
      _status = DemoRideStatus.completed;
      notifyListeners();
    });
  }

  void _startMovementAnimation(LatLng start, LatLng end, VoidCallback onComplete) {
    _movementTimer?.cancel();
    
    int steps = 50;
    int currentStep = 0;
    
    _movementTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      currentStep++;
      
      double fraction = currentStep / steps;
      
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      
      _currentTaxiLocation = LatLng(lat, lng);
      
      _distanceRemainingKm = TaxiDemoService.calculateDistance(_currentTaxiLocation!, end);
      _etaMinutes = TaxiDemoService.estimateTime(_distanceRemainingKm);
      
      if (currentStep >= steps) {
        timer.cancel();
        _currentTaxiLocation = end;
        _distanceRemainingKm = 0.0;
        _etaMinutes = 0;
        onComplete();
      }
      
      notifyListeners();
    });
  }

  void reset() {
    _movementTimer?.cancel();
    _status = DemoRideStatus.idle;
    _selectedTaxi = null;
    _pickup = null;
    _destination = null;
    _currentTaxiLocation = null;
    _distanceRemainingKm = 0.0;
    _etaMinutes = 0;
    _estimatedFare = 0.0;
    _aiSelectionReason = '';
    _fleet = TaxiDemoService.generateInitialFleet();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}
