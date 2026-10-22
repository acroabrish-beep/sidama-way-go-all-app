import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';
import 'city_os_models.dart';

enum VehicleType {
  taxi,
  bajaj,
  minibus,
  cityBus,
  governmentVehicle,
  ambulance,
  fireTruck,
  policeVehicle,
  logisticsVehicle,
  maintenanceVehicle,
  inspectionVehicle,
  serviceVehicle
}

enum VehicleStatus {
  available,
  waiting,
  assigned,
  moving,
  busy,
  loading,
  offline,
  maintenance,
  inspection,
  emergency,
  reserved,
  suspended,
  retired
}

enum OwnershipType { private, government, company, cooperative }

enum FuelType { petrol, diesel, electric, hybrid, gas }

enum VehicleLifecycleStatus {
  registration,
  inspection,
  insuranceVerification,
  governmentApproval,
  hubAssignment,
  platformAssignment,
  driverAssignment,
  active,
  maintenance,
  retirement
}

enum MaintenanceStatus {
  good,
  serviceDue,
  repairRequired,
  urgentRepair,
  underMaintenance,
  grounded
}

enum BatteryType {
  none,
  leadAcid,
  lithiumIon,
  solidState,
  hydrogenCell
}

class FleetVehicle {
  final String vehicleId;
  String get id => vehicleId;
  final String fleetNumber;
  final String plateNumber;
  final VehicleType vehicleType;
  final String brand;
  final String model;
  final int manufactureYear;
  final FuelType fuelType;
  final BatteryType batteryType;
  final OwnershipType ownershipType;
  final int capacity;
  bool get availability => status == VehicleStatus.available || status == VehicleStatus.waiting;

  // Status
  final VehicleStatus status;
  final ApprovalStatus approvalStatus;
  final VehicleLifecycleStatus lifecycleStatus;

  // Compliance
  final DateTime? registrationExpiry;
  final DateTime? insuranceExpiry;
  final DateTime? inspectionExpiry;

  // Technical State
  final MaintenanceStatus maintenanceStatus;
  final double fuelLevel; // 0.0 - 100.0
  final double batteryLevel; // 0.0 - 100.0
  final double odometer;

  // Realtime
  final GeoPoint? gpsLocation;
  final double heading;
  final double speed;
  final String? currentZone;
  final bool gpsHealth;

  // Assignments
  final String assignedHubId;
  String get stationId => assignedHubId;
  final String assignedPlatformId;
  final String assignedDriverId;
  String get driverId => assignedDriverId;
  final String currentTripId;
  final String lastTripId;

  final DateTime createdAt;
  final DateTime updatedAt;

