import 'dart:math';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

double calculateDistance(LatLng p1, LatLng p2) {
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

int estimateTime(double distanceKm) {
  return (distanceKm / 20 * 60).round() + 2; 
}

double calculateFare(double distanceKm, int durationMin) {
  const baseFare = 15.0;
  const perKm = 8.0;
  const perMin = 0.5;
  return baseFare + (distanceKm * perKm) + (durationMin * perMin);
}

void main() {
  const hu = LatLng(7.0450, 38.4900);
  const piazza = LatLng(7.0504, 38.4955);
  
  double dist = calculateDistance(hu, piazza);
  int time = estimateTime(dist);
  double fare = calculateFare(dist, time);
  
  print('Distance: $dist km');
  print('Time: $time min');
  print('Fare: $fare ETB');
}
