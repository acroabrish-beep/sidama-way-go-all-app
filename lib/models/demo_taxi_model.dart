import 'package:latlong2/latlong.dart';

class DemoLocation {
  final String name;
  final LatLng coordinates;

  DemoLocation({required this.name, required this.coordinates});
}

class DemoTaxi {
  final String id;
  final String plateNumber;
  final String driverName;
  final String vehicleType;
  LatLng location;
  final double rating;
  bool available;
  double? heading;

  DemoTaxi({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    required this.vehicleType,
    required this.location,
    this.rating = 4.5,
    this.available = true,
    this.heading,
  });

  DemoTaxi copyWith({
    String? id,
    String? plateNumber,
    String? driverName,
    String? vehicleType,
    LatLng? location,
    double? rating,
    bool? available,
    double? heading,
  }) {
    return DemoTaxi(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      available: available ?? this.available,
      heading: heading ?? this.heading,
    );
  }
}
