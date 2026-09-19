import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/emergency_report.dart';
import '../models/emergency_tracking.dart';
import '../services/pending_operation_queue.dart';

/// Repository interface for device-local emergency persistence.
///
/// Serves as the single boundary between the application/service layer
/// and the SQLite database (Drift / AppDatabase).
///
/// Implements:
/// - Idempotent emergency persistence (respecting unique idempotencyKey)
/// - Vulnerability snapshot immutability (T043 requirement preserved)
/// - Domain-to-Database entity mapping (EmergencyReport / EmergencyTracking <-> EmergencyEntry)
/// - Reactive stream observation for UI bindings
class LocalEmergencyRepository {
  final AppDatabase database;

  LocalEmergencyRepository([AppDatabase? db])
      : database = db ?? AppDatabase();

  /// Creates a repository backed by an in-memory SQLite database for testing.
  factory LocalEmergencyRepository.inMemory() {
    return LocalEmergencyRepository(AppDatabase(NativeDatabase.memory()));
  }

  // ===========================================================================
  // CREATE / SAVE OPERATIONS
  // ===========================================================================

  /// Saves an emergency report to SQLite.
  ///
  /// Enforces idempotency: if a record with the same idempotencyKey already
  /// exists, returns the existing record without duplicating or throwing.
  ///
  /// Enforces vulnerability snapshot immutability: the snapshot map on the
  /// report is serialized directly into SQLite and never altered by later profile edits.
  Future<EmergencyEntry> saveEmergency(EmergencyReport report) async {
    final key = report.idempotencyKey ?? const Uuid().v4();

    // Check for existing record by idempotency key first
    final existing = await getEmergencyByIdempotencyKey(key);
    if (existing != null) {
      return existing;
    }

    final snapJson = report.vulnerabilitySnapshot != null
        ? jsonEncode(report.vulnerabilitySnapshot)
        : null;

    final companion = EmergenciesCompanion.insert(
      idempotencyKey: key,
      title: report.title,
      category: report.category,
      latitude: report.latitude,
      longitude: report.longitude,
      createdAt: report.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
      id: report.id != null ? Value(report.id) : const Value.absent(),
      description: report.description != null
          ? Value(report.description)
          : const Value.absent(),
      affectedCount: Value(report.affectedCount),
      vulnerabilitySnapshot:
          snapJson != null ? Value(snapJson) : const Value.absent(),
      syncStatus: Value(report.syncStatus),
      status: Value(report.syncStatus == 'SYNCED' ? 'PENDING' : 'LOCAL_PENDING'),
      priorityScore: report.priorityScore != null
          ? Value(report.priorityScore)
          : const Value.absent(),
      priorityLevel: report.priorityLevel != null
          ? Value(report.priorityLevel)
          : const Value.absent(),
      priorityReasons: report.priorityReasons.isNotEmpty
          ? Value(jsonEncode(report.priorityReasons))
          : const Value.absent(),
      vulnerabilityScore: report.vulnerabilityScore != null
          ? Value(report.vulnerabilityScore)
          : const Value.absent(),
    );

    try {
      final localId = await database.insertEmergency(companion);
      final inserted = await database.getEmergencyByLocalId(localId);
      return inserted!;
    } catch (_) {
      // If a concurrent insert occurred with identical idempotencyKey, return it
      final raceExisting = await getEmergencyByIdempotencyKey(key);
      if (raceExisting != null) {
        return raceExisting;
      }
      rethrow;
    }
  }

