enum EmergencyRequestType {
  ambulance(
    'ambulance',
    'Ambulance',
    'Medical emergency: an ambulance is requested.',
  ),
  police('police', 'Police', 'Police assistance is requested.'),
  fire('fire', 'Fire', 'Fire emergency: the fire service is requested.'),
  roadAssist('road_assist', 'Road Assist', 'Roadside assistance is requested.');

  const EmergencyRequestType(
    this.wireValue,
    this.label,
    this.defaultDescription,
  );

  final String wireValue;
  final String label;
  final String defaultDescription;

  static EmergencyRequestType? fromWire(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final type in EmergencyRequestType.values) {
      if (type.wireValue == normalized) return type;
    }
    return null;
  }
}

class EmergencyIncidentModel {
  const EmergencyIncidentModel({
    required this.id,
    required this.incidentCode,
    required this.requesterFirebaseUid,
    required this.emergencyType,
    required this.priority,
    required this.status,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.assigneeFirebaseUid,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });

  static const activeStatuses = ['reported', 'acknowledged', 'in_progress'];
  static const resolvedStatuses = ['resolved', 'closed'];

  final String id;
  final String incidentCode;
  final String requesterFirebaseUid;
  final String emergencyType;
  final String priority;
  final String status;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? assigneeFirebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  factory EmergencyIncidentModel.fromRow(Map<String, dynamic> row) {
    final id = _readString(row['id']);
    if (id.isEmpty) {
      throw const FormatException('Emergency incident is missing its id.');
    }
    return EmergencyIncidentModel(
      id: id,
      incidentCode: _readString(row['incident_code']),
      requesterFirebaseUid: _readString(row['requester_firebase_uid']),
      emergencyType: _readString(
        row['emergency_type'] ?? row['incident_type'],
      ).toLowerCase(),
      priority: _readString(row['priority'] ?? row['severity']).toLowerCase(),
      status: _readString(row['status']).toLowerCase(),
      description: _readString(row['description']),
      latitude: _readDouble(row['latitude']),
      longitude: _readDouble(row['longitude']),
      assigneeFirebaseUid: _readOptionalString(row['assignee_firebase_uid']),
      createdAt: _readDate(row['created_at']),
      updatedAt: _readDate(row['updated_at']),
      resolvedAt: _readDate(row['resolved_at']),
    );
  }

  bool get isActive => activeStatuses.contains(status);

  bool get isResolved => resolvedStatuses.contains(status);

  bool get isCritical => priority == 'critical';

  String get typeLabel {
    final type = EmergencyRequestType.fromWire(emergencyType);
    if (type != null) return type.label;
    if (emergencyType.isEmpty) return 'Emergency';
    return _titleCase(emergencyType.replaceAll('_', ' '));
  }

  String get statusLabel {
    switch (status) {
      case 'reported':
        return 'Reported';
      case 'acknowledged':
        return 'Acknowledged';
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status.isEmpty ? 'Unknown' : _titleCase(status);
    }
  }

  String get priorityLabel {
    if (priority.isEmpty) return 'Unknown';
    return _titleCase(priority);
  }

  String get coordinatesLabel {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return 'Coordinates not recorded';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

String _readString(Object? value) => value?.toString().trim() ?? '';

String? _readOptionalString(Object? value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _readDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String _titleCase(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
