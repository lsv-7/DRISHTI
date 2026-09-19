import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service responsible for managing the durable FIFO queue of pending outbox operations.
///
/// Ensures offline operations (e.g. emergency submissions) survive application restarts,
/// maintain strict FIFO sequence, and preserve exact original idempotency keys,
/// vulnerability snapshots, and location coordinates.
class PendingOperationQueue {
  final AppDatabase database;

  PendingOperationQueue(this.database);

  // ===========================================================================
  // ENQUEUE & RETRIEVAL
  // ===========================================================================

  /// Enqueues a pending operation into the durable SQLite queue.
  ///
  /// Enforces idempotency: if an operation with the same idempotencyKey is already queued,
  /// returns the existing entry without creating duplicates.
  Future<PendingOperationEntry> enqueue({
    required String operationType,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
    int? emergencyLocalId,
  }) async {
    // 1. Idempotency check: look for existing operation with this idempotency key
    final existing = await getOperationByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      return existing;
    }

    final payloadStr = jsonEncode(payload);
    final now = DateTime.now().toUtc();

    final companion = PendingOperationsCompanion.insert(
      operationType: operationType,
      idempotencyKey: idempotencyKey,
      payload: payloadStr,
      emergencyLocalId: emergencyLocalId != null
          ? Value(emergencyLocalId)
          : const Value.absent(),
      status: const Value('PENDING'),
      attemptCount: const Value(0),
      createdAt: now,
    );

    try {
      final id =
          await database.into(database.pendingOperations).insert(companion);
      return (await getOperationById(id))!;
    } catch (_) {
      // If a concurrent insert occurred with identical idempotencyKey
      final raceExisting = await getOperationByIdempotencyKey(idempotencyKey);
      if (raceExisting != null) {
        return raceExisting;
      }
      rethrow;
    }
  }

  /// Returns the oldest active pending operation in deterministic FIFO order (createdAt ASC, id ASC).
  Future<PendingOperationEntry?> peekOldestPending() {
    return (database.select(database.pendingOperations)
          ..where((tbl) => tbl.status.equals('PENDING'))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdAt),
            (tbl) => OrderingTerm.asc(tbl.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Retrieves an operation by its local auto-increment ID.
  Future<PendingOperationEntry?> getOperationById(int id) {
    return (database.select(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Retrieves an operation by its unique UUID v4 idempotency key.
  Future<PendingOperationEntry?> getOperationByIdempotencyKey(
      String idempotencyKey) {
    return (database.select(database.pendingOperations)
          ..where((tbl) => tbl.idempotencyKey.equals(idempotencyKey)))
        .getSingleOrNull();
  }

  /// Retrieves all pending operations in deterministic FIFO order.
  Future<List<PendingOperationEntry>> getPendingOperations() {
    return (database.select(database.pendingOperations)
          ..where((tbl) => tbl.status.equals('PENDING'))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdAt),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
  }

  /// Retrieves all operations in the queue table (regardless of status).
  Future<List<PendingOperationEntry>> getAllOperations() {
    return (database.select(database.pendingOperations)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdAt),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();
  }

  /// Returns the current count of pending operations awaiting sync.
  Future<int> getPendingCount() async {
    final countExp = database.pendingOperations.id.count();
    final query = database.selectOnly(database.pendingOperations)
      ..where(database.pendingOperations.status.equals('PENDING'))
      ..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ===========================================================================
  // STATUS TRANSITIONS & METADATA
  // ===========================================================================

  /// Marks an operation as currently being transmitted.
  Future<void> markInFlight(int id) async {
    final op = await getOperationById(id);
    if (op == null) return;

    await (database.update(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      PendingOperationsCompanion(
        status: const Value('IN_FLIGHT'),
        attemptCount: Value(op.attemptCount + 1),
        lastAttemptedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Marks an operation as successfully synchronized.
  Future<void> markCompleted(int id) async {
    await (database.update(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      const PendingOperationsCompanion(
        status: Value('COMPLETED'),
      ),
    );
  }

  /// Marks an operation as failed with an error message and optional retry timestamp.
  Future<void> markFailed(int id, String error, {DateTime? nextRetryAt}) async {
    await (database.update(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      PendingOperationsCompanion(
        status: const Value('FAILED'),
        lastError: Value(error),
        nextRetryAt:
            nextRetryAt != null ? Value(nextRetryAt) : const Value.absent(),
      ),
    );
  }

  /// Resets a failed or in-flight operation back to PENDING for retry.
  Future<void> resetToPending(int id) async {
    await (database.update(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      const PendingOperationsCompanion(
        status: Value('PENDING'),
      ),
    );
  }

  // ===========================================================================
  // DELETION & RESET
  // ===========================================================================

  /// Deletes an operation from the queue.
  Future<int> deleteOperation(int id) {
    return (database.delete(database.pendingOperations)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Clears all operations from the queue table.
  Future<int> clearQueue() {
    return database.delete(database.pendingOperations).go();
  }

  // ===========================================================================
  // REACTIVE STREAM
  // ===========================================================================

  /// Watches all pending operations reactively.
  Stream<List<PendingOperationEntry>> watchPendingOperations() {
    return (database.select(database.pendingOperations)
          ..where((tbl) => tbl.status.equals('PENDING'))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.createdAt),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .watch();
  }
}