  /// Saves or upserts an emergency from a generic JSON map payload.
  Future<EmergencyEntry> saveEmergencyMap(Map<String, dynamic> data) async {
    final key = data['idempotency_key'] as String? ?? const Uuid().v4();

    final existing = await getEmergencyByIdempotencyKey(key);
    if (existing != null) {
      // If existing record found and new data has server-assigned fields or sync updates, update it
      if (data['id'] != null || data['sync_status'] != null || data['status'] != null) {
        await updateEmergencyStatus(
          localId: existing.localId,
          status: data['status'] as String? ?? existing.status,
          syncStatus: data['sync_status'] as String? ?? existing.syncStatus,
          serverId: data['id'] as String? ?? existing.id,
          priorityScore: (data['priority_score'] as num?)?.toDouble() ?? existing.priorityScore,
          priorityLevel: data['priority_level'] as String? ?? existing.priorityLevel,
          priorityReasons: data['priority_reasons'] is List
              ? (data['priority_reasons'] as List).map((e) => e.toString()).toList()
              : null,
          vulnerabilityScore: (data['vulnerability_score'] as num?)?.toDouble() ?? existing.vulnerabilityScore,
          lastSyncError: data['last_sync_error'] as String? ?? existing.lastSyncError,
        );
        return (await getEmergencyByLocalId(existing.localId))!;
      }
      return existing;
    }

    String? snapJson;
    final rawSnap = data['vulnerability_snapshot'];
    if (rawSnap is Map) {
      snapJson = jsonEncode(rawSnap);
    } else if (rawSnap is String) {
      snapJson = rawSnap;
    }

    DateTime created;
    if (data['created_at'] != null) {
      try {
        created = DateTime.parse(data['created_at'].toString()).toUtc();
      } catch (_) {
        created = DateTime.now().toUtc();
      }
    } else {
      created = DateTime.now().toUtc();
    }

    final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lon = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final int count = (data['affected_count'] as num?)?.toInt() ?? 1;

    final companion = EmergenciesCompanion.insert(
      idempotencyKey: key,
      title: data['title'] as String? ?? 'Emergency Incident',
      category: data['category'] as String? ?? 'FLOOD_RESCUE',
      latitude: lat,
      longitude: lon,
      createdAt: created,
      updatedAt: DateTime.now().toUtc(),
      id: data['id'] != null ? Value(data['id'] as String) : const Value.absent(),
      description: data['description'] != null
          ? Value(data['description'] as String)
          : const Value.absent(),
      affectedCount: Value(count),
      vulnerabilitySnapshot:
          snapJson != null ? Value(snapJson) : const Value.absent(),
      syncStatus: Value(data['sync_status'] as String? ?? 'LOCAL_PENDING'),
      status: Value(data['status'] as String? ?? 'LOCAL_PENDING'),
      priorityScore: data['priority_score'] != null
          ? Value((data['priority_score'] as num).toDouble())
          : const Value.absent(),
      priorityLevel: data['priority_level'] != null
          ? Value(data['priority_level'] as String)
          : const Value.absent(),
      priorityReasons: data['priority_reasons'] != null
          ? Value(jsonEncode(data['priority_reasons']))
          : const Value.absent(),
      vulnerabilityScore: data['vulnerability_score'] != null
          ? Value((data['vulnerability_score'] as num).toDouble())
          : const Value.absent(),
      lastSyncError: data['last_sync_error'] != null
          ? Value(data['last_sync_error'] as String)
          : const Value.absent(),
    );

    final localId = await database.insertEmergency(companion);
    final inserted = await database.getEmergencyByLocalId(localId);
    return inserted!;
  }

  /// Atomically persists an emergency and enqueues its pending transmission operation
  /// within a single SQLite transaction.
  Future<EmergencyEntry> saveAndEnqueueEmergency({
    required Map<String, dynamic> payload,
    required PendingOperationQueue queue,
    String operationType = 'CREATE_EMERGENCY',
  }) async {
    return database.transaction(() async {
      final entry = await saveEmergencyMap(payload);
      await queue.enqueue(
        operationType: operationType,
        idempotencyKey: entry.idempotencyKey,
        payload: payload,
        emergencyLocalId: entry.localId,
      );
      return entry;
    });
  }

  // ===========================================================================
  // READ OPERATIONS
  // ===========================================================================

  /// Retrieves an emergency by its device local SQLite primary key.
  Future<EmergencyEntry?> getEmergencyByLocalId(int localId) {
    return database.getEmergencyByLocalId(localId);
  }

  /// Retrieves an emergency by its unique UUID v4 idempotency key.
  Future<EmergencyEntry?> getEmergencyByIdempotencyKey(String idempotencyKey) {
    return database.getEmergencyByIdempotencyKey(idempotencyKey);
  }

  /// Retrieves an emergency by its authoritative backend ID.
  Future<EmergencyEntry?> getEmergencyByServerId(String serverId) {
    return database.getEmergencyByServerId(serverId);
  }

