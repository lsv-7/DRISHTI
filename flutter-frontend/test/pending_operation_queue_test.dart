import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_response_flutter/database/app_database.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';

void main() {
  group('T054 — PendingOperationQueue Unit & Durability Tests', () {
    late AppDatabase db;
    late PendingOperationQueue queue;
    late LocalEmergencyRepository repository;

    setUp(() {
      // In-memory isolated SQLite database for hermetic testing
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingOperationQueue(db);
      repository = LocalEmergencyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Database initializes with schema version 2 and empty queue table', () async {
      expect(db.schemaVersion, equals(2));
      final all = await queue.getAllOperations();
      expect(all, isEmpty);
      expect(await queue.getPendingCount(), equals(0));
    });

    test('2. Enqueue operation persists typed PendingOperationEntry', () async {
      final payload = {
        'idempotency_key': 'idemp-q-1',
        'title': 'Rooftop rescue in flood zone',
        'category': 'FLOOD_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'affected_count': 3,
        'vulnerability_snapshot': {
          'mobility_status': 'WHEELCHAIR',
          'elderly_count': 1,
        },
      };

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'idemp-q-1',
        payload: payload,
        emergencyLocalId: 101,
      );

      expect(op.id, equals(1));
      expect(op.operationType, equals('CREATE_EMERGENCY'));
      expect(op.idempotencyKey, equals('idemp-q-1'));
      expect(op.emergencyLocalId, equals(101));
      expect(op.status, equals('PENDING'));
      expect(op.attemptCount, equals(0));
      expect(op.lastAttemptedAt, isNull);
      expect(op.lastError, isNull);

      final decoded = jsonDecode(op.payload) as Map<String, dynamic>;
      expect(decoded['title'], equals('Rooftop rescue in flood zone'));
      expect(decoded['latitude'], equals(16.5062));
      expect(decoded['longitude'], equals(80.6480));
      expect(decoded['vulnerability_snapshot']['mobility_status'], equals('WHEELCHAIR'));
    });

    test('3. Deterministic FIFO ordering: getPendingOperations returns oldest first', () async {
      final p1 = {'title': 'Op 1', 'idempotency_key': 'k-1'};
      final p2 = {'title': 'Op 2', 'idempotency_key': 'k-2'};
      final p3 = {'title': 'Op 3', 'idempotency_key': 'k-3'};

      await queue.enqueue(operationType: 'CREATE_EMERGENCY', idempotencyKey: 'k-1', payload: p1);
      await queue.enqueue(operationType: 'CREATE_EMERGENCY', idempotencyKey: 'k-2', payload: p2);
      await queue.enqueue(operationType: 'CREATE_EMERGENCY', idempotencyKey: 'k-3', payload: p3);

      final list = await queue.getPendingOperations();
      expect(list.length, equals(3));
      expect(list[0].idempotencyKey, equals('k-1'));
      expect(list[1].idempotencyKey, equals('k-2'));
      expect(list[2].idempotencyKey, equals('k-3'));
      expect(await queue.getPendingCount(), equals(3));
    });

    test('4. peekOldestPending returns oldest PENDING item without modifying queue', () async {
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'first-key',
        payload: {'title': 'Oldest emergency'},
      );
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'second-key',
        payload: {'title': 'Newer emergency'},
      );

      final oldest = await queue.peekOldestPending();
      expect(oldest, isNotNull);
      expect(oldest!.idempotencyKey, equals('first-key'));
      expect(jsonDecode(oldest.payload)['title'], equals('Oldest emergency'));

      // Peek should not alter pending count
      expect(await queue.getPendingCount(), equals(2));
    });

    test('5. Lifecycle status transitions: markInFlight, markCompleted, markFailed, resetToPending', () async {
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'state-key-1',
        payload: {'title': 'State test'},
      );

      // 1. Mark in-flight
      await queue.markInFlight(op.id);
      var current = await queue.getOperationById(op.id);
      expect(current!.status, equals('IN_FLIGHT'));
      expect(current.attemptCount, equals(1));
      expect(current.lastAttemptedAt, isNotNull);

      // 2. Mark failed
      await queue.markFailed(op.id, 'HTTP 503 Service Unavailable');
      current = await queue.getOperationById(op.id);
      expect(current!.status, equals('FAILED'));
      expect(current.lastError, equals('HTTP 503 Service Unavailable'));

      // 3. Reset to pending
      await queue.resetToPending(op.id);
      current = await queue.getOperationById(op.id);
      expect(current!.status, equals('PENDING'));

      // 4. Mark completed
      await queue.markCompleted(op.id);
      current = await queue.getOperationById(op.id);
      expect(current!.status, equals('COMPLETED'));

      // Completed items should not count as pending
      expect(await queue.getPendingCount(), equals(0));
    });

    test('6. Idempotency: duplicate idempotencyKey returns existing record without error or duplicate', () async {
      final payload = {'title': 'Idempotent test', 'category': 'FLOOD_RESCUE'};

      final first = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'duplicate-safe-key',
        payload: payload,
      );

      final second = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'duplicate-safe-key',
        payload: payload,
      );

      expect(second.id, equals(first.id));
      expect(second.idempotencyKey, equals('duplicate-safe-key'));

      final all = await queue.getAllOperations();
      expect(all.length, equals(1));
    });

    test('7. Immutable vulnerability snapshot: payload snapshot unchanged after profile edit', () async {
      const initialProfile = VulnerabilityProfile(
        age: 80,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'BEDRIDDEN',
        medicalConditions: ['OXYGEN_DEPENDENT'],
        status: ProfileStatus.completed,
      );

      final originalSnapshot = initialProfile.toSnapshot();

      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'vuln-snap-queue',
        payload: {
          'idempotency_key': 'vuln-snap-queue',
          'title': 'Bedridden flood evacuation',
          'vulnerability_snapshot': originalSnapshot,
        },
      );

      // Simulate profile changing later
      const mutatedProfile = VulnerabilityProfile(
        age: 20,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        status: ProfileStatus.completed,
      );
      expect(mutatedProfile.mobilityStatus, equals('FULL'));

      // Re-read payload from queue
      final reloaded = await queue.getOperationById(op.id);
      final decoded = jsonDecode(reloaded!.payload) as Map<String, dynamic>;
      final storedSnapshot = decoded['vulnerability_snapshot'] as Map<String, dynamic>;

      expect(storedSnapshot['mobility_status'], equals('BEDRIDDEN'));
      expect(storedSnapshot['age'], equals(80));
      expect(storedSnapshot['medical_conditions'], contains('OXYGEN_DEPENDENT'));
    });

    test('8. Exact location coordinates preserved in queued payload', () async {
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'loc-key-1',
        payload: {
          'title': 'Sector C emergency',
          'latitude': 16.5033,
          'longitude': 80.6465,
          'location_source': 'disasterSector',
        },
      );

      final fetched = await queue.getOperationById(op.id);
      final decoded = jsonDecode(fetched!.payload) as Map<String, dynamic>;
      expect(decoded['latitude'], equals(16.5033));
      expect(decoded['longitude'], equals(80.6465));
      expect(decoded['location_source'], equals('disasterSector'));
    });

    test('9. Atomic transaction: saveAndEnqueueEmergency creates emergency and queue operation together', () async {
      final payload = {
        'idempotency_key': 'atomic-key-99',
        'title': 'Atomic emergency save and queue',
        'category': 'MEDICAL_EMERGENCY',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'affected_count': 1,
        'sync_status': 'PENDING_SYNC',
        'status': 'LOCAL_PENDING',
      };

      final emergency = await repository.saveAndEnqueueEmergency(
        payload: payload,
        queue: queue,
      );

      expect(emergency.localId, isNotNull);
      expect(emergency.idempotencyKey, equals('atomic-key-99'));

      final queuedOp = await queue.getOperationByIdempotencyKey('atomic-key-99');
      expect(queuedOp, isNotNull);
      expect(queuedOp!.emergencyLocalId, equals(emergency.localId));
      expect(queuedOp.operationType, equals('CREATE_EMERGENCY'));
      expect(queuedOp.status, equals('PENDING'));
    });

    test('10. Deletion and clearQueue removes operations', () async {
      final op = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'del-key-1',
        payload: {'title': 'Delete me'},
      );

      final deleted = await queue.deleteOperation(op.id);
      expect(deleted, equals(1));
      expect(await queue.getOperationById(op.id), isNull);

      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'clear-k1',
        payload: {'title': 'Item 1'},
      );
      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'clear-k2',
        payload: {'title': 'Item 2'},
      );
      expect(await queue.getPendingCount(), equals(2));

      await queue.clearQueue();
      expect(await queue.getPendingCount(), equals(0));
    });

    test('11. Reactive watchPendingOperations emits stream updates on enqueue and completion', () async {
      final stream = queue.watchPendingOperations();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
          hasLength(2),
          hasLength(1), // after markCompleted
        ]),
      );

      await pumpEventQueue();

      final op1 = await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'st-key-1',
        payload: {'title': 'Stream 1'},
      );

      await pumpEventQueue();

      await queue.enqueue(
        operationType: 'CREATE_EMERGENCY',
        idempotencyKey: 'st-key-2',
        payload: {'title': 'Stream 2'},
      );

      await pumpEventQueue();

      await queue.markCompleted(op1.id);

      await expectation;
    });

    test('12. OfflineService integration: offline submitEmergency persists to durable SQLite queue', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService(repository: repository, queue: queue);
      await service.ensureInitialized();

      service.setConnectivity(ConnectivityState.offline);

      final result = await service.submitEmergency(
        title: 'Offline submit with durable queue',
        description: 'Testing SQLite queue durability',
        category: 'FLOOD_RESCUE',
        latitude: 16.5075,
        longitude: 80.6055,
        affectedCount: 2,
      );

      expect(result['status'], equals('SAVED_LOCALLY'));
      final item = result['item'] as Map<String, dynamic>;
      final idempotencyKey = item['idempotency_key'] as String;

      // Verify that the queue contains the pending operation in SQLite
      final queued = await queue.getOperationByIdempotencyKey(idempotencyKey);
      expect(queued, isNotNull);
      expect(queued!.status, equals('PENDING'));
      expect(queued.operationType, equals('CREATE_EMERGENCY'));
      expect(await queue.getPendingCount(), equals(1));

      final decoded = jsonDecode(queued.payload) as Map<String, dynamic>;
      expect(decoded['title'], equals('Offline submit with durable queue'));
    });

    test('13. OfflineService integration: syncPendingQueue marks queue operation COMPLETED', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService(repository: repository, queue: queue);
      await service.ensureInitialized();

      service.setConnectivity(ConnectivityState.offline);

      final submitRes = await service.submitEmergency(
        title: 'Pending for sync test',
        description: 'To be synced online',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      final item = submitRes['item'] as Map<String, dynamic>;
      final idempKey = item['idempotency_key'] as String;

      // Mock backend returning 201 Created
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/emergencies') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 'emg_sync_done_1',
              'idempotency_key': idempKey,
              'title': 'Pending for sync test',
              'category': 'FLOOD_RESCUE',
              'latitude': 16.5062,
              'longitude': 80.6480,
              'status': 'PENDING',
              'sync_status': 'SYNCED',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      // Synchronize
      await service.syncPendingQueue(client: mockClient);

      // Verify queue operation was marked COMPLETED
      final op = await queue.getOperationByIdempotencyKey(idempKey);
      expect(op, isNotNull);
      expect(op!.status, equals('COMPLETED'));
      expect(await queue.getPendingCount(), equals(0));
    });

    test('14. OfflineService startup migration: loads pending queue from SQLite and migrates legacy SharedPreferences', () async {
      // Simulate legacy items in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'pending_queue': jsonEncode([
          {
            'idempotency_key': 'legacy-key-1',
            'title': 'Legacy report from SharedPreferences',
            'category': 'RELIEF_SUPPLY',
            'latitude': 16.5,
            'longitude': 80.6,
            'status': 'LOCAL_PENDING',
          }
        ]),
      });

      final service = OfflineService(repository: repository, queue: queue);
      await service.ensureInitialized();

      // Verify that the legacy item was migrated into the SQLite queue
      final migratedOp = await queue.getOperationByIdempotencyKey('legacy-key-1');
      expect(migratedOp, isNotNull);
      expect(migratedOp!.operationType, equals('CREATE_EMERGENCY'));
      expect(migratedOp.status, equals('PENDING'));
      expect(service.localQueue.length, equals(1));
      expect(service.localQueue[0]['title'], equals('Legacy report from SharedPreferences'));
    });
  });
}
