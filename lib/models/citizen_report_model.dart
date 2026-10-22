enum ReportStatus { pending, inProgress, resolved }

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
  final String? aiStatus;
  final String? aiCategory;
  final String? aiUrgency;
  final String? aiSummary;
  final String? aiLanguage;
  final double? aiConfidence;
  final String? finalCategory;
  final String? finalUrgency;

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
    this.aiStatus,
    this.aiCategory,
    this.aiUrgency,
    this.aiSummary,
    this.aiLanguage,
    this.aiConfidence,
    this.finalCategory,
    this.finalUrgency,
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

  static const List<String> categories = [
    'pothole',
    'garbage',
    'street_light',
    'water',
    'other',
  ];

  static String categoryLabel(String? value) {
    switch (value) {
      case 'pothole':
        return 'Road damage';
      case 'garbage':
        return 'Waste';
      case 'street_light':
        return 'Street light';
      case 'water':
        return 'Water';
      default:
        return 'Other';
    }
  }

  static String urgencyLabel(String? value) {
    switch (value) {
      case 'high':
        return 'High urgency';
      case 'medium':
        return 'Medium urgency';
      case 'low':
        return 'Low urgency';
      default:
        return 'Not triaged';
    }
  }

  static String languageLabel(String? value) {
    switch (value) {
      case 'am':
        return 'Amharic';
      case 'en':
        return 'English';
      case 'sid':
        return 'Sidaamu Afoo';
      default:
        return 'Other language';
    }
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
      aiStatus: map['ai_status']?.toString(),
      aiCategory: map['ai_category']?.toString(),
      aiUrgency: map['ai_urgency']?.toString(),
      aiSummary: map['ai_summary']?.toString(),
      aiLanguage: map['ai_language']?.toString(),
      aiConfidence: (map['ai_confidence'] as num?)?.toDouble(),
      finalCategory: map['final_category']?.toString(),
      finalUrgency: map['final_urgency']?.toString(),
    );
  }

  String get effectiveCategory => finalCategory ?? aiCategory ?? category;

  String? get effectiveUrgency => finalUrgency ?? aiUrgency;

  bool get hasAiSummary => aiSummary != null && aiSummary!.trim().isNotEmpty;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
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
