import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../repositories/local_emergency_repository.dart';
import 'pending_operation_queue.dart';

/// Structured outcome classifications for emergency synchronization operations.
enum SyncStatus {
  /// Authoritative synchronization succeeded and local SQLite record was reconciled.
  success,

  /// Server recognized identical idempotency key and returned existing authoritative record.
  duplicateAlreadySynced,

  /// Client validation error (HTTP 400/422). Non-retryable without payload correction.
  validationFailure,

  /// Server-side temporary error (HTTP 5xx). Retryable.
  transientFailure,

  /// Network timeout, socket disconnect, or transport error. Retryable.
  networkFailure,

  /// Other permanent HTTP failures (e.g. 403, 404). Non-retryable.
  permanentFailure,
}

/// Strongly typed result returned by [SyncService] for an emergency synchronization attempt.
class SyncResult {
  final SyncStatus status;
  final int? operationId;
  final int? emergencyLocalId;
  final String? idempotencyKey;
  final String? serverEmergencyId;
  final int? httpStatusCode;
  final String? errorMessage;
  final bool isRetryable;
  final Map<String, dynamic>? authoritativeData;

  const SyncResult({
    required this.status,
    this.operationId,
    this.emergencyLocalId,
    this.idempotencyKey,
    this.serverEmergencyId,
    this.httpStatusCode,
    this.errorMessage,
    required this.isRetryable,
    this.authoritativeData,
  });

  bool get isSuccess =>
      status == SyncStatus.success ||
      status == SyncStatus.duplicateAlreadySynced;

  factory SyncResult.success({
    required int operationId,
    int? emergencyLocalId,
    required String idempotencyKey,
    required String serverEmergencyId,
    int httpStatusCode = 200,
    required Map<String, dynamic> authoritativeData,
    bool isDuplicate = false,
  }) {
    return SyncResult(
      status: isDuplicate
          ? SyncStatus.duplicateAlreadySynced
          : SyncStatus.success,
      operationId: operationId,
      emergencyLocalId: emergencyLocalId,
      idempotencyKey: idempotencyKey,
      serverEmergencyId: serverEmergencyId,
      httpStatusCode: httpStatusCode,
      isRetryable: false,
      authoritativeData: authoritativeData,
    );
  }

  factory SyncResult.validationFailure({
    required int operationId,
    int? emergencyLocalId,
    required String idempotencyKey,
    required int httpStatusCode,
    required String errorMessage,
  }) {
    return SyncResult(
      status: SyncStatus.validationFailure,
      operationId: operationId,
      emergencyLocalId: emergencyLocalId,
      idempotencyKey: idempotencyKey,
      httpStatusCode: httpStatusCode,
      errorMessage: errorMessage,
      isRetryable: false,
    );
  }

  factory SyncResult.transientFailure({
    required int operationId,
    int? emergencyLocalId,
    required String idempotencyKey,
    required int httpStatusCode,
    required String errorMessage,
  }) {
    return SyncResult(
      status: SyncStatus.transientFailure,
      operationId: operationId,
      emergencyLocalId: emergencyLocalId,
      idempotencyKey: idempotencyKey,
      httpStatusCode: httpStatusCode,
      errorMessage: errorMessage,
      isRetryable: true,
    );
  }

  factory SyncResult.networkFailure({
    required int operationId,
    int? emergencyLocalId,
    required String idempotencyKey,
    required String errorMessage,
  }) {
    return SyncResult(
      status: SyncStatus.networkFailure,
      operationId: operationId,
      emergencyLocalId: emergencyLocalId,
      idempotencyKey: idempotencyKey,
      errorMessage: errorMessage,
      isRetryable: true,
    );
  }

  factory SyncResult.permanentFailure({
    required int operationId,
    int? emergencyLocalId,
    required String idempotencyKey,
    required int httpStatusCode,
    required String errorMessage,
  }) {
    return SyncResult(
      status: SyncStatus.permanentFailure,
      operationId: operationId,
      emergencyLocalId: emergencyLocalId,
      idempotencyKey: idempotencyKey,
      httpStatusCode: httpStatusCode,
      errorMessage: errorMessage,
      isRetryable: false,
    );
  }
}

