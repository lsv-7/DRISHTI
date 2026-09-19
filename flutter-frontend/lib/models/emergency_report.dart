// Emergency Report Model for DRISHTI AI
// 
// Matches FastAPI backend schema:
// `app.schemas.domain.EmergencyCreate` and `EmergencyResponse`
// 
// CONTRACT:
// title: String (non-empty)
// description: String?
// category: String (FLOOD_RESCUE, MEDICAL_EMERGENCY, TRAPPED_CITIZENS, SHELTER_EVACUATION, RELIEF_SUPPLY, OTHER)
// latitude: double (-90.0 to 90.0)
// longitude: double (-180.0 to 180.0)
// affected_count: int (>= 1)
// vulnerability_snapshot: Map<String, dynamic>? (Immutable snapshot from VulnerabilityProfile)
// idempotency_key: String? (UUID v4)

class EmergencyValidationResult {
  final bool isValid;
  final String? primaryError;
  final Map<String, String> fieldErrors;

  const EmergencyValidationResult({
    required this.isValid,
    this.primaryError,
    this.fieldErrors = const {},
  });

  static const valid = EmergencyValidationResult(isValid: true);
}

class EmergencyReport {
  final String? id;
  final String? idempotencyKey;
  final String title;
  final String? description;
  final String category;
  final double latitude;
  final double longitude;
  final int affectedCount;
  final Map<String, dynamic>? vulnerabilitySnapshot;
  final String syncStatus; // PENDING_SYNC, SYNCING, SYNCED
  final DateTime createdAt;
  final double? priorityScore;
  final String? priorityLevel;
  final List<String> priorityReasons;
  final double? vulnerabilityScore;

  const EmergencyReport({
    this.id,
    this.idempotencyKey,
    required this.title,
    this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.affectedCount = 1,
    this.vulnerabilitySnapshot,
    this.syncStatus = 'PENDING_SYNC',
    required this.createdAt,
    this.priorityScore,
    this.priorityLevel,
    this.priorityReasons = const [],
    this.vulnerabilityScore,
  });

  static const List<String> validCategories = [
    'FLOOD_RESCUE',
    'MEDICAL_EMERGENCY',
    'TRAPPED_CITIZENS',
    'SHELTER_EVACUATION',
    'RELIEF_SUPPLY',
    'OTHER',
  ];

  /// Performs comprehensive field-level validation and returns an EmergencyValidationResult
  EmergencyValidationResult validateDetailed() {
    final errors = <String, String>{};

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      errors['title'] = "Emergency title or summary is required.";
    } else if (trimmedTitle.length < 5) {
      errors['title'] = "Emergency title must be at least 5 characters.";
    } else if (trimmedTitle.length > 150) {
      errors['title'] = "Emergency title cannot exceed 150 characters.";
    }

    if (description != null && description!.trim().length > 500) {
      errors['description'] = "Description cannot exceed 500 characters.";
    }

    if (category.trim().isEmpty) {
      errors['category'] = "Emergency category must be selected.";
    } else if (!validCategories.contains(category)) {
      errors['category'] = "Invalid emergency category ($category).";
    }

    if (latitude < -90.0 || latitude > 90.0) {
      errors['latitude'] = "Invalid latitude ($latitude). Must be between -90 and 90.";
    }
    if (longitude < -180.0 || longitude > 180.0) {
      errors['longitude'] = "Invalid longitude ($longitude). Must be between -180 and 180.";
    }
    if (latitude == 0.0 && longitude == 0.0) {
      errors['location'] = "Location cannot be at (0, 0). Valid GPS coordinates required.";
    }

    if (affectedCount < 1) {
      errors['affected_count'] = "Affected count must be at least 1 person.";
    } else if (affectedCount > 1000) {
      errors['affected_count'] = "Affected count cannot exceed 1000 people per incident.";
    }

    if (errors.isNotEmpty) {
      return EmergencyValidationResult(
        isValid: false,
        primaryError: errors.values.first,
        fieldErrors: errors,
      );
    }

    return EmergencyValidationResult.valid;
  }

  /// Validates coordinates and required fields. Returns null if valid, or an error message.
  String? validate() {
    final res = validateDetailed();
    return res.isValid ? null : res.primaryError;
  }

  bool get isValid => validate() == null;

  /// Serializes to JSON payload matching backend EmergencyCreate exactly.
  Map<String, dynamic> toBackendPayload() {
    return {
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'affected_count': affectedCount,
      'vulnerability_snapshot': vulnerabilitySnapshot != null
          ? Map<String, dynamic>.from(vulnerabilitySnapshot!)
          : null,
    };
  }

  /// Serializes to persistent local storage JSON.
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'idempotency_key': idempotencyKey,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'affected_count': affectedCount,
      'vulnerability_snapshot': vulnerabilitySnapshot != null
          ? Map<String, dynamic>.from(vulnerabilitySnapshot!)
          : null,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'priority_score': priorityScore,
      'priority_level': priorityLevel,
      'priority_reasons': priorityReasons,
      'vulnerability_score': vulnerabilityScore,
    };
  }

  factory EmergencyReport.fromJson(Map<String, dynamic> json) {
    final rawReasons = json['priority_reasons'];
    List<String> reasons = [];
    if (rawReasons is List) {
      reasons = rawReasons.map((e) => e.toString()).toList();
    }

    DateTime created;
    if (json['created_at'] != null) {
      try {
        created = DateTime.parse(json['created_at'].toString());
      } catch (_) {
        created = DateTime.now();
      }
    } else {
      created = DateTime.now();
    }

    final rawLat = json['latitude'];
    final double lat = rawLat is num ? rawLat.toDouble() : 0.0;

    final rawLon = json['longitude'];
    final double lon = rawLon is num ? rawLon.toDouble() : 0.0;

    final rawCount = json['affected_count'];
    final int count = rawCount is num ? rawCount.toInt() : 1;

    final rawPriority = json['priority_score'];
    final double? priority = rawPriority is num ? rawPriority.toDouble() : null;

    final rawVuln = json['vulnerability_score'];
    final double? vulnScore = rawVuln is num ? rawVuln.toDouble() : null;

    Map<String, dynamic>? snap;
    if (json['vulnerability_snapshot'] is Map) {
      snap = Map<String, dynamic>.from(json['vulnerability_snapshot'] as Map);
    }

    return EmergencyReport(
      id: json['id'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      title: json['title'] as String? ?? 'Emergency Report',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'FLOOD_RESCUE',
      latitude: lat,
      longitude: lon,
      affectedCount: count,
      vulnerabilitySnapshot: snap,
      syncStatus: json['sync_status'] as String? ?? 'PENDING_SYNC',
      createdAt: created,
      priorityScore: priority,
      priorityLevel: json['priority_level'] as String?,
      priorityReasons: reasons,
      vulnerabilityScore: vulnScore,
    );
  }
}