  FleetVehicle({
    required this.vehicleId,
    this.fleetNumber = '',
    required this.plateNumber,
    required this.vehicleType,
    this.brand = '',
    this.model = '',
    this.manufactureYear = 2024,
    this.fuelType = FuelType.petrol,
    this.batteryType = BatteryType.none,
    this.ownershipType = OwnershipType.private,
    this.capacity = 4,
    required this.status,
    required this.approvalStatus,
    this.lifecycleStatus = VehicleLifecycleStatus.registration,
    this.registrationExpiry,
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.maintenanceStatus = MaintenanceStatus.good,
    this.fuelLevel = 100.0,
    this.batteryLevel = 100.0,
    this.odometer = 0.0,
    this.gpsLocation,
    this.heading = 0.0,
    this.speed = 0.0,
    this.currentZone,
    this.gpsHealth = true,
    this.assignedHubId = '',
    this.assignedPlatformId = '',
    this.assignedDriverId = '',
    this.currentTripId = '',
    this.lastTripId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory FleetVehicle.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Legacy support logic
    final rawStatus = (data['status']?.toString() ?? data['taxiStatus']?.toString() ?? 'offline').toLowerCase();
    VehicleStatus vStatus = VehicleStatus.offline;
    if (rawStatus == 'waiting') vStatus = VehicleStatus.waiting;
    else if (rawStatus == 'available') vStatus = VehicleStatus.available;
    else if (rawStatus == 'busy' || rawStatus == 'on_trip' || rawStatus == 'ontrip') vStatus = VehicleStatus.busy;
    else if (rawStatus == 'moving') vStatus = VehicleStatus.moving;
    else if (rawStatus == 'emergency') vStatus = VehicleStatus.emergency;
    else if (rawStatus == 'maintenance') vStatus = VehicleStatus.maintenance;

    return FleetVehicle(
      vehicleId: doc.id,
      fleetNumber: data['fleetNumber'] ?? '',
      plateNumber: data['plateNumber'] ?? data['plate_number'] ?? '',
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['vehicleType'] ?? 'taxi').toString().toLowerCase(),
        orElse: () => VehicleType.taxi,
      ),
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      manufactureYear: (data['manufactureYear'] ?? 2024) as int,
      fuelType: FuelType.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['fuelType'] ?? 'petrol').toString().toLowerCase(),
        orElse: () => FuelType.petrol,
      ),
      batteryType: BatteryType.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['batteryType'] ?? 'none').toString().toLowerCase(),
        orElse: () => BatteryType.none,
      ),
      ownershipType: OwnershipType.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['ownershipType'] ?? 'private').toString().toLowerCase(),
        orElse: () => OwnershipType.private,
      ),
      capacity: (data['capacity'] ?? 4) as int,
      status: vStatus,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['approvalStatus'] ?? (data['approved'] == true ? 'approved' : 'pending')).toString().toLowerCase(),
        orElse: () => ApprovalStatus.pending,
      ),
      lifecycleStatus: VehicleLifecycleStatus.values.firstWhere(
        (e) => e.name == data['lifecycleStatus'],
        orElse: () => VehicleLifecycleStatus.registration
      ),
      registrationExpiry: FirestoreUtils.parseDateTime(data['registrationExpiry']),
      insuranceExpiry: FirestoreUtils.parseDateTime(data['insuranceExpiry']),
      inspectionExpiry: FirestoreUtils.parseDateTime(data['inspectionExpiry']),
      maintenanceStatus: MaintenanceStatus.values.firstWhere(
        (e) => e.name == data['maintenanceStatus'],
        orElse: () => MaintenanceStatus.good
      ),
      fuelLevel: (data['fuelLevel'] ?? 100.0).toDouble(),
      batteryLevel: (data['batteryLevel'] ?? 100.0).toDouble(),
      odometer: (data['odometer'] ?? 0.0).toDouble(),
      gpsLocation: data['gpsLocation'] as GeoPoint? ?? data['location'] as GeoPoint?,
      heading: (data['heading'] ?? 0.0).toDouble(),
      speed: (data['speed'] ?? 0.0).toDouble(),
      currentZone: data['currentZone'],
      gpsHealth: data['gpsHealth'] ?? true,
      assignedHubId: data['assignedHubId'] ?? data['stationId'] ?? '',
      assignedPlatformId: data['assignedPlatformId'] ?? '',
      assignedDriverId: data['assignedDriverId'] ?? data['driverId'] ?? '',
      currentTripId: data['currentTripId'] ?? '',
      lastTripId: data['lastTripId'] ?? '',
      createdAt: FirestoreUtils.parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreUtils.parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fleetNumber': fleetNumber,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType.name,
      'brand': brand,
      'model': model,
      'manufactureYear': manufactureYear,
      'fuelType': fuelType.name,
      'batteryType': batteryType.name,
      'ownershipType': ownershipType.name,
      'capacity': capacity,
      'status': status.name,
      'approvalStatus': approvalStatus.name,
      'lifecycleStatus': lifecycleStatus.name,
      'registrationExpiry': registrationExpiry != null ? Timestamp.fromDate(registrationExpiry!) : null,
      'insuranceExpiry': insuranceExpiry != null ? Timestamp.fromDate(insuranceExpiry!) : null,
      'inspectionExpiry': inspectionExpiry != null ? Timestamp.fromDate(inspectionExpiry!) : null,
      'maintenanceStatus': maintenanceStatus.name,
      'fuelLevel': fuelLevel,
      'batteryLevel': batteryLevel,
      'odometer': odometer,
      'gpsLocation': gpsLocation,
      'heading': heading,
      'speed': speed,
      'currentZone': currentZone,
      'gpsHealth': gpsHealth,
      'assignedHubId': assignedHubId,
      'assignedPlatformId': assignedPlatformId,
      'assignedDriverId': assignedDriverId,
      'currentTripId': currentTripId,
      'lastTripId': lastTripId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Maintenance Engine Models
class MaintenanceRecord {
  final String recordId;
  final String vehicleId;
  final String serviceType;
  final String description;
  final double cost;
  final double odometerAtService;
  final String technicianId;
  final DateTime serviceDate;

  MaintenanceRecord({
    required this.recordId,
    required this.vehicleId,
    required this.serviceType,
    required this.description,
    required this.cost,
    required this.odometerAtService,
    required this.technicianId,
    required this.serviceDate,
  });

