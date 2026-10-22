import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

enum IncidentType {
  medical,
  fire,
  police,
  trafficAccident,
  naturalDisaster,
  flood,
  landslide,
  buildingCollapse,
  crimeReport,
  missingPerson,
  publicSafety,
  governmentEmergency
}

enum IncidentPriority { low, medium, high, critical }

enum IncidentStatus {
  reported,
  aiClassified,
  dispatcherReviewed,
  unitAssigned,
  enRoute,
  onScene,
  resolving,
  resolved,
  cancelled
}

class EmergencyIncident {
  final String incidentId;
  final IncidentType type;
  final IncidentPriority priority;
  final double severity; // 0.0 to 1.0
  final IncidentStatus status;

  final String reportedBy;
  final String reporterRole;
  final GeoPoint location;
  final String address;
  final String description;

  final List<String> photos;
  final List<String> videos;

  final String assignedUnitId;
  final String assignedCommanderId;
  final List<String> assignedVehicleIds;
  final List<String> assignedWorkforceIds;

  final int responseEtaMinutes;
  final DateTime? arrivalTime;
  final DateTime? resolutionTime;

  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyIncident({
    required this.incidentId,
    required this.type,
    required this.priority,
    this.severity = 0.5,
    required this.status,
    required this.reportedBy,
    this.reporterRole = 'citizen',
    required this.location,
    this.address = '',
    required this.description,
    this.photos = const [],
    this.videos = const [],
    this.assignedUnitId = '',
    this.assignedCommanderId = '',
    this.assignedVehicleIds = const [],
    this.assignedWorkforceIds = const [],
    this.responseEtaMinutes = 0,
    this.arrivalTime,
    this.resolutionTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyIncident.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return EmergencyIncident(
      incidentId: doc.id,
      type: IncidentType.values.firstWhere((e) => e.name == data['type'], orElse: () => IncidentType.medical),
      priority: IncidentPriority.values.firstWhere((e) => e.name == data['priority'], orElse: () => IncidentPriority.medium),
      severity: (data['severity'] ?? 0.5).toDouble(),
      status: IncidentStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => IncidentStatus.reported),
      reportedBy: data['reportedBy'] ?? '',
      reporterRole: data['reporterRole'] ?? 'citizen',
      location: data['location'] as GeoPoint? ?? const GeoPoint(7.0622, 38.4763),
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      assignedUnitId: data['assignedUnitId'] ?? '',
      assignedCommanderId: data['assignedCommanderId'] ?? '',
      assignedVehicleIds: List<String>.from(data['assignedVehicleIds'] ?? []),
      assignedWorkforceIds: List<String>.from(data['assignedWorkforceIds'] ?? []),
      responseEtaMinutes: (data['responseEtaMinutes'] ?? 0) as int,
      arrivalTime: FirestoreUtils.parseDateTime(data['arrivalTime']),
      resolutionTime: FirestoreUtils.parseDateTime(data['resolutionTime']),
      createdAt: FirestoreUtils.parseDateTimeOrDefault(data['createdAt']),
      updatedAt: FirestoreUtils.parseDateTimeOrDefault(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'priority': priority.name,
      'severity': severity,
      'status': status.name,
      'reportedBy': reportedBy,
      'reporterRole': reporterRole,
      'location': location,
      'address': address,
      'description': description,
      'photos': photos,
      'videos': videos,
      'assignedUnitId': assignedUnitId,
      'assignedCommanderId': assignedCommanderId,
      'assignedVehicleIds': assignedVehicleIds,
      'assignedWorkforceIds': assignedWorkforceIds,
      'responseEtaMinutes': responseEtaMinutes,
      'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'resolutionTime': resolutionTime != null ? Timestamp.fromDate(resolutionTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class HospitalCapacity {
  final String hospitalId;
  final String hospitalName;
  final int totalBeds;
  final int availableBeds;
  final int erQueueLength;
  final bool intensiveCareAvailable;
  final String bloodBankStatus; // Normal, Low, Critical

  HospitalCapacity({
    required this.hospitalId,
    required this.hospitalName,
    required this.totalBeds,
    required this.availableBeds,
    required this.erQueueLength,
    required this.intensiveCareAvailable,
    required this.bloodBankStatus,
  });

  factory HospitalCapacity.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return HospitalCapacity(
      hospitalId: doc.id,
      hospitalName: data['hospitalName'] ?? '',
      totalBeds: (data['totalBeds'] ?? 0) as int,
      availableBeds: (data['availableBeds'] ?? 0) as int,
      erQueueLength: (data['erQueueLength'] ?? 0) as int,
      intensiveCareAvailable: data['intensiveCareAvailable'] ?? true,
      bloodBankStatus: data['bloodBankStatus'] ?? 'Normal',
    );
  }
}
