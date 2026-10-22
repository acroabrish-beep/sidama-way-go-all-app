import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/demo_taxi_model.dart';

class TaxiDemoService {
  static final List<DemoLocation> hawassaLocations = [
    DemoLocation(name: 'Hawassa University', coordinates: const LatLng(7.0450, 38.4900)),
    DemoLocation(name: 'Piazza', coordinates: const LatLng(7.0504, 38.4955)),
    DemoLocation(name: 'Mekenissa', coordinates: const LatLng(7.0600, 38.4800)),
    DemoLocation(name: 'Lake Hawassa', coordinates: const LatLng(7.0650, 38.4750)),
    DemoLocation(name: 'Hawassa Stadium', coordinates: const LatLng(7.0550, 38.5000)),
    DemoLocation(name: 'Referral Hospital', coordinates: const LatLng(7.0622, 38.4763)),
    DemoLocation(name: 'Amora Gedel Park', coordinates: const LatLng(7.0700, 38.4700)),
    DemoLocation(name: 'Hawassa Fish Market', coordinates: const LatLng(7.0750, 38.4650)),
    DemoLocation(name: 'Haile Resort', coordinates: const LatLng(7.0800, 38.4850)),
    DemoLocation(name: 'Alamura', coordinates: const LatLng(7.0150, 38.4820)),
    DemoLocation(name: 'Tabor', coordinates: const LatLng(7.0423, 38.5085)),
    DemoLocation(name: 'Tulla', coordinates: const LatLng(7.0315, 38.5210)),
    DemoLocation(name: 'Manore', coordinates: const LatLng(7.0580, 38.4850)),
    DemoLocation(name: 'Bus Station', coordinates: const LatLng(7.0621, 38.4772)),
  ];

  static List<DemoTaxi> generateInitialFleet() {
    return [
      DemoTaxi(
        id: 'T-01',
        plateNumber: '3-A00001',
        driverName: 'Abebe Bikila',
        vehicleType: 'Sedan',
        location: const LatLng(7.0520, 38.4980),
        rating: 4.9,
      ),
      DemoTaxi(
        id: 'T-02',
        plateNumber: '3-A00002',
        driverName: 'Mamo Wolde',
        vehicleType: 'Bajaj',
        location: const LatLng(7.0480, 38.4850),
        rating: 4.7,
      ),
      DemoTaxi(
        id: 'T-03',
        plateNumber: '3-A00003',
        driverName: 'Derartu Tulu',
        vehicleType: 'Sedan',
        location: const LatLng(7.0580, 38.4720),
        rating: 4.8,
      ),
      DemoTaxi(
        id: 'T-04',
        plateNumber: '3-A00004',
        driverName: 'Haile Gebrselassie',
        vehicleType: 'Minibus',
        location: const LatLng(7.0400, 38.5050),
        rating: 5.0,
      ),
      DemoTaxi(
        id: 'T-05',
        plateNumber: '3-A00005',
        driverName: 'Kenenisa Bekele',
        vehicleType: 'Sedan',
        location: const LatLng(7.0650, 38.4800),
        rating: 4.6,
      ),
      DemoTaxi(
        id: 'T-06',
        plateNumber: '3-A00006',
        driverName: 'Tirunesh Dibaba',
        vehicleType: 'Bajaj',
        location: const LatLng(7.0500, 38.4900),
        rating: 4.5,
      ),
    ];
  }

  static double calculateDistance(LatLng p1, LatLng p2) {
    var lat1 = p1.latitude;
    var lon1 = p1.longitude;
    var lat2 = p2.latitude;
    var lon2 = p2.longitude;

    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  static double calculateFare(double distanceKm, int durationMin) {
    const baseFare = 15.0;
    const perKm = 8.0;
    const perMin = 0.5;
    return baseFare + (distanceKm * perKm) + (durationMin * perMin);
  }

  static int estimateTime(double distanceKm) {
    return (distanceKm / 20 * 60).round() + 2; 
  }
}
