import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request_model.dart';

class RideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fare configuration
  static const double baseFare = 15.0; // ETB
  static const double perKmRate = 8.0; // ETB per km
  static const double perMinuteRate = 0.5; // ETB per minute

  // Calculate distance between two coordinates in km using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Calculate fare based on distance and time
  double calculateFare(double distanceKm, int estimatedMinutes) {
    final distanceFare = distanceKm * perKmRate;
    final timeFare = estimatedMinutes * perMinuteRate;
    return baseFare + distanceFare + timeFare;
  }

  // Create a new ride request
  Future<String> createRideRequest({
    required String riderId,
    required String riderName,
    required String riderPhone,
    required String pickupLocation,
    required GeoPoint pickupCoordinates,
    required String destination,
    GeoPoint? destinationCoordinates,
  }) async {
    // Calculate distance if destination coordinates are provided
    double distanceKm = 0;
    if (destinationCoordinates != null) {
      distanceKm = calculateDistance(
        pickupCoordinates.latitude,
        pickupCoordinates.longitude,
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      );
    }

    // Estimate fare (assume 2 minutes per km for ETA)
    final estimatedMinutes = (distanceKm * 2).round();
    final estimatedFare = calculateFare(distanceKm, estimatedMinutes);

    final rideRequest = RideRequest(
      id: '',
      riderId: riderId,
      riderName: riderName,
      riderPhone: riderPhone,
      pickupLocation: pickupLocation,
      pickupCoordinates: pickupCoordinates,
      destination: destination,
      destinationCoordinates: destinationCoordinates,
      estimatedDistanceKm: distanceKm,
      estimatedFare: estimatedFare,
      status: RideStatus.requested,
      createdAt: DateTime.now(),
    );

    final docRef = await _db.collection('ride_requests').add(rideRequest.toMap());
    return docRef.id;
  }

  // Get ride request by ID
  Stream<RideRequest?> getRideRequest(String rideId) {
    return _db.collection('ride_requests').doc(rideId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RideRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // Get rider's ride history
  Stream<List<RideRequest>> getRiderRideHistory(String riderId) {
    return _db
        .collection('ride_requests')
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get driver's ride history
  Stream<List<RideRequest>> getDriverRideHistory(String driverId) {
    return _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get available ride requests for drivers (nearby and requested status)
  Stream<List<RideRequest>> getAvailableRideRequests(GeoPoint driverLocation) {
    // In a real implementation, this would use geohash or geofire for proximity queries
    // For now, we'll return all requested rides
    return _db
        .collection('ride_requests')
        .where('status', isEqualTo: RideStatus.requested.name)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Driver accepts a ride request
  Future<void> acceptRideRequest({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String vehiclePlateNumber,
  }) async {
    await _db.collection('ride_requests').doc(rideId).update({
      'status': RideStatus.accepted.name,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlateNumber': vehiclePlateNumber,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Driver rejects a ride request
  Future<void> rejectRideRequest(String rideId) async {
    await _db.collection('ride_requests').doc(rideId).update({
      'status': RideStatus.rejected.name,
    });
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    final updateData = <String, dynamic>{'status': status.name};
    
    if (status == RideStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }
    
    await _db.collection('ride_requests').doc(rideId).update(updateData);
  }

  // Cancel ride request
  Future<void> cancelRideRequest(String rideId) async {
    await _db.collection('ride_requests').doc(rideId).update({
      'status': RideStatus.cancelled.name,
    });
  }

  // Calculate driver earnings
  Future<Map<String, double>> calculateDriverEarnings(String driverId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final snapshot = await _db
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: RideStatus.completed.name)
        .get();

    double todayEarnings = 0;
    double weekEarnings = 0;
    double monthEarnings = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fare = (data['actualFare'] ?? data['estimatedFare'] ?? 0) as num;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();

      if (completedAt != null) {
        if (completedAt.isAfter(today)) {
          todayEarnings += fare.toDouble();
        }
        if (completedAt.isAfter(weekStart)) {
          weekEarnings += fare.toDouble();
        }
        if (completedAt.isAfter(monthStart)) {
          monthEarnings += fare.toDouble();
        }
      }
    }

    return {
      'today': todayEarnings,
      'week': weekEarnings,
      'month': monthEarnings,
    };
  }
}
