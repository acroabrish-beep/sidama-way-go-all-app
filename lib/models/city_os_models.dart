import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum ApprovalStatus { pending, approved, rejected, suspended }

class CityOSCollection {
  static const String users = 'users';
  static const String routes = 'routes';
  static const String vehicles = 'vehicles';
  static const String drivers = 'drivers';
  static const String schedules = 'schedules';
  static const String ticketPrices = 'ticket_prices';
  static const String tickets = 'tickets';
  static const String payments = 'payments';
  static const String taxiStations = 'taxi_stations';
  static const String taxis = 'taxis';
  static const String taxiTrips = 'taxi_trips';
  static const String rideRequests = 'ride_requests';
  static const String driverLocations = 'driver_locations';
  static const String tourismSites = 'tourism_sites';
  static const String hotels = 'hotels';
  static const String hotelBookings = 'hotel_bookings';
  static const String hospitals = 'hospitals';
  static const String pharmacies = 'pharmacies';
  static const String foodVendors = 'food_vendors';
  static const String foodOrders = 'food_orders';
  static const String ecoShineLocations = 'eco_shine_locations';
  static const String announcements = 'announcements';
  static const String emergencyRequests = 'emergency_requests';
  static const String emergencyAlerts = 'emergency_alerts';
  static const String emergencyCenters = 'emergency_centers';
  static const String sosRequests = 'sos_requests';
  static const String governmentOffices = 'government_offices';
  static const String governmentVehicles = 'government_vehicles';
  static const String marketplaceProviders = 'marketplace_providers';
  static const String guestHouses = 'guest_houses';
  static const String stationQueue = 'station_queue';
  static const String notifications = 'notifications';
  static const String auditLogs = 'audit_logs';
  static const String analytics = 'analytics';
  static const String reminders = 'reminders';
  static const String popularDestinations = 'popular_destinations';
  static const String locations = 'locations';
}

class CitySummaryStats {
  final int totalUsers;
  final int taxiRequests;
  final int busBookings;
  final int activeSOS;
  final double totalRevenue;
  final List<double> weeklyRevenue;

  CitySummaryStats({
    required this.totalUsers,
    required this.taxiRequests,
    required this.busBookings,
    required this.activeSOS,
    required this.totalRevenue,
    required this.weeklyRevenue,
  });

  factory CitySummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return CitySummaryStats(
      totalUsers: data['totalUsers'] ?? 0,
      taxiRequests: data['taxiRequests'] ?? 0,
      busBookings: data['busBookings'] ?? 0,
      activeSOS: data['activeSOS'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
      weeklyRevenue: List<double>.from(data['weeklyRevenue'] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
    );
  }
}

class TaxiSummaryStats {
  final int totalStations;
  final int onlineTaxis;
  final int busyTaxis;
  final int offlineTaxis;
  final int waitingPassengers;
  final int completedRides;
  final double todayRevenue;

  TaxiSummaryStats({
    required this.totalStations,
    required this.onlineTaxis,
    required this.busyTaxis,
    required this.offlineTaxis,
    required this.waitingPassengers,
    required this.completedRides,
    required this.todayRevenue,
  });

