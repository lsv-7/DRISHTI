import 'package:drift/drift.dart';

/// Table schema for the durable pending operations queue in DRISHTI AI.
///
/// Stores outbox operations awaiting server synchronization:
/// - Operation type (`CREATE_EMERGENCY`)
/// - Foreign reference to local emergency record (`emergencyLocalId`)
/// - Exact client-generated UUID v4 idempotency key
/// - Self-contained JSON payload holding original vulnerability snapshot and coordinates
/// - Queue status (`PENDING`, `IN_FLIGHT`, `FAILED`, `COMPLETED`)
/// - Transmission attempt metadata and diagnostics
/// - Deterministic FIFO ordering (`createdAt ASC, id ASC`)
@DataClassName('PendingOperationEntry')
class PendingOperations extends Table {
  /// Local autoincrement operation ID
  IntColumn get id => integer().autoIncrement()();

  /// Explicit operation type (e.g. `CREATE_EMERGENCY`)
  TextColumn get operationType => text()();

  /// Associated emergency localId in SQLite Emergencies table, if available
  IntColumn get emergencyLocalId => integer().nullable()();

  /// Unique client-generated UUID v4 idempotency key matching original emergency
  TextColumn get idempotencyKey => text().unique()();

  /// Exact JSON stringified request payload to be replayed verbatim
  TextColumn get payload => text()();

  /// Operation queue state: PENDING, IN_FLIGHT, FAILED, COMPLETED
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  /// Number of transmission attempts
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Timestamp of the latest transmission attempt
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();

  /// Timestamp when operation was enqueued (for deterministic FIFO sorting)
  DateTimeColumn get createdAt => dateTime()();

  /// Diagnostic error message from latest failure
  TextColumn get lastError => text().nullable()();

  /// Timestamp when next retry is permitted (foundation for T058 backoff)
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
}
