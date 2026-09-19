import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';
import 'package:disaster_response_flutter/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T056 — SyncService Unit & Integration Tests', () {
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
        timeout: const Duration(milliseconds: 200),
      );
    });

    tearDown(() async {
      await repository.database.close();
    });

    test('1. Successful emergency synchronization returns typed SyncResult.success', () async {
      const idempotencyKey = 'idemp-sync-001';
      final emergency = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Rooftop rescue',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'affected_count': 3,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: emergency.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Rooftop rescue',
          'category': 'FLOOD_RESCUE',
          'latitude': 16.5062,
          'longitude': 80.6480,
          'affected_count': 3,
        },
      );

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_srv_001',
            'title': 'Rooftop rescue',
            'status': 'PENDING',
            'priority_score': 88.5,
            'priority_level': 'HIGH',
            'priority_reasons': ['Elderly trapped'],
            'vulnerability_score': 45.0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(SyncStatus.success));
      expect(result.serverEmergencyId, equals('emg_srv_001'));
      expect(result.isRetryable, isFalse);
    });

    test('2. Correct request payload structure matches backend EmergencyCreate schema', () async {
      const idempotencyKey = 'idemp-sync-002';
      Map<String, dynamic>? capturedBody;

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Medical evacuation',
          'category': 'MEDICAL_EMERGENCY',
          'latitude': 16.5033,
          'longitude': 80.6465,
          'affected_count': 2,
          'vulnerability_snapshot': {'age': 75, 'can_swim': false},
          'sync_status': 'PENDING_SYNC', // Local-only field, must be stripped
          'status': 'LOCAL_PENDING',      // Local-only field, must be stripped
        },
      );

      final mockClient = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 'emg_srv_002', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      expect(capturedBody, isNotNull);
      expect(capturedBody!['title'], equals('Medical evacuation'));
      expect(capturedBody!['category'], equals('MEDICAL_EMERGENCY'));
      expect(capturedBody!['latitude'], equals(16.5033));
      expect(capturedBody!['longitude'], equals(80.6465));
      expect(capturedBody!['affected_count'], equals(2));
      expect(capturedBody!['idempotency_key'], equals(idempotencyKey));
      expect(capturedBody!['vulnerability_snapshot']['age'], equals(75));
      expect(capturedBody!.containsKey('sync_status'), isFalse);
      expect(capturedBody!.containsKey('status'), isFalse);
    });

    test('3. Original idempotency key is strictly preserved without mutation', () async {
      const originalKey = 'idemp-fixed-uuid-12345';
      String? sentKey;

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: originalKey,
        payload: {
          'idempotency_key': originalKey,
          'title': 'Test idempotency preservation',
          'category': 'FLOOD_RESCUE',
          'latitude': 16.5062,
          'longitude': 80.6480,
          'affected_count': 1,
        },
      );

      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        sentKey = body['idempotency_key'] as String?;
        return http.Response(
          jsonEncode({'id': 'emg_srv_003', 'status': 'PENDING'}),
          201,
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      expect(sentKey, equals(originalKey));
      expect(op.idempotencyKey, equals(originalKey));
    });

    test('4. Successful response stores server-assigned emergency ID in SQLite', () async {
      const idempotencyKey = 'idemp-sync-004';
      final localEmg = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Local incident',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: localEmg.localId,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Local incident'},
      );

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({'id': 'emg_server_uuid_999', 'status': 'ASSIGNED'}),
          201,
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      final updated = await repository.getEmergencyByLocalId(localEmg.localId);
      expect(updated, isNotNull);
      expect(updated!.id, equals('emg_server_uuid_999'));
      expect(updated.syncStatus, equals('SYNCED'));
    });

    test('5. Successful response updates priority fields in SQLite', () async {
      const idempotencyKey = 'idemp-sync-005';
      final localEmg = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Priority test incident',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: localEmg.localId,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Priority test'},
      );

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_srv_005',
            'status': 'PENDING',
            'priority_score': 92.5,
            'priority_level': 'CRITICAL',
            'priority_reasons': ['Oxygen Dependent', 'Rapid water rise'],
            'vulnerability_score': 55.0,
          }),
          201,
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      final updated = await repository.getEmergencyByLocalId(localEmg.localId);
      expect(updated!.priorityScore, equals(92.5));
      expect(updated.priorityLevel, equals('CRITICAL'));
      expect(updated.priorityReasons, contains('Oxygen Dependent'));
      expect(updated.vulnerabilityScore, equals(55.0));
    });

    test('6. Queue operation transitions to COMPLETED after success', () async {
      const idempotencyKey = 'idemp-sync-006';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Queue check'},
      );

      final mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'id': 'emg_006'}), 201);
      });

      await syncService.syncOperation(op, client: mockClient);

      final updatedOp = await queue.getOperationById(op.id);
      expect(updatedOp!.status, equals('COMPLETED'));
    });

    test('7. HTTP 400 handling marks operation as non-retryable validation failure', () async {
      const idempotencyKey = 'idemp-sync-007';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Bad title'},
      );

      final mockClient = MockClient((req) async {
        return http.Response('Title too short', 400);
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.status, equals(SyncStatus.validationFailure));
      expect(result.isRetryable, isFalse);
      expect(result.httpStatusCode, equals(400));

      final updatedOp = await queue.getOperationById(op.id);
      expect(updatedOp!.status, equals('FAILED'));
    });

    test('8. HTTP 422 handling marks operation as non-retryable validation failure', () async {
      const idempotencyKey = 'idemp-sync-008';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Unprocessable'},
      );

      final mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'detail': 'Invalid coordinates'}), 422);
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.status, equals(SyncStatus.validationFailure));
      expect(result.isRetryable, isFalse);
      expect(result.httpStatusCode, equals(422));
    });

    test('9. HTTP 500 handling marks operation as retryable transient failure', () async {
      const idempotencyKey = 'idemp-sync-009';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Server 500 test'},
      );

      final mockClient = MockClient((req) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.status, equals(SyncStatus.transientFailure));
      expect(result.isRetryable, isTrue);
      expect(result.httpStatusCode, equals(500));
    });

    test('10. HTTP 503 handling marks operation as retryable transient failure', () async {
      const idempotencyKey = 'idemp-sync-010';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Gateway 503 test'},
      );

      final mockClient = MockClient((req) async {
        return http.Response('Service Unavailable', 503);
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.status, equals(SyncStatus.transientFailure));
      expect(result.isRetryable, isTrue);
      expect(result.httpStatusCode, equals(503));
    });

    test('11. Timeout handling classifies failure as retryable and avoids stuck IN_FLIGHT state', () async {
      const idempotencyKey = 'idemp-sync-011';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Timeout test'},
      );

      final hangingClient = MockClient((req) async {
        // Sleep longer than timeout (200ms)
        await Future<void>.delayed(const Duration(milliseconds: 350));
        return http.Response('{"status": "ok"}', 200);
      });

      final result = await syncService.syncOperation(op, client: hangingClient);

      expect(result.status, equals(SyncStatus.networkFailure));
      expect(result.isRetryable, isTrue);
      expect(result.errorMessage, contains('timed out'));

      // Verify operation did NOT remain stuck in IN_FLIGHT
      final updatedOp = await queue.getOperationById(op.id);
      expect(updatedOp!.status, equals('FAILED'));
    });

    test('12. Network exception handling (SocketException) classified as retryable', () async {
      const idempotencyKey = 'idemp-sync-012';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Socket test'},
      );

      final socketFailClient = MockClient((req) async {
        throw const SocketException('Connection refused by host');
      });

      final result = await syncService.syncOperation(op, client: socketFailClient);

      expect(result.status, equals(SyncStatus.networkFailure));
      expect(result.isRetryable, isTrue);

      final updatedOp = await queue.getOperationById(op.id);
      expect(updatedOp!.status, equals('FAILED'));
    });

    test('13. Duplicate/idempotent response handling: server returns existing record and reconciles', () async {
      const idempotencyKey = 'idemp-sync-013';
      final localEmg = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Previously created incident',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: localEmg.localId,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Duplicate test'},
      );

      // Backend returns status 200 (existing entity retrieved)
      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_existing_777',
            'title': 'Previously created incident',
            'status': 'ASSIGNED',
            'priority_score': 75.0,
            'priority_level': 'HIGH',
          }),
          200,
        );
      });

      final result = await syncService.syncOperation(op, client: mockClient);

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(SyncStatus.duplicateAlreadySynced));
      expect(result.serverEmergencyId, equals('emg_existing_777'));

      final updated = await repository.getEmergencyByLocalId(localEmg.localId);
      expect(updated!.id, equals('emg_existing_777'));
      expect(updated.syncStatus, equals('SYNCED'));
    });

    test('14. Local emergency remains in database after sync failure', () async {
      const idempotencyKey = 'idemp-sync-014';
      final localEmg = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Resilient incident',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: localEmg.localId,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Resilient incident'},
      );

      final mockClient = MockClient((req) async {
        return http.Response('Gateway error', 502);
      });

      await syncService.syncOperation(op, client: mockClient);

      // Emergency must STILL exist in SQLite!
      final record = await repository.getEmergencyByLocalId(localEmg.localId);
      expect(record, isNotNull);
      expect(record!.lastSyncError, contains('502'));
    });

    test('15. Vulnerability snapshot is completely unchanged after synchronization', () async {
      const idempotencyKey = 'idemp-sync-015';
      final snapshot = {
        'age': 82,
        'age_group': 'ELDERLY',
        'can_swim': false,
        'mobility_status': 'BEDRIDDEN',
        'medical_conditions': ['Cardiac', 'Oxygen Dependent'],
      };

      final localEmg = await repository.saveEmergencyMap({
        'idempotency_key': idempotencyKey,
        'title': 'Vulnerability immutability incident',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'vulnerability_snapshot': snapshot,
      });

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        emergencyLocalId: localEmg.localId,
        payload: {
          'idempotency_key': idempotencyKey,
          'title': 'Vulnerability immutability incident',
          'category': 'FLOOD_RESCUE',
          'latitude': 16.5062,
          'longitude': 80.6480,
          'vulnerability_snapshot': snapshot,
        },
      );

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_srv_015',
            'status': 'PENDING',
            'priority_score': 95.0,
          }),
          201,
        );
      });

      await syncService.syncOperation(op, client: mockClient);

      final syncedRecord = await repository.getEmergencyByLocalId(localEmg.localId);
      final decodedSnapshot = jsonDecode(syncedRecord!.vulnerabilitySnapshot!) as Map<String, dynamic>;
      expect(decodedSnapshot['age'], equals(82));
      expect(decodedSnapshot['mobility_status'], equals('BEDRIDDEN'));
      expect(decodedSnapshot['can_swim'], equals(false));
      expect(decodedSnapshot['medical_conditions'], contains('Cardiac'));
    });

    test('16. Original queued payload is not mutated in SQLite', () async {
      const idempotencyKey = 'idemp-sync-016';
      final payload = {
        'idempotency_key': idempotencyKey,
        'title': 'Preserve payload test',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
      };

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: payload,
      );

      final mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'id': 'emg_016'}), 201);
      });

      await syncService.syncOperation(op, client: mockClient);

      final storedOp = await queue.getOperationById(op.id);
      final storedPayload = jsonDecode(storedOp!.payload) as Map<String, dynamic>;
      expect(storedPayload['title'], equals('Preserve payload test'));
      expect(storedPayload['latitude'], equals(16.5062));
    });

    test('17. IN_FLIGHT operation does not remain stuck after timeout or crash', () async {
      const idempotencyKey = 'idemp-sync-017';
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: idempotencyKey,
        payload: {'idempotency_key': idempotencyKey, 'title': 'Crash test'},
      );

      final crashingClient = MockClient((req) async {
        throw Exception('Simulated fatal transport crash');
      });

      await syncService.syncOperation(op, client: crashingClient);

      final opAfter = await queue.getOperationById(op.id);
      expect(opAfter!.status, isNot(equals('IN_FLIGHT')));
      expect(opAfter.status, equals('FAILED'));
    });

    test('18. OfflineService integration: syncPendingQueue uses SyncService seamlessly', () async {
      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        syncService: syncService,
      );
      await offlineService.ensureInitialized();

      offlineService.setConnectivity(ConnectivityState.offline);
      await offlineService.submitEmergency(
        title: 'Offline queued incident',
        description: 'Waiting for sync',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      expect(offlineService.localQueue.length, equals(1));

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_srv_integrated',
            'status': 'PENDING',
            'priority_score': 80.0,
            'priority_level': 'HIGH',
          }),
          201,
        );
      });

      await offlineService.syncPendingQueue(client: mockClient);

      expect(offlineService.localQueue, isEmpty);
      expect(offlineService.lastSyncError, isNull);

      final pendingAfter = await queue.getPendingCount();
      expect(pendingAfter, equals(0));

      offlineService.dispose();
    });

    test('19. Multiple queued emergencies preserve strict FIFO order during syncAllPending', () async {
      final processedOrder = <String>[];

      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-fifo-1',
        payload: {'idempotency_key': 'idemp-fifo-1', 'title': 'First Op'},
      );
      // Ensure slight timestamp separation
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-fifo-2',
        payload: {'idempotency_key': 'idemp-fifo-2', 'title': 'Second Op'},
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-fifo-3',
        payload: {'idempotency_key': 'idemp-fifo-3', 'title': 'Third Op'},
      );

      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        processedOrder.add(body['idempotency_key'] as String);
        return http.Response(jsonEncode({'id': 'emg_ok'}), 201);
      });

      final results = await syncService.syncAllPending(client: mockClient);

      expect(results.length, equals(3));
      expect(processedOrder, equals(['idemp-fifo-1', 'idemp-fifo-2', 'idemp-fifo-3']));
    });

    test('20. Successful sync of one operation does not delete or affect another', () async {
      final op1 = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-iso-1',
        payload: {'idempotency_key': 'idemp-iso-1', 'title': 'First Op'},
      );
      final op2 = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-iso-2',
        payload: {'idempotency_key': 'idemp-iso-2', 'title': 'Second Op'},
      );

      final mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'id': 'emg_iso_1'}), 201);
      });

      // Sync only op1
      await syncService.syncOperation(op1, client: mockClient);

      final check1 = await queue.getOperationById(op1.id);
      final check2 = await queue.getOperationById(op2.id);

      expect(check1!.status, equals('COMPLETED'));
      expect(check2!.status, equals('PENDING')); // Untouched!
    });

    test('21. Regression: Profile update from A to B does NOT alter snapshot of Emergency A when synchronized', () async {
      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        syncService: syncService,
      );
      await offlineService.ensureInitialized();

      // 1. Citizen Profile A (Elderly non-swimmer)
      const profileA = VulnerabilityProfile(
        age: 80,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['Hypertension'],
        status: ProfileStatus.completed,
      );
      await offlineService.saveVulnerabilityProfile(profileA);

      // 2. Submit emergency while offline
      offlineService.setConnectivity(ConnectivityState.offline);
      await offlineService.submitEmergency(
        title: 'Trapped senior during storm',
        description: 'Need assistance',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // 3. Citizen updates profile to Profile B (Young adult swimmer)
      const profileB = VulnerabilityProfile(
        age: 25,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        status: ProfileStatus.completed,
      );
      await offlineService.saveVulnerabilityProfile(profileB);
      expect(offlineService.vulnerabilityProfile.age, equals(25));

      // 4. Synchronize emergency to server
      Map<String, dynamic>? transmittedSnapshot;
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        transmittedSnapshot = body['vulnerability_snapshot'] as Map<String, dynamic>?;
        return http.Response(
          jsonEncode({
            'id': 'emg_snapshot_verified',
            'status': 'PENDING',
            'priority_score': 90.0,
            'priority_level': 'HIGH',
          }),
          201,
        );
      });

      await offlineService.syncPendingQueue(client: mockClient);

      // 5. Verify the transmitted snapshot was Profile A (age 80, non-swimmer)
      expect(transmittedSnapshot, isNotNull);
      expect(transmittedSnapshot!['age'], equals(80));
      expect(transmittedSnapshot!['can_swim'], equals(false));
      expect(transmittedSnapshot!['mobility_status'], equals('WHEELCHAIR'));

      offlineService.dispose();
    });
  });
}