  factory TaxiSummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return TaxiSummaryStats(
      totalStations: data['totalStations'] ?? 0,
      onlineTaxis: data['onlineTaxis'] ?? 0,
      busyTaxis: data['busyTaxis'] ?? 0,
      offlineTaxis: data['offlineTaxis'] ?? 0,
      waitingPassengers: data['waitingPassengers'] ?? 0,
      completedRides: data['completedRides'] ?? 0,
      todayRevenue: (data['todayRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class TerminalSummaryStats {
  final int activeBuses;
  final int delayedBuses;
  final int passengersToday;
  final double todayRevenue;

  TerminalSummaryStats({
    required this.activeBuses,
    required this.delayedBuses,
    required this.passengersToday,
    required this.todayRevenue,
  });

  factory TerminalSummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return TerminalSummaryStats(
      activeBuses: data['activeBuses'] ?? 0,
      delayedBuses: data['delayedBuses'] ?? 0,
      passengersToday: data['passengersToday'] ?? 0,
      todayRevenue: (data['todayRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class Room {
  final String id;
  final String hotelId;
  final String type;
  final double price;
  final bool isAvailable;
  final List<String> photos;

  Room({required this.id, required this.hotelId, required this.type, required this.price, required this.isAvailable, required this.photos});

  factory Room.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Room(
      id: doc.id,
      hotelId: data['hotelId'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      photos: List<String>.from(data['photos'] ?? []),
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String phone;
  final GeoPoint location;
  final String logo;
  final List<String> photos;

  Restaurant({required this.id, required this.name, required this.address, required this.phone, required this.location, required this.logo, required this.photos});

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? const GeoPoint(7.0504, 38.4955),
      logo: data['logo'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
    );
  }
}

class FoodMenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String photo;

  FoodMenuItem({required this.id, required this.restaurantId, required this.name, required this.description, required this.price, required this.photo});

  factory FoodMenuItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return FoodMenuItem(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      photo: data['photo'] ?? '',
    );
  }
}

class CityOrder {
  final String id;
  final String userId;
  final String businessId; // Restaurant, Pharmacy, etc.
  final String type; // Food, Pharmacy
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String status; // pending, preparing, delivering, completed
  final DateTime timestamp;
  final String? driverId;

  CityOrder({required this.id, required this.userId, required this.businessId, required this.type, required this.items, required this.totalAmount, required this.status, required this.timestamp, this.driverId});

  factory CityOrder.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return CityOrder(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessId: data['businessId'] ?? '',
      type: data['type'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      driverId: data['driverId'],
    );
  }
}

class HotelSummaryStats {
  final int totalHotels;
  final double totalRevenue;

  HotelSummaryStats({
    required this.totalHotels,
    required this.totalRevenue,
  });

  factory HotelSummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return HotelSummaryStats(
      totalHotels: data['totalHotels'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class TourismSummaryStats {
  final int totalBookings;
  final int tourGuides;
  final int operators;
  final int contractRides;
  final int siteVisitors;
  final double totalRevenue;

  TourismSummaryStats({
    required this.totalBookings,
    required this.tourGuides,
    required this.operators,
    required this.contractRides,
    required this.siteVisitors,
    required this.totalRevenue,
  });

  factory TourismSummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return TourismSummaryStats(
      totalBookings: data['totalBookings'] ?? 0,
      tourGuides: data['tourGuides'] ?? 0,
      operators: data['operators'] ?? 0,
      contractRides: data['contractRides'] ?? 0,
      siteVisitors: data['siteVisitors'] ?? 0,
      totalRevenue: (data['totalRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class PharmacySummaryStats {
  final int totalPharmacies;
  final int totalMedicines;

  PharmacySummaryStats({
    required this.totalPharmacies,
    required this.totalMedicines,
  });

  factory PharmacySummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return PharmacySummaryStats(
      totalPharmacies: data['totalPharmacies'] ?? 0,
      totalMedicines: data['totalMedicines'] ?? 0,
    );
  }
}

class HealthcareSummaryStats {
  final int totalHospitals;
  final int totalAmbulances;

  HealthcareSummaryStats({
    required this.totalHospitals,
    required this.totalAmbulances,
  });

  factory HealthcareSummaryStats.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return HealthcareSummaryStats(
      totalHospitals: data['totalHospitals'] ?? 0,
      totalAmbulances: data['totalAmbulances'] ?? 0,
    );
  }
}

class EmergencyRequest {
  final String id;
  final String userId;
  final String userName;
  final String type; // ambulance, police, fire, road
  final GeoPoint location;
  final String locationName;
  final String status; // pending, responding, completed
  final DateTime timestamp;
  final String? responderId;

  EmergencyRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.location,
    this.locationName = '',
    required this.status,
    required this.timestamp,
    this.responderId,
  });

  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return EmergencyRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Citizen',
      type: data['type'] ?? '',
      location: data['location'] ?? const GeoPoint(7.0504, 38.4955),
      locationName: data['locationName'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      responderId: data['responderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'location': location,
      'locationName': locationName,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'responderId': responderId,
    };
  }
}

class Ticket {
  final String id;
  final String passengerName;
  final String userId;
  final String busId;
  final String routeId;
  final int seatNumber;
  final String route;
  final String terminal;
  final double fare;
  final DateTime date;
  final String paymentStatus;
  final String qrData;
  final bool isScanned;
  final bool isUsed;

  Ticket({
    required this.id,
    required this.passengerName,
    required this.userId,
    required this.busId,
    required this.routeId,
    required this.seatNumber,
    required this.route,
    this.terminal = '',
    this.fare = 0.0,
    required this.date,
    required this.paymentStatus,
    required this.qrData,
    this.isScanned = false,
    this.isUsed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'passengerName': passengerName,
      'userId': userId,
      'busId': busId,
      'routeId': routeId,
      'seatNumber': seatNumber,
      'route': route,
      'terminal': terminal,
      'fare': fare,
      'date': Timestamp.fromDate(date),
      'paymentStatus': paymentStatus,
      'qrData': qrData,
      'isScanned': isScanned,
      'isUsed': isUsed,
    };
  }

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Ticket(
      id: doc.id,
      passengerName: data['passengerName'] ?? '',
      userId: data['userId'] ?? '',
      busId: data['busId'] ?? '',
      routeId: data['routeId'] ?? '',
      seatNumber: (data['seatNumber'] ?? 0) as int,
      route: data['route'] ?? '',
      terminal: data['terminal'] ?? '',
      fare: (data['fare'] ?? 0.0).toDouble(),
      date: (data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      paymentStatus: data['paymentStatus'] ?? '',
      qrData: data['qrData'] ?? '',
      isScanned: data['isScanned'] ?? false,
      isUsed: data['isUsed'] ?? false,
    );
  }
}
class Hospital {
  final String id;
  final String name;
  final String address;
  final String phone;
  final GeoPoint location;
  final List<String> services;
  final String status;
  final DateTime? updatedAt;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    required this.services,
    this.status = 'Active',
    this.updatedAt,
  });

  factory Hospital.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Hospital(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      services: List<String>.from(data['services'] ?? []),
      status: data['status'] ?? 'Active',
      updatedAt: (data['updatedAt'] is Timestamp) ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'location': location,
      'services': services,
      'status': status,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String phone;
  final GeoPoint location;
  final String status;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    this.status = 'Open',
  });

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Pharmacy(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      status: data['status'] ?? 'Open',
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

class TouristSite {
  final String id, name, description, category;
  final double lat, lng, rating;
  final List<String> images;
  final String openingHours, entryFee;
  final bool isActive;

  TouristSite({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.images,
    required this.openingHours,
    required this.entryFee,
    required this.isActive,
  });

  factory TouristSite.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return TouristSite(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 7.0504,
      lng: (data['lng'] as num?)?.toDouble() ?? 38.4955,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      images: List<String>.from(data['images'] ?? []),
      openingHours: data['openingHours'] ?? '6:00 AM - 6:00 PM',
      entryFee: data['entryFee'] ?? 'Free',
      isActive: data['isActive'] ?? true,
    );
  }

  factory TouristSite.fromMap(Map<String, dynamic> d, String id) => TouristSite(
        id: id,
        name: d['name'] ?? '',
        description: d['description'] ?? '',
        category: d['category'] ?? '',
        lat: (d['lat'] as num?)?.toDouble() ?? 7.0504,
        lng: (d['lng'] as num?)?.toDouble() ?? 38.4955,
        rating: (d['rating'] as num?)?.toDouble() ?? 4.5,
        images: List<String>.from(d['images'] ?? []),
        openingHours: d['openingHours'] ?? '6:00 AM - 6:00 PM',
        entryFee: d['entryFee'] ?? 'Free',
        isActive: d['isActive'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'images': images,
        'openingHours': openingHours,
        'entryFee': entryFee,
        'isActive': isActive
      };
}

class BusRoute {
  final String id;
  final String terminalId;
  final String start;
  final String destination;
  final double fare;
  final List<String> schedule;
  final List<int> availableSeats;

  BusRoute({
    required this.id,
    required this.terminalId,
    required this.start,
    required this.destination,
    required this.fare,
    required this.schedule,
    this.availableSeats = const [],
  });

  factory BusRoute.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return BusRoute(
      id: doc.id,
      terminalId: data['terminalId'] ?? '',
      start: data['start'] ?? '',
      destination: data['destination'] ?? '',
      fare: (data['fare'] ?? 0.0).toDouble(),
      schedule: List<String>.from(data['schedule'] ?? []),
      availableSeats: List<int>.from(data['availableSeats'] ?? []),
    );
  }
}

class BusVehicle {
  final String id;
  final String terminalId;
  final String plateNumber;
  final String driverName;
  final String routeId;
  final int totalSeats;
  final List<int> occupiedSeats;
  final String status;

  BusVehicle({
    required this.id,
    required this.terminalId,
    required this.plateNumber,
    required this.driverName,
    required this.routeId,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.status,
  });

  factory BusVehicle.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return BusVehicle(
      id: doc.id,
      terminalId: data['terminalId'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      driverName: data['driverName'] ?? '',
      routeId: data['routeId'] ?? '',
      totalSeats: data['totalSeats'] ?? 45,
      occupiedSeats: List<int>.from(data['occupiedSeats'] ?? []),
      status: data['status'] ?? 'ready',
    );
  }
}

class BusTerminal {
  final String id;
  final String name; // "Old Terminal" or "New Terminal"
  final String location;

  BusTerminal({required this.id, required this.name, required this.location});

  factory BusTerminal.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return BusTerminal(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
    );
  }
}


class TourPackage {
  final String id, name, description, destination, duration, guideId, guideName, operatorId;
  final double price;
  final List<String> images;
  final bool guideIncluded, vehicleIncluded;
  final String status;

  TourPackage({required this.id, required this.name, required this.description, required this.destination, required this.duration, required this.price, required this.images, required this.guideIncluded, required this.vehicleIncluded, required this.status, required this.guideId, required this.guideName, required this.operatorId});

  factory TourPackage.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return TourPackage(id: doc.id, name: d['name'] ?? '', description: d['description'] ?? '', destination: d['destination'] ?? '', duration: d['duration'] ?? '1 day', price: (d['price'] as num?)?.toDouble() ?? 0, images: List<String>.from(d['images'] ?? []), guideIncluded: d['guideIncluded'] ?? false, vehicleIncluded: d['vehicleIncluded'] ?? false, status: d['status'] ?? 'active', guideId: d['guideId'] ?? '', guideName: d['guideName'] ?? '', operatorId: d['operatorId'] ?? '');
  }

  factory TourPackage.fromMap(Map<String, dynamic> d, String id) => TourPackage(id: id, name: d['name'] ?? '', description: d['description'] ?? '', destination: d['destination'] ?? '', duration: d['duration'] ?? '1 day', price: (d['price'] as num?)?.toDouble() ?? 0, images: List<String>.from(d['images'] ?? []), guideIncluded: d['guideIncluded'] ?? false, vehicleIncluded: d['vehicleIncluded'] ?? false, status: d['status'] ?? 'active', guideId: d['guideId'] ?? '', guideName: d['guideName'] ?? '', operatorId: d['operatorId'] ?? '');

  Map<String, dynamic> toMap() => {'name': name, 'description': description, 'destination': destination, 'duration': duration, 'price': price, 'images': images, 'guideIncluded': guideIncluded, 'vehicleIncluded': vehicleIncluded, 'status': status, 'guideId': guideId, 'guideName': guideName, 'operatorId': operatorId};
}

class TourGuide {
  final String id, fullName, phone, email, experience, status, nationalId, profilePhoto;
  final List<String> languages;
  final double rating;

  TourGuide({required this.id, required this.fullName, required this.phone, required this.email, required this.experience, required this.status, required this.nationalId, required this.profilePhoto, required this.languages, required this.rating});

  factory TourGuide.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return TourGuide(id: doc.id, fullName: d['fullName'] ?? '', phone: d['phone'] ?? '', email: d['email'] ?? '', experience: d['experience'] ?? '', status: d['status'] ?? 'pending', nationalId: d['nationalId'] ?? '', profilePhoto: d['profilePhoto'] ?? '', languages: List<String>.from(d['languages'] ?? ['English']), rating: (d['rating'] as num?)?.toDouble() ?? 0);
  }

  factory TourGuide.fromMap(Map<String, dynamic> d, String id) => TourGuide(id: id, fullName: d['fullName'] ?? '', phone: d['phone'] ?? '', email: d['email'] ?? '', experience: d['experience'] ?? '', status: d['status'] ?? 'pending', nationalId: d['nationalId'] ?? '', profilePhoto: d['profilePhoto'] ?? '', languages: List<String>.from(d['languages'] ?? ['English']), rating: (d['rating'] as num?)?.toDouble() ?? 0);

  Map<String, dynamic> toMap() => {'fullName': fullName, 'phone': phone, 'email': email, 'experience': experience, 'status': status, 'nationalId': nationalId, 'profilePhoto': profilePhoto, 'languages': languages, 'rating': rating};
}

class ContractRide {
  final String id, userId, pickup, destination, vehicleType, status, passengerPhone;
  final int passengers;
  final double price;
  final DateTime date;

  ContractRide({required this.id, required this.userId, required this.pickup, required this.destination, required this.vehicleType, required this.status, required this.passengers, required this.price, required this.date, required this.passengerPhone});

  factory ContractRide.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return ContractRide(
      id: doc.id,
      userId: d['userId'] ?? '',
      pickup: d['pickup'] ?? '',
      destination: d['destination'] ?? '',
      vehicleType: d['vehicleType'] ?? 'Taxi',
      status: d['status'] ?? 'pending',
      passengers: (d['passengers'] as num?)?.toInt() ?? 1,
      price: (d['price'] as num?)?.toDouble() ?? 0,
      date: (d['date'] is Timestamp) ? (d['date'] as Timestamp).toDate() : DateTime.now(),
      passengerPhone: d['passengerPhone'] ?? ''
    );
  }

  factory ContractRide.fromMap(Map<String, dynamic> d, String id) => ContractRide(
        id: id,
        userId: d['userId'] ?? '',
        pickup: d['pickup'] ?? '',
        destination: d['destination'] ?? '',
        vehicleType: d['vehicleType'] ?? 'Taxi',
        status: d['status'] ?? 'pending',
        passengers: (d['passengers'] as num?)?.toInt() ?? 1,
        price: (d['price'] as num?)?.toDouble() ?? 0,
        date: (d['date'] is Timestamp) ? (d['date'] as Timestamp).toDate() : DateTime.now(),
        passengerPhone: d['passengerPhone'] ?? '',
      );

  Map<String, dynamic> toMap() => {'userId': userId, 'pickup': pickup, 'destination': destination, 'vehicleType': vehicleType, 'status': status, 'passengers': passengers, 'price': price, 'date': Timestamp.fromDate(date), 'passengerPhone': passengerPhone, 'createdAt': FieldValue.serverTimestamp()};
}

class TouristEvent {
  final String id, title, location, description, imageUrl;
  final DateTime date;