/// Service dedicated to transmitting queued emergency operations to the backend API.
///
/// Features:
/// - Enforces exact idempotency key preservation across retries and restarts
/// - Reconciles SQLite emergency records with authoritative backend priority and status
/// - Classifies errors into retryable (5xx, timeout, socket) vs non-retryable (400, 422)
/// - Guarantees vulnerability snapshot immutability
/// - Preserves strict FIFO queue ordering
class SyncService {
  final LocalEmergencyRepository repository;
  final PendingOperationQueue queue;
  final String apiBase;
  final Duration timeout;

  SyncService({
    required this.repository,
    required this.queue,
    this.apiBase = 'http://localhost:3000/api/v1',
    this.timeout = const Duration(seconds: 5),
  });

  /// Synchronizes a specific pending operation against the backend API.
  Future<SyncResult> syncOperation(
    PendingOperationEntry operation, {
    http.Client? client,
  }) async {
    // 1. Mark operation IN_FLIGHT in queue to prevent duplicate processing
    await queue.markInFlight(operation.id);

    // 2. Parse stored JSON payload
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(operation.payload) as Map<String, dynamic>;
    } catch (e) {
      final err = 'Corrupted payload: $e';
      await queue.markFailed(operation.id, err);
      return SyncResult.validationFailure(
        operationId: operation.id,
        emergencyLocalId: operation.emergencyLocalId,
        idempotencyKey: operation.idempotencyKey,
        httpStatusCode: 400,
        errorMessage: err,
      );
    }

