import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus {
  pending,
  inProgress,
  resolved,
}

class CitizenReport {
  final String id;
  final String reporterFirebaseUid;
  final String category;
  final String? description;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CitizenReport({
    required this.id,
    required this.reporterFirebaseUid,
    required this.category,
    this.description,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Normalizes category string to match backend enum values
  static String normalizeCategory(String category) {
    final c = category.toLowerCase().trim();
    
    if (c.contains('road') || c.contains('damage') || c.contains('pothole')) {
      return 'pothole';
    }
    if (c.contains('waste') || c.contains('garbage') || c.contains('trash')) {
      return 'garbage';
    }
    if (c.contains('street') && c.contains('light') || c.contains('lamp')) {
      return 'street_light';
    }
    if (c.contains('water') || c.contains('leak') || c.contains('pipe')) {
      return 'water';
    }
    
    return 'other';
  }

  /// Maps backend status string to ReportStatus enum
  static ReportStatus parseStatus(String? status) {
    if (status == null) return ReportStatus.pending;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return ReportStatus.pending;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      default:
        return ReportStatus.pending;
    }
  }

  /// Maps ReportStatus enum to backend string
  static String statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
    }
  }

  factory CitizenReport.fromMap(Map<String, dynamic> map, String id) {
    return CitizenReport(
      id: id,
      reporterFirebaseUid: map['reporter_firebase_uid']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
      description: map['description']?.toString(),
      photoUrl: map['photo_url']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(map['status']?.toString()),
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporter_firebase_uid': reporterFirebaseUid,
      'category': category,
      'description': description,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Get a user-friendly status display string
  String get statusDisplay {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
    }
  }
}