  factory MaintenanceRecord.fromMap(Map<String, dynamic> data, String id) {
    return MaintenanceRecord(
      recordId: id,
      vehicleId: data['vehicleId'] ?? '',
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      cost: (data['cost'] ?? 0.0).toDouble(),
      odometerAtService: (data['odometerAtService'] ?? 0.0).toDouble(),
      technicianId: data['technicianId'] ?? '',
      serviceDate: FirestoreUtils.parseDateTimeOrDefault(data['serviceDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'description': description,
      'cost': cost,
      'odometerAtService': odometerAtService,
      'technicianId': technicianId,
      'serviceDate': Timestamp.fromDate(serviceDate),
    };
  }
}

class MaintenanceReminder {
  final String reminderId;
  final String vehicleId;
  final String title;
  final String description;
  final DateTime dueDate;
  final double dueOdometer;
  final bool isCompleted;

  MaintenanceReminder({
    required this.reminderId,
    required this.vehicleId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.dueOdometer = 0.0,
    this.isCompleted = false,
  });

  factory MaintenanceReminder.fromMap(Map<String, dynamic> data, String id) {
    return MaintenanceReminder(
      reminderId: id,
      vehicleId: data['vehicleId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: FirestoreUtils.parseDateTimeOrDefault(data['dueDate']),
      dueOdometer: (data['dueOdometer'] ?? 0.0).toDouble(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueOdometer': dueOdometer,
      'isCompleted': isCompleted,
    };
  }
}

// Backward compatibility aliases
typedef TransportVehicle = FleetVehicle;
typedef Taxi = FleetVehicle;

// Preserve other models required by the system
enum DriverStatus { pending, approved, rejected, suspended }
enum TaxiStatus { waiting, offline, busy, onTrip }

class TaxiRoute {
  final String id;
  final String from;
  final String to;
  final double fare;

  TaxiRoute({required this.id, required this.from, required this.to, required this.fare});

  factory TaxiRoute.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return TaxiRoute(
      id: doc.id,
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      fare: (data['fare'] ?? 0).toDouble(),
    );
  }
}

enum WorkforceRole {
  taxiDriver,
  bajajDriver,
  minibusDriver,
  busDriver,
  governmentDriver,
  ambulanceDriver,
  fireServiceDriver,
  policeDriver,
  logisticsDriver,
  maintenanceOperator,
  inspector,
  dispatchOfficer,
  stationSupervisor
}

enum EmploymentStatus {
  fullTime,
  partTime,
  contract,
  temporary,
  volunteer,
  onLeave,
  suspended,
  retired
}

enum WorkforceLifecycleStatus {
  registration,
  identityVerified,
  documentVerified,
  licenseVerified,
  medicalCleared,
  trainingCompleted,
  supervisorApproved,
  governmentApproved,
  active,
  suspended,
  medicalHold,
  licenseExpired,
  emergencyAssignment,
  retired
}

enum ShiftType {
  morning,
  afternoon,
  night,
  emergency,
  weekend,
  holiday,
  custom
}

class WorkforceMember {
  final String workerId;
  String get id => workerId;
  final String employeeNumber;
  final String governmentId;
  final String fullName;
  final WorkforceRole role;
  final String department;
  final String organization;
  final String phone;
  final String email;
  final String photo;
  String get profilePhoto => photo;

  // Compliance
  final String licenseNumber;
  String get drivingLicense => licenseNumber;
  final DateTime? licenseExpiry;
  final String medicalCertificate;
  final DateTime? medicalExpiry;
  final String trainingCertificate;
  final List<String> skills;
  final List<String> permissions;

  // Status
  final EmploymentStatus employmentStatus;
  final WorkforceLifecycleStatus lifecycleStatus;
  final ApprovalStatus governmentApproval;

  // Legacy Compatibility Getters
  TaxiStatus get status => online ? TaxiStatus.waiting : TaxiStatus.offline;
  DriverStatus get approvalStatus => governmentApproval == ApprovalStatus.approved ? DriverStatus.approved : (governmentApproval == ApprovalStatus.suspended ? DriverStatus.suspended : DriverStatus.pending);

  // Assignments
  final String assignedHubId;
  String get stationId => assignedHubId;
  final String assignedPlatformId;
  final String assignedVehicleId;
  String get plateNumber => assignedVehicleId;
  final String vehicleModel; // Added legacy field
  final String assignedShiftId;
  final List<VehicleType> vehicleTypesAllowed;
  String get stationName => 'Hub-$assignedHubId'; // fallback

  // Performance
  final double performanceScore;
  final double safetyScore;
  final double attendanceScore;
  final double rating;
  final int completedTrips;
  final int cancelledTrips;
  final int violations;
  final int rewardPoints;

  // Realtime
  final bool gpsEnabled;
  final bool online;
  final GeoPoint? lastKnownLocation;
  GeoPoint? get location => lastKnownLocation;
  final double heading;
  final double speed;
  final String? currentZone;
  final DateTime? lastUpdate;

  final DateTime createdAt;
  final DateTime updatedAt;

  WorkforceMember({
    required this.workerId,
    this.employeeNumber = '',
    this.governmentId = '',
    required this.fullName,
    required this.role,
    this.department = 'Operations',
    this.organization = 'Sidama Transport Authority',
    required this.phone,
    this.email = '',
    this.photo = '',
    this.licenseNumber = '',
    this.licenseExpiry,
    this.medicalCertificate = '',
    this.medicalExpiry,
    this.trainingCertificate = '',
    this.skills = const [],
    this.permissions = const [],
    this.employmentStatus = EmploymentStatus.fullTime,
    this.lifecycleStatus = WorkforceLifecycleStatus.registration,
    this.governmentApproval = ApprovalStatus.pending,
    this.assignedHubId = '',
    this.assignedPlatformId = '',
    this.assignedVehicleId = '',
    this.vehicleModel = '',
    this.assignedShiftId = '',
    this.vehicleTypesAllowed = const [VehicleType.taxi],
    this.performanceScore = 100.0,
    this.safetyScore = 100.0,
    this.attendanceScore = 100.0,
    this.rating = 5.0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.violations = 0,
    this.rewardPoints = 0,
    this.gpsEnabled = true,
    this.online = false,
    this.lastKnownLocation,
    this.heading = 0.0,
    this.speed = 0.0,
    this.currentZone,
    this.lastUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WorkforceMember.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Role mapping with legacy support
    final rawRole = (data['role'] ?? data['vehicleType'] ?? 'taxiDriver').toString().toLowerCase();
    WorkforceRole parsedRole = WorkforceRole.taxiDriver;
    if (rawRole.contains('bajaj')) parsedRole = WorkforceRole.bajajDriver;
    else if (rawRole.contains('bus')) parsedRole = WorkforceRole.busDriver;
    else if (rawRole.contains('ambulance')) parsedRole = WorkforceRole.ambulanceDriver;
    else if (rawRole.contains('inspector')) parsedRole = WorkforceRole.inspector;

    // Status mapping with legacy support
    final rawStatus = (data['approvalStatus'] ?? data['status'] ?? 'pending').toString().toLowerCase();
    WorkforceLifecycleStatus lStatus = WorkforceLifecycleStatus.registration;
    if (rawStatus == 'approved' || rawStatus == 'active') lStatus = WorkforceLifecycleStatus.active;
    else if (rawStatus == 'suspended') lStatus = WorkforceLifecycleStatus.suspended;

    return WorkforceMember(
      workerId: doc.id,
      employeeNumber: data['employeeNumber'] ?? data['membershipNumber'] ?? '',
      governmentId: data['governmentId'] ?? data['nationalId'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      role: WorkforceRole.values.firstWhere((e) => e.name.toLowerCase() == rawRole, orElse: () => parsedRole),
      department: data['department'] ?? 'Operations',
      organization: data['organization'] ?? 'Sidama Transport Authority',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      photo: data['photo'] ?? data['profilePhoto'] ?? '',
      licenseNumber: data['licenseNumber'] ?? data['drivingLicense'] ?? '',
      licenseExpiry: FirestoreUtils.parseDateTime(data['licenseExpiry']),
      medicalCertificate: data['medicalCertificate'] ?? '',
      medicalExpiry: FirestoreUtils.parseDateTime(data['medicalExpiry']),
      trainingCertificate: data['trainingCertificate'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      permissions: List<String>.from(data['permissions'] ?? []),
      employmentStatus: EmploymentStatus.values.firstWhere((e) => e.name == data['employmentStatus'], orElse: () => EmploymentStatus.fullTime),
      lifecycleStatus: WorkforceLifecycleStatus.values.firstWhere((e) => e.name == data['lifecycleStatus'], orElse: () => lStatus),
      governmentApproval: ApprovalStatus.values.firstWhere((e) => e.name.toLowerCase() == rawStatus, orElse: () => ApprovalStatus.pending),
      assignedHubId: data['assignedHubId'] ?? data['stationId'] ?? '',
      assignedPlatformId: data['assignedPlatformId'] ?? '',
      assignedVehicleId: data['assignedVehicleId'] ?? data['plateNumber'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      assignedShiftId: data['assignedShiftId'] ?? '',
      vehicleTypesAllowed: (data['vehicleTypesAllowed'] as List?)?.map((e) => VehicleType.values.firstWhere((v) => v.name == e)).toList() ?? [VehicleType.taxi],
      performanceScore: (data['performanceScore'] ?? 100.0).toDouble(),
      safetyScore: (data['safetyScore'] ?? 100.0).toDouble(),
      attendanceScore: (data['attendanceScore'] ?? 100.0).toDouble(),
      rating: (data['rating'] ?? 5.0).toDouble(),
      completedTrips: (data['completedTrips'] ?? 0) as int,
      cancelledTrips: (data['cancelledTrips'] ?? 0) as int,
      violations: (data['violations'] ?? 0) as int,
      rewardPoints: (data['rewardPoints'] ?? 0) as int,
      gpsEnabled: data['gpsEnabled'] ?? true,
      online: data['online'] ?? data['isOnline'] ?? false,
      lastKnownLocation: data['lastKnownLocation'] as GeoPoint? ?? data['location'] as GeoPoint?,
      heading: (data['heading'] ?? 0.0).toDouble(),
      speed: (data['speed'] ?? 0.0).toDouble(),
      currentZone: data['currentZone'],
      lastUpdate: FirestoreUtils.parseDateTime(data['lastUpdate']),
      createdAt: FirestoreUtils.parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreUtils.parseDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeNumber': employeeNumber,
      'governmentId': governmentId,
      'fullName': fullName,
      'role': role.name,
      'department': department,
      'organization': organization,
      'phone': phone,
      'email': email,
      'photo': photo,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry != null ? Timestamp.fromDate(licenseExpiry!) : null,
      'medicalCertificate': medicalCertificate,
      'medicalExpiry': medicalExpiry != null ? Timestamp.fromDate(medicalExpiry!) : null,
      'trainingCertificate': trainingCertificate,
      'skills': skills,
      'permissions': permissions,
      'employmentStatus': employmentStatus.name,
      'lifecycleStatus': lifecycleStatus.name,
      'governmentApproval': governmentApproval.name,
      'assignedHubId': assignedHubId,
      'assignedPlatformId': assignedPlatformId,
      'assignedVehicleId': assignedVehicleId,
      'vehicleModel': vehicleModel,
      'assignedShiftId': assignedShiftId,
      'vehicleTypesAllowed': vehicleTypesAllowed.map((e) => e.name).toList(),
      'performanceScore': performanceScore,
      'safetyScore': safetyScore,
      'attendanceScore': attendanceScore,
      'rating': rating,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'violations': violations,
      'rewardPoints': rewardPoints,
      'gpsEnabled': gpsEnabled,
      'online': online,
      'lastKnownLocation': lastKnownLocation,
      'heading': heading,
      'speed': speed,
      'currentZone': currentZone,
      'lastUpdate': lastUpdate != null ? Timestamp.fromDate(lastUpdate!) : FieldValue.serverTimestamp(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Backward compatibility alias
typedef TaxiDriver = WorkforceMember;

enum StationHealth { normal, busy, congested, critical, full, closed }

class TransportHub {
  final String stationId;
  String get id => stationId;
  final String stationName;
  String get name => stationName;
  final String stationCode;
  String get code => stationCode;

  // Hierarchy
  final String country;
  final String region;
  final String city;
  final String zone;

  final GeoPoint location;
  final String address;
  final List<VehicleType> supportedVehicleTypes;
  final int maximumVehicleCapacity;
  int get capacity => maximumVehicleCapacity;
  final Map<VehicleType, int> maximumCapacityPerVehicleType;
  final int currentVehicleCount;
  int get totalTaxiCount => currentVehicleCount;
  final Map<VehicleType, int> currentVehicleCountPerVehicleType;

  // Realtime Counters (Global & Specific)
  final int availableVehicles;
  int get onlineTaxiCount => availableVehicles;
  int get activeTaxiCount => availableVehicles;
  final int busyVehicles;
  final int movingVehicles;
  final int waitingVehicles;
  int get waitingPassengers => waitingVehicles;
  final int offlineVehicles;
  final int maintenanceVehicles;
  final int governmentVehicles;
  final int emergencyVehicles;

  // Specific Type Counters (Mandatory for Fleet Management)
  final int taxiVehicles;
  final int bajajVehicles;
  final int busVehicles;
  final int minibusVehicles;
  final int ambulanceVehicles;
  final int fireVehicles;
  final int policeVehicles;
  final int governmentFleetVehicles;
  final int logisticsVehicles;
  final int maintenanceFleetVehicles;
  final int inspectionVehicles;

  final StationHealth healthStatus;
  String get status => isOperational ? 'Active' : 'Inactive';
  final double occupancyPercentage;
  final int averageWaitingTime; // minutes
  int get estimatedWaitTime => averageWaitingTime;
  final int averageDispatchTime; // minutes
  final int queueLength;
  int get queueCount => queueLength;
  final bool isOperational;
  final bool isClosed;

  // Management & Ops
  final String managerName;
  final String managerEmail;
  final int dailyRides;
  final double dailyIncome;
  final int gpsRadius;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Sub-Management
  final List<TransportPlatform> platforms;

  TransportHub({
    String stationId = '',
    String stationName = 'Unknown Station',
    String stationCode = 'HUB',
    this.country = 'Ethiopia',
    this.region = 'Sidama',
    this.city = 'Hawassa',
    this.zone = 'Central',
    required this.location,
    this.address = '',
    this.supportedVehicleTypes = const [VehicleType.taxi, VehicleType.bajaj],
    int maximumVehicleCapacity = 50,
    this.maximumCapacityPerVehicleType = const {},
    this.currentVehicleCount = 0,
    this.currentVehicleCountPerVehicleType = const {},
    this.availableVehicles = 0,
    this.busyVehicles = 0,
    this.movingVehicles = 0,
    this.waitingVehicles = 0,
    this.offlineVehicles = 0,
    this.maintenanceVehicles = 0,
    this.governmentVehicles = 0,
    this.emergencyVehicles = 0,
    this.taxiVehicles = 0,
    this.bajajVehicles = 0,
    this.busVehicles = 0,
    this.minibusVehicles = 0,
    this.ambulanceVehicles = 0,
    this.fireVehicles = 0,
    this.policeVehicles = 0,
    this.governmentFleetVehicles = 0,
    this.logisticsVehicles = 0,
    this.maintenanceFleetVehicles = 0,
    this.inspectionVehicles = 0,
    this.healthStatus = StationHealth.normal,
    this.occupancyPercentage = 0.0,
    this.averageWaitingTime = 12,
    this.averageDispatchTime = 5,
    this.queueLength = 0,
    this.isOperational = true,
    this.isClosed = false,
    this.managerName = '',
    this.managerEmail = '',
    this.dailyRides = 0,
    this.dailyIncome = 0.0,
    this.gpsRadius = 800,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.platforms = const [],
    // Legacy support params
    String? id,
    String? name,
    int? capacity,
    String? status,
  })  : stationId = id ?? stationId,
        stationName = name ?? stationName,
        stationCode = stationCode,
        maximumVehicleCapacity = capacity ?? maximumVehicleCapacity,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TransportHub.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final int maxCap = (data['maximumVehicleCapacity'] ?? data['capacity'] ?? 50) as int;
    final int currentCount = (data['currentVehicleCount'] ?? data['totalTaxiCount'] ?? 0) as int;
    final double occupancy = maxCap > 0 ? (currentCount / maxCap) * 100 : 0.0;

    StationHealth health = StationHealth.normal;
    if (data['isClosed'] == true || data['status'] == 'Inactive') {
      health = StationHealth.closed;
    } else if (occupancy >= 100) {
      health = StationHealth.full;
    } else if (occupancy >= 91) {
      health = StationHealth.critical;
    } else if (occupancy >= 76) {
      health = StationHealth.congested;
    } else if (occupancy >= 51) {
      health = StationHealth.busy;
    }

    return TransportHub(
      stationId: doc.id,
      stationName: data['stationName'] ?? data['name'] ?? 'Unknown Station',
      stationCode: data['stationCode'] ?? data['code'] ?? doc.id.substring(0, 4).toUpperCase(),
      country: data['country'] ?? 'Ethiopia',
      region: data['region'] ?? 'Sidama',
      city: data['city'] ?? 'Hawassa',
      zone: data['zone'] ?? 'Central',
      location: data['location'] as GeoPoint? ?? const GeoPoint(7.0504, 38.4955),
      address: data['address'] ?? '',
      supportedVehicleTypes: (data['supportedVehicleTypes'] as List?)
          ?.map((e) => VehicleType.values.firstWhere((v) => v.name == e))
          .toList() ?? [VehicleType.taxi, VehicleType.bajaj],
      maximumVehicleCapacity: maxCap,
      maximumCapacityPerVehicleType: (data['maximumCapacityPerVehicleType'] as Map?)?.cast<String, int>().map((k, v) => MapEntry(VehicleType.values.firstWhere((e) => e.name == k), v)) ?? {},
      currentVehicleCount: currentCount,
      currentVehicleCountPerVehicleType: (data['currentVehicleCountPerVehicleType'] as Map?)?.cast<String, int>().map((k, v) => MapEntry(VehicleType.values.firstWhere((e) => e.name == k), v)) ?? {},
      availableVehicles: (data['availableVehicles'] ?? data['onlineTaxiCount'] ?? 0) as int,
      busyVehicles: (data['busyVehicles'] ?? 0) as int,
      movingVehicles: (data['movingVehicles'] ?? 0) as int,
      waitingVehicles: (data['waitingVehicles'] ?? data['waitingPassengers'] ?? 0) as int,
      offlineVehicles: (data['offlineVehicles'] ?? 0) as int,
      maintenanceVehicles: (data['maintenanceVehicles'] ?? 0) as int,
      governmentVehicles: (data['governmentVehicles'] ?? 0) as int,
      emergencyVehicles: (data['emergencyVehicles'] ?? 0) as int,
      taxiVehicles: (data['taxiVehicles'] ?? 0) as int,
      bajajVehicles: (data['bajajVehicles'] ?? 0) as int,
      busVehicles: (data['busVehicles'] ?? 0) as int,
      minibusVehicles: (data['minibusVehicles'] ?? 0) as int,
      ambulanceVehicles: (data['ambulanceVehicles'] ?? 0) as int,
      fireVehicles: (data['fireVehicles'] ?? 0) as int,
      policeVehicles: (data['policeVehicles'] ?? 0) as int,
      governmentFleetVehicles: (data['governmentFleetVehicles'] ?? 0) as int,
      logisticsVehicles: (data['logisticsVehicles'] ?? 0) as int,
      maintenanceFleetVehicles: (data['maintenanceFleetVehicles'] ?? 0) as int,
      inspectionVehicles: (data['inspectionVehicles'] ?? 0) as int,
      healthStatus: health,
      occupancyPercentage: occupancy,
      averageWaitingTime: (data['averageWaitingTime'] ?? data['estimatedWaitTime'] ?? 12) as int,
      averageDispatchTime: (data['averageDispatchTime'] ?? 5) as int,
      queueLength: (data['queueLength'] ?? data['queueCount'] ?? 0) as int,
      isOperational: data['isOperational'] ?? (data['status'] == 'Active'),
      isClosed: data['isClosed'] ?? false,
      managerName: data['managerName'] ?? '',
      managerEmail: data['managerEmail'] ?? '',
      dailyRides: (data['dailyRides'] ?? 0) as int,
      dailyIncome: (data['dailyIncome'] ?? 0.0).toDouble(),
      gpsRadius: (data['gpsRadius'] ?? 800) as int,
      createdAt: FirestoreUtils.parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: FirestoreUtils.parseDateTime(data['updatedAt']) ?? DateTime.now(),
      platforms: (data['platforms'] as List?)?.map((e) => TransportPlatform.fromMap(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationName': stationName,
      'stationCode': stationCode,
      'country': country,
      'region': region,
      'city': city,
      'zone': zone,
      'location': location,
      'address': address,
      'supportedVehicleTypes': supportedVehicleTypes.map((e) => e.name).toList(),
      'maximumVehicleCapacity': maximumVehicleCapacity,
      'maximumCapacityPerVehicleType': maximumCapacityPerVehicleType.map((k, v) => MapEntry(k.name, v)),
      'currentVehicleCount': currentVehicleCount,
      'currentVehicleCountPerVehicleType': currentVehicleCountPerVehicleType.map((k, v) => MapEntry(k.name, v)),
      'availableVehicles': availableVehicles,
      'busyVehicles': busyVehicles,
      'movingVehicles': movingVehicles,
      'waitingVehicles': waitingVehicles,
      'offlineVehicles': offlineVehicles,
      'maintenanceVehicles': maintenanceVehicles,
      'governmentVehicles': governmentVehicles,
      'emergencyVehicles': emergencyVehicles,
      'taxiVehicles': taxiVehicles,
      'bajajVehicles': bajajVehicles,
      'busVehicles': busVehicles,
      'minibusVehicles': minibusVehicles,
      'ambulanceVehicles': ambulanceVehicles,
      'fireVehicles': fireVehicles,
      'policeVehicles': policeVehicles,
      'governmentFleetVehicles': governmentFleetVehicles,
      'logisticsVehicles': logisticsVehicles,
      'maintenanceFleetVehicles': maintenanceFleetVehicles,
      'inspectionVehicles': inspectionVehicles,
      'healthStatus': healthStatus.name,
      'occupancyPercentage': occupancyPercentage,
      'averageWaitingTime': averageWaitingTime,
      'averageDispatchTime': averageDispatchTime,
      'queueLength': queueLength,
      'isOperational': isOperational,
      'isClosed': isClosed,
      'managerName': managerName,
      'managerEmail': managerEmail,
      'dailyRides': dailyRides,
      'dailyIncome': dailyIncome,
      'gpsRadius': gpsRadius,
      'platforms': platforms.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class TransportPlatform {
  final String platformId;
  final String platformName;
  final VehicleType vehicleType;
  final int capacity;
  final int currentVehicles;
  final int queueLength;
  final StationHealth health;
  final String status;

  // Smart Queue Engine Metrics
  final double dispatchRate; // vehicles/hour
  final double arrivalRate; // vehicles/hour
  final int avgWaitTime; // minutes
  final double rotationIndex; // turnover speed

  TransportPlatform({
    required this.platformId,
    required this.platformName,
    required this.vehicleType,
    required this.capacity,
    this.currentVehicles = 0,
    this.queueLength = 0,
    this.health = StationHealth.normal,
    this.status = 'Operational',
    this.dispatchRate = 0.0,
    this.arrivalRate = 0.0,
    this.avgWaitTime = 0,
    this.rotationIndex = 1.0,
  });

  factory TransportPlatform.fromMap(Map<String, dynamic> map) {
    return TransportPlatform(
      platformId: map['platformId'] ?? '',
      platformName: map['platformName'] ?? '',
      vehicleType: VehicleType.values.firstWhere((e) => e.name == map['vehicleType'], orElse: () => VehicleType.taxi),
      capacity: (map['capacity'] ?? 10) as int,
      currentVehicles: (map['currentVehicles'] ?? 0) as int,
      queueLength: (map['queueLength'] ?? 0) as int,
      health: StationHealth.values.firstWhere((e) => e.name == map['health'], orElse: () => StationHealth.normal),
      status: map['status'] ?? 'Operational',
      dispatchRate: (map['dispatchRate'] ?? 0.0).toDouble(),
      arrivalRate: (map['arrivalRate'] ?? 0.0).toDouble(),
      avgWaitTime: (map['avgWaitTime'] ?? 0) as int,
      rotationIndex: (map['rotationIndex'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platformId': platformId,
      'platformName': platformName,
      'vehicleType': vehicleType.name,
      'capacity': capacity,
      'currentVehicles': currentVehicles,
      'queueLength': queueLength,
      'health': health.name,
      'status': status,
      'dispatchRate': dispatchRate,
      'arrivalRate': arrivalRate,
      'avgWaitTime': avgWaitTime,
      'rotationIndex': rotationIndex,
    };
  }
}

class StationQueueEntry {
  final String id;
  final String stationId;
  final String stationName;
  final String driverId;
  final String driverName;
  final DateTime joinedAt;
  final String status;

  StationQueueEntry({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.driverId,
    required this.driverName,
    required this.joinedAt,
    required this.status,
  });

  factory StationQueueEntry.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return StationQueueEntry(
      id: doc.id,
      stationId: data['stationId'] ?? '',
      stationName: data['stationName'] ?? '',
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      joinedAt:
          FirestoreUtils.parseDateTime(data['joinedAt']) ?? DateTime.now(),
      status: data['status'] ?? 'queued',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'driverId': driverId,
      'driverName': driverName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status,
    };
  }
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
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return RideRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      pickup: data['pickup'] ?? '',
      pickupLocation:
          data['pickupLocation'] as GeoPoint? ??
          const GeoPoint(7.0504, 38.4955),
      destination: data['destination'] ?? '',
      destinationLocation:
          data['destinationLocation'] as GeoPoint? ??
          const GeoPoint(7.0504, 38.4955),
      fare: (data['fare'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      driverId: data['driverId'],
      driverName: data['driverName'],
      plateNumber: data['plateNumber'],
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      stationId: data['stationId'] ?? '',
      stationName: data['stationName'] ?? 'Piassa',
      etaMinutes: data['etaMinutes'] ?? 10,
      timestamp: FirestoreUtils.parseDateTimeOrDefault(data['timestamp']),
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

typedef TaxiStation = TransportHub;