    // 3. Prepare HTTP request matching backend EmergencyCreate schema
    final httpClient = client ?? http.Client();
    try {
      final requestBody = Map<String, dynamic>.from(payload);
      // Ensure exact original idempotency key is preserved
      requestBody['idempotency_key'] = operation.idempotencyKey;

      // Clean local-only fields so payload strictly matches FastAPI EmergencyCreate
      requestBody.remove('status');
      requestBody.remove('sync_status');
      requestBody.remove('last_sync_error');
      requestBody.remove('id');

      final url = Uri.parse('$apiBase/emergencies');
      final response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      final statusCode = response.statusCode;

      if (statusCode == 200 || statusCode == 201) {
        final responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        final serverId = responseData['id'] as String? ?? 'unknown';

        // Reconcile local emergency record atomically with authoritative server data
        await _reconcileSuccess(
          operation: operation,
          responseData: responseData,
        );

        // Mark queue operation completed
        await queue.markCompleted(operation.id);

        return SyncResult.success(
          operationId: operation.id,
          emergencyLocalId: operation.emergencyLocalId,
          idempotencyKey: operation.idempotencyKey,
          serverEmergencyId: serverId,
          httpStatusCode: statusCode,
          authoritativeData: responseData,
          isDuplicate: statusCode == 200,
        );
      } else if (statusCode == 400 || statusCode == 422) {
        final errorMsg =
            'Client validation error ($statusCode): ${response.body}';
        await queue.markFailed(operation.id, errorMsg);
        await _recordEmergencySyncError(operation, errorMsg);

        return SyncResult.validationFailure(
          operationId: operation.id,
          emergencyLocalId: operation.emergencyLocalId,
          idempotencyKey: operation.idempotencyKey,
          httpStatusCode: statusCode,
          errorMessage: errorMsg,
        );
      } else if (statusCode >= 500 && statusCode < 600) {
        final errorMsg =
            'Server transient error ($statusCode): ${response.body}';
        await queue.markFailed(operation.id, errorMsg);
        await _recordEmergencySyncError(operation, errorMsg);

        return SyncResult.transientFailure(
          operationId: operation.id,
          emergencyLocalId: operation.emergencyLocalId,
          idempotencyKey: operation.idempotencyKey,
          httpStatusCode: statusCode,
          errorMessage: errorMsg,
        );
      } else if (statusCode == 409) {
        final errorMsg =
            'Idempotency conflict ($statusCode): ${response.body}';
        await queue.markFailed(operation.id, errorMsg);
        await _recordEmergencySyncError(operation, errorMsg);

        return SyncResult.permanentFailure(
          operationId: operation.id,
          emergencyLocalId: operation.emergencyLocalId,
          idempotencyKey: operation.idempotencyKey,
          httpStatusCode: statusCode,
          errorMessage: errorMsg,
        );
      } else {
        final errorMsg =
            'Permanent HTTP failure ($statusCode): ${response.body}';
        await queue.markFailed(operation.id, errorMsg);
        await _recordEmergencySyncError(operation, errorMsg);

        return SyncResult.permanentFailure(
          operationId: operation.id,
          emergencyLocalId: operation.emergencyLocalId,
          idempotencyKey: operation.idempotencyKey,
          httpStatusCode: statusCode,
          errorMessage: errorMsg,
        );
      }
    } on TimeoutException catch (_) {
      final errorMsg =
          'Request timed out after ${timeout.inSeconds}s (retryable)';
      await queue.markFailed(operation.id, errorMsg);
      await _recordEmergencySyncError(operation, errorMsg);

      return SyncResult.networkFailure(
        operationId: operation.id,
        emergencyLocalId: operation.emergencyLocalId,
        idempotencyKey: operation.idempotencyKey,
        errorMessage: errorMsg,
      );
    } catch (e) {
      final errorMsg = 'Network transport failure: $e (retryable)';
      await queue.markFailed(operation.id, errorMsg);
      await _recordEmergencySyncError(operation, errorMsg);

      return SyncResult.networkFailure(
        operationId: operation.id,
        emergencyLocalId: operation.emergencyLocalId,
        idempotencyKey: operation.idempotencyKey,
        errorMessage: errorMsg,
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Synchronizes an operation looked up by its local integer ID.
  Future<SyncResult> syncOperationById(
    int operationId, {
    http.Client? client,
  }) async {
    final op = await queue.getOperationById(operationId);
    if (op == null) {
      return SyncResult(
        status: SyncStatus.permanentFailure,
        operationId: operationId,
        isRetryable: false,
        errorMessage: 'Operation $operationId not found in queue',
      );
    }
    return syncOperation(op, client: client);
  }

  /// Synchronizes all pending operations in deterministic FIFO order.
  Future<List<SyncResult>> syncAllPending({http.Client? client}) async {
    final pending = await queue.getPendingOperations();
    final results = <SyncResult>[];
    for (final op in pending) {
      final res = await syncOperation(op, client: client);
      results.add(res);
    }
    return results;
  }

  Future<void> _reconcileSuccess({
    required PendingOperationEntry operation,
    required Map<String, dynamic> responseData,
  }) async {
    EmergencyEntry? entry;
    if (operation.emergencyLocalId != null) {
      entry = await repository.getEmergencyByLocalId(operation.emergencyLocalId!);
    }
    entry ??= await repository.getEmergencyByIdempotencyKey(operation.idempotencyKey);

    if (entry != null) {
      List<String>? reasons;
      if (responseData['priority_reasons'] is List) {
        reasons = (responseData['priority_reasons'] as List)
            .map((e) => e.toString())
            .toList();
      }

      await repository.updateEmergencyStatus(
        localId: entry.localId,
        status: responseData['status'] as String? ?? 'PENDING',
        syncStatus: 'SYNCED',
        serverId: responseData['id'] as String?,
        priorityScore: (responseData['priority_score'] as num?)?.toDouble(),
        priorityLevel: responseData['priority_level'] as String?,
        priorityReasons: reasons,
        vulnerabilityScore:
            (responseData['vulnerability_score'] as num?)?.toDouble(),
        lastSyncError: null,
        clearSyncError: true,
        updatedAt: DateTime.now().toUtc(),
      );
    }
  }

  Future<void> _recordEmergencySyncError(
    PendingOperationEntry operation,
    String error,
  ) async {
    EmergencyEntry? entry;
    if (operation.emergencyLocalId != null) {
      entry = await repository.getEmergencyByLocalId(operation.emergencyLocalId!);
    }
    entry ??= await repository.getEmergencyByIdempotencyKey(operation.idempotencyKey);

    if (entry != null) {
      await repository.updateEmergencyStatus(
        localId: entry.localId,
        status: entry.status,
        syncStatus: entry.syncStatus,
        lastSyncError: error,
      );
    }
  }
}