  /// Polymorphic query: attempts to find an emergency by server ID, idempotency key,
  /// or numeric local ID.
  Future<EmergencyEntry?> getEmergencyById(String identifier) async {
    // 1. Try server ID lookup
    var record = await database.getEmergencyByServerId(identifier);
    if (record != null) return record;

    // 2. Try idempotency key lookup
    record = await database.getEmergencyByIdempotencyKey(identifier);
    if (record != null) return record;

    // 3. Try local integer ID lookup if applicable
    final parsed = int.tryParse(identifier);
    if (parsed != null) {
      record = await database.getEmergencyByLocalId(parsed);
      if (record != null) return record;
    }

    return null;
  }

  /// Retrieves all emergencies ordered newest first.
  Future<List<EmergencyEntry>> getAllEmergencies() {
    return database.getAllEmergencies();
  }

  // ===========================================================================
  // REACTIVE STREAM OPERATIONS
  // ===========================================================================

  /// Stream of all emergencies ordered newest first for reactive UI bindings.
  Stream<List<EmergencyEntry>> watchAllEmergencies() {
    return database.watchAllEmergencies();
  }

  // ===========================================================================
  // UPDATE OPERATIONS
  // ===========================================================================

  /// Updates an entire emergency entry.
  Future<bool> updateEmergency(EmergenciesCompanion entry) {
    return database.updateEmergency(entry);
  }

  /// Granularly updates status, sync state, and priority without mutating the snapshot.
  Future<int> updateEmergencyStatus({
    required int localId,
    required String status,
    required String syncStatus,
    String? serverId,
    double? priorityScore,
    String? priorityLevel,
    List<String>? priorityReasons,
    double? vulnerabilityScore,
    String? lastSyncError,
    bool clearSyncError = false,
    DateTime? updatedAt,
  }) {
    return database.updateEmergencyStatus(
      localId: localId,
      status: status,
      syncStatus: syncStatus,
      serverId: serverId,
      priorityScore: priorityScore,
      priorityLevel: priorityLevel,
      priorityReasons: priorityReasons,
      vulnerabilityScore: vulnerabilityScore,
      lastSyncError: lastSyncError,
      clearSyncError: clearSyncError,
      updatedAt: updatedAt,
    );
  }

  // ===========================================================================
  // DELETE & RESET OPERATIONS
  // ===========================================================================

  /// Deletes an emergency record by local ID.
  Future<int> deleteEmergency(int localId) {
    return database.deleteEmergency(localId);
  }

  /// Clears all emergency records from SQLite.
  Future<int> clearAllEmergencies() {
    return database.clearAllEmergencies();
  }
}

// =============================================================================
// DOMAIN <-> DATABASE MAPPING EXTENSIONS
// =============================================================================

extension EmergencyEntryMapping on EmergencyEntry {
  /// Maps a database row (`EmergencyEntry`) to domain `EmergencyReport`.
  EmergencyReport toReport() {
    Map<String, dynamic>? snap;
    if (vulnerabilitySnapshot != null) {
      try {
        snap = jsonDecode(vulnerabilitySnapshot!) as Map<String, dynamic>;
      } catch (_) {}
    }

    List<String> reasons = [];
    if (priorityReasons != null) {
      try {
        final decoded = jsonDecode(priorityReasons!);
        if (decoded is List) {
          reasons = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return EmergencyReport(
      id: id,
      idempotencyKey: idempotencyKey,
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      affectedCount: affectedCount,
      vulnerabilitySnapshot: snap,
      syncStatus: syncStatus,
      createdAt: createdAt,
      priorityScore: priorityScore,
      priorityLevel: priorityLevel,
      priorityReasons: reasons,
      vulnerabilityScore: vulnerabilityScore,
    );
  }

  /// Maps a database row (`EmergencyEntry`) to domain `EmergencyTracking`.
  EmergencyTracking toTracking() {
    List<String> reasons = [];
    if (priorityReasons != null) {
      try {
        final decoded = jsonDecode(priorityReasons!);
        if (decoded is List) {
          reasons = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    Map<String, dynamic>? vulnFactors;
    if (vulnerabilitySnapshot != null) {
      try {
        vulnFactors = jsonDecode(vulnerabilitySnapshot!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return EmergencyTracking(
      id: id ?? idempotencyKey,
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      status: status,
      priorityScore: priorityScore,
      priorityLevel: priorityLevel,
      priorityReasons: reasons,
      vulnerabilityScore: vulnerabilityScore,
      vulnerabilityFactors: vulnFactors,
      affectedCount: affectedCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      hasVulnerabilitySnapshot: vulnerabilitySnapshot != null,
    );
  }
}
