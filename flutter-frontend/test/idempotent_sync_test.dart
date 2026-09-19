import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';
import 'package:disaster_response_flutter/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T057 — Idempotent Synchronization Flutter Tests', () {
    late LocalEmergencyRepository repository;
    late PendingOperationQueue queue;
    late SyncService syncService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalEmergencyRepository.inMemory();
      queue = PendingOperationQueue(repository.database);
      syncService = SyncService(
        repository: repository,
        queue: queue,
        timeout: const Duration(milliseconds: 300),
      );
    });

    tearDown(() async {
      await repository.database.close();
    });

    test('1. Retry after lost network response with identical key reconciles server ID without duplicates', () async {
      const idempotencyKey = 'idemp-retry-001';
      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Flash flood roof rescue',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'affected_count': 2,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Flash flood roof rescue',
          'category': 'FLOOD_RESCUE',
          'latitude': 16.5062,
          'longitude': 80.6480,
          'affected_count': 2,
        },
      );

      // Attempt 1: Server processes the request, but response drops (simulated timeout)
      int callCount = 0;
      final flakyClient = MockClient((req) async {
        callCount++;
        if (callCount == 1) {
          throw http.ClientException('Connection dropped before response');
        }
        // Attempt 2: Server returns the existing record created during attempt 1 (HTTP 200)
        return http.Response(
          jsonEncode({
            'id': 'emg_authoritative_100',
            'title': 'Flash flood roof rescue',
            'category': 'FLOOD_RESCUE',
            'latitude': 16.5062,
            'longitude': 80.6480,
            'status': 'PENDING',
            'priority_score': 85.0,
            'priority_level': 'HIGH',
            'priority_reasons': ['Flood rescue in active zone'],
            'affected_count': 2,
          }),
          200,
        );
      });

      // Run attempt 1
      final result1 = await syncService.syncOperation(op, client: flakyClient);
      expect(result1.isSuccess, isFalse);
      expect(result1.status, equals(SyncStatus.networkFailure));
      expect(result1.isRetryable, isTrue);

      // Verify local emergency remains intact in SQLite
      final midState = await repository.getEmergencyByLocalId(emergency.localId);
      expect(midState, isNotNull);
      expect(midState!.syncStatus, equals('LOCAL_PENDING'));
      expect(midState.lastSyncError, contains('Network transport failure'));

      // Run attempt 2 (retry using same queued operation with identical idempotency key)
      final opRetry = await queue.getOperationById(op.id);
      expect(opRetry, isNotNull);
      expect(opRetry!.idempotencyKey, equals(idempotencyKey));

      final result2 = await syncService.syncOperation(opRetry, client: flakyClient);
      expect(result2.isSuccess, isTrue);
      expect(result2.status, equals(SyncStatus.duplicateAlreadySynced));
      expect(result2.serverEmergencyId, equals('emg_authoritative_100'));

      // Verify local emergency is reconciled with authoritative backend data
      final finalState = await repository.getEmergencyByLocalId(emergency.localId);
      expect(finalState!.id, equals('emg_authoritative_100'));
      expect(finalState.syncStatus, equals('SYNCED'));
      expect(finalState.priorityScore, equals(85.0));
      expect(finalState.priorityLevel, equals('HIGH'));
      expect(finalState.lastSyncError, isNull);

      // Verify operation is marked COMPLETED
      final completedOp = await queue.getOperationById(op.id);
      expect(completedOp!.status, equals('COMPLETED'));

      // Verify exactly ONE emergency exists in local SQLite
      final allEmergencies = await repository.getAllEmergencies();
      expect(allEmergencies.length, equals(1));
    });

    test('2. Duplicate server response (HTTP 200) does not duplicate local SQLite rows', () async {
      const idempotencyKey = 'idemp-dup-002';
      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Medical evacuation',
        'category': 'MEDICAL_EMERGENCY',
        'latitude': 12.9716,
        'longitude': 77.5946,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Medical evacuation',
          'category': 'MEDICAL_EMERGENCY',
          'latitude': 12.9716,
          'longitude': 77.5946,
        },
      );

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_authoritative_200',
            'title': 'Medical evacuation',
            'status': 'ASSIGNED',
            'priority_score': 90.0,
            'priority_level': 'CRITICAL',
          }),
          200,
        );
      });

      final result = await syncService.syncOperation(op, client: mockClient);
      expect(result.status, equals(SyncStatus.duplicateAlreadySynced));
      expect(result.isSuccess, isTrue);

      final emergencies = await repository.getAllEmergencies();
      expect(emergencies.length, equals(1));
      expect(emergencies.first.id, equals('emg_authoritative_200'));
      expect(emergencies.first.localId, equals(emergency.localId));
    });

    test('3. Local vulnerability profile edits do NOT leak into queued emergency snapshot during sync', () async {
      const idempotencyKey = 'idemp-snap-003';

      // Profile at creation time: Adult, can swim
      const initialProfile = VulnerabilityProfile(
        age: 30,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
      );

      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Water level rising',
        'category': 'FLOOD_RESCUE',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'vulnerability_snapshot': jsonEncode(initialProfile.toJson()),
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Water level rising',
          'category': 'FLOOD_RESCUE',
          'latitude': 13.0827,
          'longitude': 80.2707,
          'vulnerability_snapshot': initialProfile.toJson(),
        },
      );

      // User later edits profile to Elderly non-swimmer in wheelchair
      const updatedProfile = VulnerabilityProfile(
        age: 82,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['ASTHMA'],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vulnerability_profile', jsonEncode(updatedProfile.toJson()));

      // Capture request body sent over the wire
      late Map<String, dynamic> capturedBody;
      final mockClient = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'emg_authoritative_300',
            'title': 'Water level rising',
            'status': 'PENDING',
            'priority_score': 60.0,
            'priority_level': 'MEDIUM',
          }),
          201,
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      // Assert transmitted payload contains the ORIGINAL snapshot (Adult, canSwim=true)
      final snapshotInRequest = capturedBody['vulnerability_snapshot'] as Map<String, dynamic>;
      expect(snapshotInRequest['age_group'], equals('ADULT'));
      expect(snapshotInRequest['can_swim'], isTrue);
      expect(snapshotInRequest['mobility_status'], equals('FULL'));

      // Assert local SQLite emergency snapshot remains intact and unchanged
      final syncedEmergency = await repository.getEmergencyByLocalId(emergency.localId);
      final storedSnapshot = jsonDecode(syncedEmergency!.vulnerabilitySnapshot!) as Map<String, dynamic>;
      expect(storedSnapshot['age_group'], equals('ADULT'));
      expect(storedSnapshot['can_swim'], isTrue);
    });

    test('4. Server HTTP 409 Conflict marks operation as non-retryable failed without mutating existing local data', () async {
      const idempotencyKey = 'idemp-conflict-004';
      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Submerged home',
        'category': 'FLOOD_RESCUE',
        'latitude': 17.3850,
        'longitude': 78.4867,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Submerged home',
          'category': 'FLOOD_RESCUE',
          'latitude': 17.3850,
          'longitude': 78.4867,
        },
      );

      final conflictClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'detail': "Idempotency key conflict: key '$idempotencyKey' is already associated with a different emergency request."
          }),
          409,
        );
      });

      final result = await syncService.syncOperation(op, client: conflictClient);

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(SyncStatus.permanentFailure));
      expect(result.isRetryable, isFalse);
      expect(result.httpStatusCode, equals(409));
      expect(result.errorMessage, contains('Idempotency conflict (409)'));

      // Operation must be marked FAILED
      final failedOp = await queue.getOperationById(op.id);
      expect(failedOp!.status, equals('FAILED'));

      // Local emergency must preserve its original data and record error
      final emgState = await repository.getEmergencyByLocalId(emergency.localId);
      expect(emgState!.title, equals('Submerged home'));
      expect(emgState.lastSyncError, contains('409'));
    });

    test('5. Idempotency key is strictly invariant across repeated sync invocations', () async {
      const idempotencyKey = 'idemp-invariant-005';
      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Landslide alert',
        'category': 'LANDSLIDE',
        'latitude': 11.4102,
        'longitude': 76.6950,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Landslide alert',
          'category': 'LANDSLIDE',
          'latitude': 11.4102,
          'longitude': 76.6950,
        },
      );

      final transmittedKeys = <String>[];
      final trackingClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        transmittedKeys.add(body['idempotency_key'] as String);
        return http.Response('Internal error', 500);
      });

      // First sync attempt
      await syncService.syncOperation(op, client: trackingClient);

      // Second sync attempt on same operation
      final opRetry = await queue.getOperationById(op.id);
      await syncService.syncOperation(opRetry!, client: trackingClient);

      expect(transmittedKeys.length, equals(2));
      expect(transmittedKeys[0], equals(idempotencyKey));
      expect(transmittedKeys[1], equals(idempotencyKey));
    });

    test('6. Strict FIFO ordering is preserved across idempotent duplicate and new operations', () async {
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'fifo-key-1',
        payload: {'idempotency_key': 'fifo-key-1', 'title': 'First report'},
      );
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'fifo-key-2',
        payload: {'idempotency_key': 'fifo-key-2', 'title': 'Second report'},
      );

      final executionOrder = <String>[];
      final fifoClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final key = body['idempotency_key'] as String;
        executionOrder.add(key);

        if (key == 'fifo-key-1') {
          // op1 is an idempotent duplicate
          return http.Response(
            jsonEncode({'id': 'emg_dup_1', 'title': 'First report', 'status': 'PENDING'}),
            200,
          );
        } else {
          // op2 is a newly created entity
          return http.Response(
            jsonEncode({'id': 'emg_new_2', 'title': 'Second report', 'status': 'PENDING'}),
            201,
          );
        }
      });

      final results = await syncService.syncAllPending(client: fifoClient);

      expect(executionOrder, equals(['fifo-key-1', 'fifo-key-2']));
      expect(results.length, equals(2));
      expect(results[0].status, equals(SyncStatus.duplicateAlreadySynced));
      expect(results[1].status, equals(SyncStatus.success));
    });
  });
}
