import 'package:flutter/material.dart';

/// Strongly typed emergency tracking model matching FastAPI backend schema
/// pp.schemas.domain.EmergencyResponse and local offline queue items.
class EmergencyTracking {
  final String id;
  final String? userId;
  final String? zoneId;
  final String title;
  final String? description;
  final String category;
  final double latitude;
  final double longitude;
  final String status; // PENDING, ASSIGNED, IN_PROGRESS, RESOLVED, CANCELLED, LOCAL_PENDING
  final double? priorityScore;
  final String? priorityLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final List<String> priorityReasons;
  final double? vulnerabilityScore;
  final Map<String, dynamic>? vulnerabilityFactors;
  final int affectedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // SYNCED, PENDING_SYNC, LOCAL_PENDING
  final String? locationLabel;
  final bool hasVulnerabilitySnapshot;

  const EmergencyTracking({
    required this.id,
    this.userId,
    this.zoneId,
    required this.title,
    this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.priorityScore,
    this.priorityLevel,
    this.priorityReasons = const [],
    this.vulnerabilityScore,
    this.vulnerabilityFactors,
    this.affectedCount = 1,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'SYNCED',
    this.locationLabel,
    this.hasVulnerabilitySnapshot = true,
  });

  bool get isLocalPending =>
      status == 'LOCAL_PENDING' || syncStatus == 'PENDING_SYNC';

  /// Human-friendly display label for current emergency status
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'LOCAL_PENDING':
        return 'SAVED LOCALLY (OFFLINE)';
      case 'PENDING':
        return 'REPORT RECEIVED — PENDING DISPATCH';
      case 'ASSIGNED':
        return 'RESCUE RESOURCE ASSIGNED';
      case 'IN_PROGRESS':
        return 'RESCUE IN PROGRESS';
      case 'RESOLVED':
        return 'RESOLVED';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return status;
    }
  }

  /// Informative, honest status explanation without fabricating ETAs or arrivals
  String get statusDescription {
    switch (status.toUpperCase()) {
      case 'LOCAL_PENDING':
        return 'Stored in device offline queue. Will synchronize automatically when network or radio connectivity is available.';
      case 'PENDING':
        return 'Received by Command Center. Evaluating vulnerability-adjusted priority and dispatch queue.';
      case 'ASSIGNED':
        return 'Emergency response team and resources have been allocated by the Decision Engine.';
      case 'IN_PROGRESS':
        return 'Active rescue and evacuation operations are currently underway at this location.';
      case 'RESOLVED':
        return 'This incident has been marked as resolved by emergency field coordinators.';
      case 'CANCELLED':
        return 'This emergency report was withdrawn or cancelled.';
      default:
        return 'Emergency status updated by Command Center.';
    }
  }

  /// Visual theme color for status badge and progression
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'LOCAL_PENDING':
        return const Color(0xFFF59E0B); // Amber
      case 'PENDING':
        return const Color(0xFF3B82F6); // Blue
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6); // Purple
      case 'IN_PROGRESS':
        return const Color(0xFF06B6D4); // Cyan
      case 'RESOLVED':
        return const Color(0xFF10B981); // Emerald
      case 'CANCELLED':
        return const Color(0xFF64748B); // Slate
      default:
        return const Color(0xFF94A3B8);
    }
  }

  /// Associated status icon
  IconData get statusIcon {
    switch (status.toUpperCase()) {
      case 'LOCAL_PENDING':
        return Icons.pending_actions_rounded;
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      case 'ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'IN_PROGRESS':
        return Icons.navigation_rounded;
      case 'RESOLVED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  /// Step index for timeline (0: Created/Local, 1: Received/Pending, 2: Assigned, 3: In Progress, 4: Resolved)
  int get timelineStep {
    switch (status.toUpperCase()) {
      case 'LOCAL_PENDING':
        return 0;
      case 'PENDING':
        return 1;
      case 'ASSIGNED':
        return 2;
      case 'IN_PROGRESS':
        return 3;
      case 'RESOLVED':
        return 4;
      default:
        return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'zone_id': zoneId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'priority_score': priorityScore,
      'priority_level': priorityLevel,
      'priority_reasons': priorityReasons,
      'vulnerability_score': vulnerabilityScore,
      'vulnerability_factors': vulnerabilityFactors,
      'affected_count': affectedCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'location_label': locationLabel,
      'has_vulnerability_snapshot': hasVulnerabilitySnapshot,
    };
  }

  factory EmergencyTracking.fromJson(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      created = DateTime.now();
    }

    DateTime updated;
    try {
      updated = json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : created;
    } catch (_) {
      updated = created;
    }

    List<String> reasons = [];
    final rawReasons = json['priority_reasons'];
    if (rawReasons is List) {
      reasons = rawReasons.map((e) => e.toString()).toList();
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

    Map<String, dynamic>? vulnFactors;
    if (json['vulnerability_factors'] is Map) {
      vulnFactors = Map<String, dynamic>.from(json['vulnerability_factors'] as Map);
    }

    final hasSnap = json['vulnerability_snapshot'] != null ||
        json['has_vulnerability_snapshot'] == true;

    return EmergencyTracking(
      id: json['id'] as String? ?? json['idempotency_key'] as String? ?? 'DR-LOCAL',
      userId: json['user_id'] as String?,
      zoneId: json['zone_id'] as String?,
      title: json['title'] as String? ?? 'Emergency Incident',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'FLOOD_RESCUE',
      latitude: lat,
      longitude: lon,
      status: json['status'] as String? ?? 'PENDING',
      priorityScore: priority,
      priorityLevel: json['priority_level'] as String?,
      priorityReasons: reasons,
      vulnerabilityScore: vulnScore,
      vulnerabilityFactors: vulnFactors,
      affectedCount: count,
      createdAt: created,
      updatedAt: updated,
      syncStatus: json['sync_status'] as String? ?? 'SYNCED',
      locationLabel: json['location_label'] as String?,
      hasVulnerabilitySnapshot: hasSnap,
    );
  }

  /// Constructs an EmergencyTracking instance from a locally stored offline queue item
  factory EmergencyTracking.fromLocalEmergency(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = DateTime.parse(json['created_at'].toString());
    } catch (_) {
      created = DateTime.now();
    }

    final rawLat = json['latitude'];
    final double lat = rawLat is num ? rawLat.toDouble() : 0.0;

    final rawLon = json['longitude'];
    final double lon = rawLon is num ? rawLon.toDouble() : 0.0;

    final rawCount = json['affected_count'];
    final int count = rawCount is num ? rawCount.toInt() : 1;

    final id = json['id'] as String? ?? json['idempotency_key'] as String? ?? 'DR-LOCAL';

    return EmergencyTracking(
      id: id,
      userId: json['user_id'] as String?,
      zoneId: json['zone_id'] as String?,
      title: json['title'] as String? ?? 'Emergency Incident',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'FLOOD_RESCUE',
      latitude: lat,
      longitude: lon,
      status: 'LOCAL_PENDING',
      priorityScore: null,
      priorityLevel: null,
      priorityReasons: const [],
      vulnerabilityScore: null,
      vulnerabilityFactors: null,
      affectedCount: count,
      createdAt: created,
      updatedAt: created,
      syncStatus: 'PENDING_SYNC',
      locationLabel: json['location_label'] as String?,
      hasVulnerabilitySnapshot: json['vulnerability_snapshot'] != null,
    );
  }
}
