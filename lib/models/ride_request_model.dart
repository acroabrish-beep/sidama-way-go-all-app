import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus {
  requested,
  accepted,
  driverEnRoute,
  inProgress,
  completed,
  cancelled,
  rejected,
}

class RideRequest {
  final String id;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final String pickupLocation;
  final GeoPoint pickupCoordinates;
  final String destination;
  final GeoPoint? destinationCoordinates;
  final double estimatedDistanceKm;
  final double estimatedFare;
  final RideStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlateNumber;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final double? actualFare;

  RideRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.pickupLocation,
    required this.pickupCoordinates,
    required this.destination,
    this.destinationCoordinates,
    required this.estimatedDistanceKm,
    required this.estimatedFare,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehiclePlateNumber,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.actualFare,
  });

  factory RideRequest.fromMap(Map<String, dynamic> data, String id) {
    return RideRequest(
      id: id,
      riderId: data['riderId'] ?? '',
      riderName: data['riderName'] ?? '',
      riderPhone: data['riderPhone'] ?? '',
      pickupLocation: data['pickupLocation'] ?? '',
      pickupCoordinates: data['pickupCoordinates'] as GeoPoint? ?? const GeoPoint(0, 0),
      destination: data['destination'] ?? '',
      destinationCoordinates: data['destinationCoordinates'] as GeoPoint?,
      estimatedDistanceKm: (data['estimatedDistanceKm'] ?? 0).toDouble(),
      estimatedFare: (data['estimatedFare'] ?? 0).toDouble(),
      status: RideStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RideStatus.requested,
      ),
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      vehiclePlateNumber: data['vehiclePlateNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      actualFare: (data['actualFare'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'pickupLocation': pickupLocation,
      'pickupCoordinates': pickupCoordinates,
      'destination': destination,
      'destinationCoordinates': destinationCoordinates,
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedFare': estimatedFare,
      'status': status.name,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlateNumber': vehiclePlateNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'actualFare': actualFare,
    };
  }

  RideRequest copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? riderPhone,
    String? pickupLocation,
    GeoPoint? pickupCoordinates,
    String? destination,
    GeoPoint? destinationCoordinates,
    double? estimatedDistanceKm,
    double? estimatedFare,
    RideStatus? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehiclePlateNumber,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    double? actualFare,
  }) {
    return RideRequest(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      destination: destination ?? this.destination,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehiclePlateNumber: vehiclePlateNumber ?? this.vehiclePlateNumber,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      actualFare: actualFare ?? this.actualFare,
    );
  }
}
