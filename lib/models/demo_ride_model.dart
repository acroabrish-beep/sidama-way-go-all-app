import 'package:latlong2/latlong.dart';
import 'demo_taxi_model.dart';

enum DemoRideStatus {
  idle,
  searching,
  matched,
  approaching,
  arrived,
  inProgress,
  completed,
  cancelled
}

class DemoRideProgress {
  final DemoRideStatus status;
  final DemoTaxi? selectedTaxi;
  final LatLng? currentTaxiLocation;
  final double distanceRemainingKm;
  final int etaMinutes;
  final double estimatedFare;

  DemoRideProgress({
    required this.status,
    this.selectedTaxi,
    this.currentTaxiLocation,
    this.distanceRemainingKm = 0.0,
    this.etaMinutes = 0,
    this.estimatedFare = 0.0,
  });
}
