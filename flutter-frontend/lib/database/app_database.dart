import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/emergencies_table.dart';

part 'app_database.g.dart';

/// Central SQLite database for DRISHTI AI mobile application powered by Drift.
///
/// Supports offline-first emergency caching, sync queues, and immutable snapshot
/// preservation. Can be instantiated with an in-memory executor for hermetic tests.
@DriftDatabase(tables: [Emergencies])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection()) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future schema migrations will be handled here incrementally
        },
      );

  // ===========================================================================
  // Typed Query & Mutation Methods
  // ===========================================================================

  /// Inserts a new emergency record into SQLite and returns the generated localId.
  Future<int> insertEmergency(EmergenciesCompanion entry) {
    return into(emergencies).insert(entry);
  }

  /// Finds an emergency record by its device-local primary key ID.
  Future<EmergencyEntry?> getEmergencyByLocalId(int localId) {
    return (select(emergencies)..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Finds an emergency record by its unique UUID v4 idempotency key.
  Future<EmergencyEntry?> getEmergencyByIdempotencyKey(String idempotencyKey) {
    return (select(emergencies)
          ..where((tbl) => tbl.idempotencyKey.equals(idempotencyKey)))
        .getSingleOrNull();
  }

  /// Finds an emergency record by its server-assigned ID (e.g. `emg_...`).
  Future<EmergencyEntry?> getEmergencyByServerId(String serverId) {
    return (select(emergencies)..where((tbl) => tbl.id.equals(serverId)))
        .getSingleOrNull();
  }

  /// Retrieves all local emergency records ordered chronologically (newest first).
  Future<List<EmergencyEntry>> getAllEmergencies() {
    return (select(emergencies)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Reactive stream of all emergency records ordered chronologically.
  Stream<List<EmergencyEntry>> watchAllEmergencies() {
    return (select(emergencies)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Replaces an entire emergency entry by localId.
  Future<bool> updateEmergency(EmergenciesCompanion entry) {
    return update(emergencies).replace(entry);
  }

  /// Granularly updates status, sync state, and priority without mutating immutable snapshot.
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
    DateTime? updatedAt,
  }) {
    return (update(emergencies)..where((tbl) => tbl.localId.equals(localId)))
        .write(
      EmergenciesCompanion(
        status: Value(status),
        syncStatus: Value(syncStatus),
        id: serverId != null ? Value(serverId) : const Value.absent(),
        priorityScore:
            priorityScore != null ? Value(priorityScore) : const Value.absent(),
        priorityLevel:
            priorityLevel != null ? Value(priorityLevel) : const Value.absent(),
        priorityReasons: priorityReasons != null
            ? Value(jsonEncode(priorityReasons))
            : const Value.absent(),
        vulnerabilityScore: vulnerabilityScore != null
            ? Value(vulnerabilityScore)
            : const Value.absent(),
        lastSyncError: lastSyncError != null
            ? Value(lastSyncError)
            : const Value.absent(),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  /// Deletes a specific emergency by its local ID.
  Future<int> deleteEmergency(int localId) {
    return (delete(emergencies)..where((tbl) => tbl.localId.equals(localId)))
        .go();
  }

  /// Clears all emergency records from SQLite (primarily for testing and reset flows).
  Future<int> clearAllEmergencies() {
    return delete(emergencies).go();
  }
}

/// Default lazy connection to persistent device SQLite file with test fallback.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // In headless unit/widget tests without platform channels, immediately use in-memory SQLite
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return NativeDatabase.memory();
    }
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'drishti.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      return NativeDatabase.memory();
    }
  });
}