  TouristEvent({required this.id, required this.title, required this.location, required this.description, required this.imageUrl, required this.date});

  factory TouristEvent.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return TouristEvent(id: doc.id, title: d['title'] ?? '', location: d['location'] ?? 'Hawassa', description: d['description'] ?? '', imageUrl: d['imageUrl'] ?? '', date: (d['date'] is Timestamp) ? (d['date'] as Timestamp).toDate() : DateTime.now());
  }

  factory TouristEvent.fromMap(Map<String, dynamic> d, String id) => TouristEvent(id: id, title: d['title'] ?? '', location: d['location'] ?? 'Hawassa', description: d['description'] ?? '', imageUrl: d['imageUrl'] ?? '', date: (d['date'] is Timestamp) ? (d['date'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'title': title, 'location': location, 'description': description, 'imageUrl': imageUrl, 'date': Timestamp.fromDate(date)};
}

class TouristBooking {
  final String id, userId, userName, passengerName, phone, date, status, packageId, packageName, type;
  final int people, hours;
  final double totalPrice;
  final DateTime createdAt;

  TouristBooking({required this.id, required this.userId, required this.userName, required this.passengerName, required this.phone, required this.date, required this.status, required this.packageId, required this.packageName, required this.type, required this.people, required this.hours, required this.totalPrice, required this.createdAt});

  factory TouristBooking.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return TouristBooking(id: doc.id, userId: d['userId'] ?? '', userName: d['userName'] ?? '', passengerName: d['passengerName'] ?? '', phone: d['phone'] ?? '', date: d['date'] ?? '', status: d['status'] ?? 'pending', packageId: d['packageId'] ?? '', packageName: d['packageName'] ?? '', type: d['type'] ?? 'package', people: (d['people'] as num?)?.toInt() ?? 1, hours: (d['hours'] as num?)?.toInt() ?? 0, totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0.0, createdAt: (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : DateTime.now());
  }

  factory TouristBooking.fromMap(Map<String, dynamic> d, String id) => TouristBooking(id: id, userId: d['userId'] ?? '', userName: d['userName'] ?? '', passengerName: d['passengerName'] ?? '', phone: d['phone'] ?? '', date: d['date'] ?? '', status: d['status'] ?? 'pending', packageId: d['packageId'] ?? '', packageName: d['packageName'] ?? '', type: d['type'] ?? 'package', people: (d['people'] as num?)?.toInt() ?? 1, hours: (d['hours'] as num?)?.toInt() ?? 0, totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0.0, createdAt: (d['createdAt'] is Timestamp) ? (d['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'userId': userId, 'userName': userName, 'passengerName': passengerName, 'phone': phone, 'date': date, 'status': status, 'packageId': packageId, 'packageName': packageName, 'type': type, 'people': people, 'hours': hours, 'totalPrice': totalPrice, 'createdAt': FieldValue.serverTimestamp()};
}

class TourOperator {
  final String id, companyName, ownerName, phone, email, address, licenseNumber, description;
  final List<String> services;
  final String status;

  TourOperator({required this.id, required this.companyName, required this.ownerName, required this.phone, required this.email, required this.address, required this.licenseNumber, required this.description, required this.services, required this.status});

  factory TourOperator.fromFirestore(DocumentSnapshot doc) {
    Map d = doc.data() as Map? ?? {};
    return TourOperator(id: doc.id, companyName: d['companyName'] ?? '', ownerName: d['ownerName'] ?? '', phone: d['phone'] ?? '', email: d['email'] ?? '', address: d['address'] ?? '', licenseNumber: d['licenseNumber'] ?? '', description: d['description'] ?? '', services: List<String>.from(d['services'] ?? []), status: d['status'] ?? 'pending');
  }

  factory TourOperator.fromMap(Map<String, dynamic> d, String id) => TourOperator(id: id, companyName: d['companyName'] ?? '', ownerName: d['ownerName'] ?? '', phone: d['phone'] ?? '', email: d['email'] ?? '', address: d['address'] ?? '', licenseNumber: d['licenseNumber'] ?? '', description: d['description'] ?? '', services: List<String>.from(d['services'] ?? []), status: d['status'] ?? 'pending');

  Map<String, dynamic> toMap() => {'companyName': companyName, 'ownerName': ownerName, 'phone': phone, 'email': email, 'address': address, 'licenseNumber': licenseNumber, 'description': description, 'services': services, 'status': status};
}

class AdminProfile {
  final String uid;
  final String email;
  final UserRole role;
  final String? assignedServiceId;
  final String name;

  AdminProfile({required this.uid, required this.email, required this.role, this.assignedServiceId, required this.name});

  factory AdminProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return AdminProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == data['role'], orElse: () => UserRole.citizen),
      assignedServiceId: data['assignedServiceId'],
      name: data['name'] ?? '',
    );
  }
}

class CityAnalytics {
  final double totalRevenue;
  final int activeUsers;
  final int activeVehicles;
  final int emergencyRequestsToday;
  final Map<String, dynamic> servicePerformance;

  CityAnalytics({required this.totalRevenue, required this.activeUsers, required this.activeVehicles, required this.emergencyRequestsToday, required this.servicePerformance});
}

class Hotel {
  final String id;
  final String name;
  final String type; // Hotel or Guest House
  final String ownerId;
  final String phone;
  final String email;
  final String description;
  final String address;
  final GeoPoint location;
  final List<String> photos;
  final List<String> facilities;
  final double rating;
  final bool isActive;

  Hotel({required this.id, required this.name, required this.type, required this.ownerId, required this.phone, required this.email, required this.description, required this.address, required this.location, required this.photos, required this.facilities, this.rating = 0.0, this.isActive = true});

  factory Hotel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map? ?? {};
    return Hotel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'Hotel',
      ownerId: data['ownerId'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(7.0504, 38.4955),
      photos: List<String>.from(data['photos'] ?? data['images'] ?? []),
      facilities: List<String>.from(data['facilities'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory Hotel.fromMap(Map<String, dynamic> data, String id) => Hotel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'Hotel',
      ownerId: data['ownerId'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(7.0504, 38.4955),
      photos: List<String>.from(data['photos'] ?? data['images'] ?? []),
      facilities: List<String>.from(data['facilities'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
    );
}

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final String pickup;
  final GeoPoint pickupLocation;
  final String destination;
  final GeoPoint destinationLocation;
  final double fare;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? plateNumber;
  final String paymentMethod;
  final String stationId;
  final String stationName;
  final int etaMinutes;
  final DateTime timestamp;

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickup,
    required this.pickupLocation,
    required this.destination,
    required this.destinationLocation,
    required this.fare,
    required this.status,
    this.driverId,
    this.driverName,
    this.plateNumber,
    this.paymentMethod = 'Cash',
    this.stationId = '',
    this.stationName = 'Piassa',
    this.etaMinutes = 10,
    required this.timestamp,
  });

  factory RideRequest.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map? ?? {});
    return RideRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      pickup: data['pickup'] ?? '',
      pickupLocation: data['pickupLocation'] as GeoPoint? ?? const GeoPoint(7.0504, 38.4955),
      destination: data['destination'] ?? '',
      destinationLocation: data['destinationLocation'] as GeoPoint? ?? const GeoPoint(7.0504, 38.4955),
      fare: (data['fare'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      driverId: data['driverId'],
      driverName: data['driverName'],
      plateNumber: data['plateNumber'],
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      stationId: data['stationId'] ?? '',
      stationName: data['stationName'] ?? 'Piassa',
      etaMinutes: data['etaMinutes'] ?? 10,
      timestamp: (data['timestamp'] is Timestamp) ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'pickup': pickup,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'destinationLocation': destinationLocation,
      'fare': fare,
      'status': status,
      'driverId': driverId,
      'driverName': driverName,
      'plateNumber': plateNumber,
      'paymentMethod': paymentMethod,
      'stationId': stationId,
      'stationName': stationName,
      'etaMinutes': etaMinutes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}




