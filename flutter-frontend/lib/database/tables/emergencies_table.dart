import 'package:drift/drift.dart';

/// Table schema for local offline-first emergency persistence in DRISHTI AI.
///
/// Matches FastAPI backend schema (`EmergencyCreate` / `EmergencyResponse`)
/// and local Flutter offline models (`EmergencyReport` / `EmergencyTracking`).
///
/// Ensures immutable snapshot preservation: the `vulnerabilitySnapshot`
/// column holds the JSON-serialized citizen vulnerability factors at the time
/// of incident creation and must never be altered by subsequent profile edits.
@DataClassName('EmergencyEntry')
class Emergencies extends Table {
  /// Local SQLite primary key (auto-increment)
  IntColumn get localId => integer().autoIncrement()();

  /// Authoritative backend emergency ID (e.g. `emg_a1b2c3d4`), null when offline created
  TextColumn get id => text().nullable()();

  /// Unique client-generated UUID v4 idempotency key for deduplication and retry safety
  TextColumn get idempotencyKey => text().unique()();

  /// Short summary / title of the emergency (5-150 chars)
  TextColumn get title => text().withLength(min: 5, max: 150)();

  /// Optional detailed incident description (max 500 chars)
  TextColumn get description => text().nullable().withLength(max: 500)();

  /// Incident category (e.g. FLOOD_RESCUE, MEDICAL_EMERGENCY, TRAPPED_CITIZENS)
  TextColumn get category => text()();

  /// GPS or sector fallback latitude (-90 to 90)
  RealColumn get latitude => real()();

  /// GPS or sector fallback longitude (-180 to 180)
  RealColumn get longitude => real()();

  /// Number of individuals affected (>= 1)
  IntColumn get affectedCount => integer().withDefault(const Constant(1))();

  /// Immutable snapshot of citizen vulnerability profile as JSON string at creation time
  TextColumn get vulnerabilitySnapshot => text().nullable()();

  /// Local sync lifecycle state: LOCAL_PENDING, PENDING_SYNC, SYNCING, SYNCED, SYNC_FAILED
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL_PENDING'))();

  /// Emergency lifecycle status: LOCAL_PENDING, PENDING, ASSIGNED, IN_PROGRESS, RESOLVED, CANCELLED
  TextColumn get status => text().withDefault(const Constant('LOCAL_PENDING'))();

  /// Decision engine calculated priority score
  RealColumn get priorityScore => real().nullable()();

  /// Priority classification: LOW, MEDIUM, HIGH, CRITICAL
  TextColumn get priorityLevel => text().nullable()();

  /// JSON-encoded array of decision engine reasoning strings
  TextColumn get priorityReasons => text().nullable()();

  /// Decision engine calculated vulnerability heuristic score
  RealColumn get vulnerabilityScore => real().nullable()();

  /// Timestamp when emergency was initially created on device
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp of latest local or synced update
  DateTimeColumn get updatedAt => dateTime()();

  /// Diagnostic failure reason if sync encountered an error
  TextColumn get lastSyncError => text().nullable()();
}
