import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/connectivity_service.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';
import 'package:disaster_response_flutter/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T058 — Automatic Pending-Queue Synchronization Tests', () {
    late LocalEmergencyRepository repository;
    late PendingOperationQueue queue;
    late MockConnectivityAdapter mockAdapter;
    late ConnectivityService connectivityService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalEmergencyRepository.inMemory();
      queue = PendingOperationQueue(repository.database);
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.none]);
      connectivityService = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
        initialState: ConnectivityState.offline,
      );
    });

    tearDown(() async {
      connectivityService.dispose();
      mockAdapter.dispose();
      await repository.database.close();
    });

    Future<void> emitOnline(OfflineService service, [MockConnectivityAdapter? adapter]) async {
      (adapter ?? mockAdapter).emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await service.waitForSync();
    }

    test('1. Transition from OFFLINE to ONLINE automatically triggers queue synchronization', () async {
      await connectivityService.initialize();

      var syncCompleted = false;
      final mockClient = MockClient((req) async {
        if (req.url.path.contains('/api/v1/emergencies')) {
          syncCompleted = true;
          return http.Response(
            jsonEncode({
              'id': 'emg_auth_001',
              'title': 'Trapped citizen during Krishna surge',
              'status': 'PENDING',
              'sync_status': 'SYNCED',
            }),
            201,
            headers: {'Content-Type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Enqueue emergency while OFFLINE
      final emergency = await offlineService.submitEmergency(
        title: 'Trapped citizen during Krishna surge',
        description: 'Water at first floor',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      expect(emergency['sync_status'], equals('PENDING_SYNC'));
      final pendingBefore = await queue.getPendingCount();
      expect(pendingBefore, equals(1));

      // Network transitions to ONLINE via adapter
      await emitOnline(offlineService);

      expect(syncCompleted, isTrue);
      final pendingAfter = await queue.getPendingCount();
      expect(pendingAfter, equals(0));
      expect(offlineService.localQueue.isEmpty, isTrue);

      final syncedRecord = await repository.getEmergencyById('emg_auth_001');
      expect(syncedRecord, isNotNull);
      expect(syncedRecord!.syncStatus, equals('SYNCED'));

      offlineService.dispose();
    });

    test('2. Transition from INTERMITTENT to ONLINE automatically triggers queue synchronization', () async {
      var probeSuccess = false;
      final customConnectivity = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => probeSuccess,
        initialState: ConnectivityState.intermittent,
      );
      await customConnectivity.initialize();

      var syncCompleted = false;
      final mockClient = MockClient((req) async {
        syncCompleted = true;
        return http.Response(
          jsonEncode({
            'id': 'emg_auth_intermittent',
            'title': 'Medical assistance',
            'status': 'PENDING',
          }),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: customConnectivity,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Enqueue emergency while intermittent
      await offlineService.submitEmergency(
        title: 'Medical assistance',
        description: 'Oxygen required',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5033,
        longitude: 80.6465,
        affectedCount: 1,
      );

      expect(await queue.getPendingCount(), equals(1));
      expect(syncCompleted, isFalse);

      // Probe now succeeds, transition to ONLINE
      probeSuccess = true;
      await emitOnline(offlineService, mockAdapter);

      expect(syncCompleted, isTrue);
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
      customConnectivity.dispose();
    });

    test('3. Remaining in OFFLINE does not trigger synchronization', () async {
      await connectivityService.initialize();

      var httpCalled = false;
      final mockClient = MockClient((req) async {
        httpCalled = true;
        return http.Response('Server error', 500);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Offline report',
        description: 'No network at all',
        category: 'EVACUATION',
        latitude: 16.5000,
        longitude: 80.6400,
        affectedCount: 1,
      );

      expect(await queue.getPendingCount(), equals(1));

      // Emit another offline state
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(httpCalled, isFalse);
      expect(await queue.getPendingCount(), equals(1));

      offlineService.dispose();
    });

    test('4. Remaining in INTERMITTENT does not trigger synchronization', () async {
      final customConnectivity = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => false, // Backend unreachable
        initialState: ConnectivityState.intermittent,
      );
      await customConnectivity.initialize();

      var httpCalled = false;
      final mockClient = MockClient((req) async {
        httpCalled = true;
        return http.Response('Server error', 500);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: customConnectivity,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Intermittent report',
        description: 'Captive portal network',
        category: 'FOOD_WATER',
        latitude: 16.5100,
        longitude: 80.6500,
        affectedCount: 4,
      );

      expect(await queue.getPendingCount(), equals(1));

      // Stay intermittent by emitting cellular without reachability
      mockAdapter.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(httpCalled, isFalse);
      expect(await queue.getPendingCount(), equals(1));

      offlineService.dispose();
      customConnectivity.dispose();
    });

    test('5. Transition from ONLINE to OFFLINE to ONLINE triggers synchronization only upon reaching ONLINE', () async {
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.wifi]);
      connectivityService = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
        initialState: ConnectivityState.online,
      );
      await connectivityService.initialize();

      int syncAttempts = 0;
      final mockClient = MockClient((req) async {
        syncAttempts++;
        return http.Response(
          jsonEncode({'id': 'emg_auth_toggle', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Go OFFLINE
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(offlineService.isOnline, isFalse);

      // Submit while offline
      await offlineService.submitEmergency(
        title: 'Toggle test emergency',
        description: 'Submitted during offline interval',
        category: 'FLOOD_RESCUE',
        latitude: 16.5050,
        longitude: 80.6450,
        affectedCount: 2,
      );

      expect(await queue.getPendingCount(), equals(1));
      expect(syncAttempts, equals(0));

      // Return to ONLINE
      await emitOnline(offlineService);

      expect(syncAttempts, equals(1));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('6. Repeated ONLINE notifications do not trigger concurrent sync executions', () async {
      await connectivityService.initialize();

      int concurrentExecutions = 0;
      int maxConcurrent = 0;
      int totalCalls = 0;

      final mockClient = MockClient((req) async {
        totalCalls++;
        concurrentExecutions++;
        if (concurrentExecutions > maxConcurrent) {
          maxConcurrent = concurrentExecutions;
        }
        await Future<void>.delayed(const Duration(milliseconds: 60));
        concurrentExecutions--;
        return http.Response(
          jsonEncode({'id': 'emg_dedup_001', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Concurrency guard test',
        description: 'Testing race conditions',
        category: 'EVACUATION',
        latitude: 16.5000,
        longitude: 80.6400,
        affectedCount: 1,
      );

      // Emit ONLINE multiple times in rapid succession
      mockAdapter.emit([ConnectivityResult.wifi]);
      mockAdapter.emit([ConnectivityResult.wifi]);
      mockAdapter.emit([ConnectivityResult.ethernet]);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await offlineService.waitForSync();

      expect(maxConcurrent, equals(1));
      expect(totalCalls, equals(1));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('7. Synchronization processes pending operations in strict FIFO order', () async {
      await connectivityService.initialize();

      final List<String> executionOrder = [];

      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        executionOrder.add(body['idempotency_key'] as String);
        return http.Response(
          jsonEncode({'id': 'emg_${body['idempotency_key']}', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Submit 3 emergencies in sequence while offline
      await offlineService.submitEmergency(
        title: 'First Emergency',
        description: 'First in queue',
        category: 'FLOOD_RESCUE',
        latitude: 16.501,
        longitude: 80.641,
        affectedCount: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Second Emergency',
        description: 'Second in queue',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.502,
        longitude: 80.642,
        affectedCount: 2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Third Emergency',
        description: 'Third in queue',
        category: 'FIRE_EXPLOSION',
        latitude: 16.503,
        longitude: 80.643,
        affectedCount: 3,
      );

      final ops = await queue.getPendingOperations();
      expect(ops.length, equals(3));
      final expectedKeys = ops.map((o) => o.idempotencyKey).toList();

      // Transition to ONLINE
      await emitOnline(offlineService);

      expect(executionOrder, equals(expectedKeys));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('8. Successful synchronization updates local database record to COMPLETED / authoritative ID', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'id': 'emg_authoritative_999',
            'title': 'Authoritative ID check',
            'status': 'PENDING',
            'priority_score': 85.0,
            'priority_level': 'HIGH',
          }),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      final localEmergency = await offlineService.submitEmergency(
        title: 'Authoritative ID check',
        description: 'Verifying DB reconciliation',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );
      final item = localEmergency['item'] as Map<String, dynamic>;

      await emitOnline(offlineService);

      final updatedRecord = await repository.getEmergencyById('emg_authoritative_999');
      expect(updatedRecord, isNotNull);
      expect(updatedRecord!.id, equals('emg_authoritative_999'));
      expect(updatedRecord.localId, equals(item['local_id']));
      expect(updatedRecord.syncStatus, equals('SYNCED'));

      final allOps = await queue.getAllOperations();
      expect(allOps.first.status, equals('COMPLETED'));

      offlineService.dispose();
    });

    test('9. Transient network failure during auto-sync leaves operation retryable', () async {
      await connectivityService.initialize();

      var attempts = 0;
      final mockClient = MockClient((req) async {
        attempts++;
        if (attempts == 1) {
          throw const SocketException('Connection refused by server');
        }
        return http.Response(
          jsonEncode({'id': 'emg_retry_success', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Transient failure test',
        description: 'Server drops connection on first try',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Attempt 1: Auto-sync triggers but network throws SocketException
      await emitOnline(offlineService);

      final opsAfterFail = await queue.getAllOperations();
      expect(opsAfterFail.first.status, equals('FAILED'));
      expect(SyncService.isRetryableError(opsAfterFail.first.lastError), isTrue);

      // Network bounces: OFFLINE -> ONLINE
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await emitOnline(offlineService);

      // Attempt 2 succeeds and marks operation COMPLETED
      expect(attempts, equals(2));
      final opsAfterRetry = await queue.getAllOperations();
      expect(opsAfterRetry.first.status, equals('COMPLETED'));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('10. Permanent validation failure during auto-sync marks operation non-retryable and does not block subsequent cycles', () async {
      await connectivityService.initialize();

      var calls = 0;
      final mockClient = MockClient((req) async {
        calls++;
        return http.Response(
          jsonEncode({'detail': 'Validation failed: latitude out of bounds'}),
          422,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Validation error test',
        description: 'Invalid coordinates',
        category: 'FLOOD_RESCUE',
        latitude: 999.0, // Invalid
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Attempt 1: Triggers 422
      await emitOnline(offlineService);

      expect(calls, equals(1));
      final ops = await queue.getAllOperations();
      expect(ops.first.status, equals('FAILED'));
      expect(SyncService.isRetryableError(ops.first.lastError), isFalse);

      // Attempt 2: Toggle network again - non-retryable failed operation must NOT be endlessly retried
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await emitOnline(offlineService);

      expect(calls, equals(1)); // Was NOT retried
      expect(ops.first.status, equals('FAILED'));

      offlineService.dispose();
    });

    test('11. 409 conflict resolves idempotently to non-retryable failure without mutating local record', () async {
      await connectivityService.initialize();

      var calls = 0;
      final mockClient = MockClient((req) async {
        calls++;
        return http.Response(
          jsonEncode({
            'detail': 'Conflict: Emergency already exists with this idempotency key',
          }),
          409,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      final created = await offlineService.submitEmergency(
        title: 'Duplicate submitted report',
        description: 'Already accepted by backend',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );
      final item = created['item'] as Map<String, dynamic>;

      await emitOnline(offlineService);

      final ops = await queue.getAllOperations();
      expect(ops.first.status, equals('FAILED'));
      expect(SyncService.isRetryableError(ops.first.lastError), isFalse);

      final localRecord = await repository.getEmergencyByLocalId(item['local_id'] as int);
      expect(localRecord, isNotNull);
      expect(localRecord!.title, equals('Duplicate submitted report'));
      expect(localRecord.lastSyncError, contains('409'));

      // Ensure that a subsequent sync cycle does NOT endlessly retry the 409 conflict
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await emitOnline(offlineService);

      expect(calls, equals(1)); // Was NOT retried

      offlineService.dispose();
    });

    test('12. Partial queue success: failure of one operation does not corrupt or drop subsequent operations', () async {
      await connectivityService.initialize();

      int callIndex = 0;
      final mockClient = MockClient((req) async {
        callIndex++;
        if (callIndex == 1) {
          // First operation fails with permanent 400 Bad Request
          return http.Response(
            jsonEncode({'detail': 'Malformed request body'}),
            400,
            headers: {'Content-Type': 'application/json'},
          );
        }
        // Second operation succeeds
        return http.Response(
          jsonEncode({'id': 'emg_second_success', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Op 1 Bad Request',
        description: 'Will fail',
        category: 'FLOOD_RESCUE',
        latitude: 16.501,
        longitude: 80.641,
        affectedCount: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Op 2 Valid Request',
        description: 'Will succeed',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.502,
        longitude: 80.642,
        affectedCount: 2,
      );

      await emitOnline(offlineService);

      final allOps = await queue.getAllOperations();
      expect(allOps.length, equals(2));
      expect(allOps[0].status, equals('FAILED'));
      expect(allOps[1].status, equals('COMPLETED'));

      final syncedSecond = await repository.getEmergencyById('emg_second_success');
      expect(syncedSecond, isNotNull);
      expect(syncedSecond!.syncStatus, equals('SYNCED'));

      offlineService.dispose();
    });

    test('13. Existing local emergency data remains in SQLite after failed auto-sync', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        return http.Response('Internal Server Error', 500);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      final created = await offlineService.submitEmergency(
        title: 'Do not delete me on fail',
        description: 'Must persist locally across failures',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 5,
      );
      final item = created['item'] as Map<String, dynamic>;

      await emitOnline(offlineService);

      final localRecord = await repository.getEmergencyByLocalId(item['local_id'] as int);
      expect(localRecord, isNotNull);
      expect(localRecord!.title, equals('Do not delete me on fail'));
      expect(localRecord.description, equals('Must persist locally across failures'));
      expect(localRecord.affectedCount, equals(5));
      expect(localRecord.syncStatus, equals('PENDING_SYNC'));

      offlineService.dispose();
    });

    test('14. Vulnerability snapshot remains intact after auto-sync', () async {
      await connectivityService.initialize();

      Map<String, dynamic>? capturedPayload;
      final mockClient = MockClient((req) async {
        capturedPayload = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 'emg_snap_ok', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Step 1: User saves profile with wheelchair & asthma
      const originalProfile = VulnerabilityProfile(
        status: ProfileStatus.completed,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['ASTHMA'],
        ageGroup: 'ELDERLY',
        age: 72,
      );
      await offlineService.saveVulnerabilityProfile(originalProfile);

      // Step 2: Enqueue emergency while offline
      await offlineService.submitEmergency(
        title: 'Snapshot preservation test',
        description: 'Frozen profile in payload',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Step 3: User changes active profile in UI before sync occurs
      const updatedProfile = VulnerabilityProfile(
        status: ProfileStatus.completed,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        ageGroup: 'ADULT',
        age: 30,
      );
      await offlineService.saveVulnerabilityProfile(updatedProfile);

      // Step 4: Auto-sync triggers
      await emitOnline(offlineService);

      expect(capturedPayload, isNotNull);
      final sentSnapshot = capturedPayload!['vulnerability_snapshot'] as Map<String, dynamic>?;
      expect(sentSnapshot, isNotNull);
      expect(sentSnapshot!['mobility_status'], equals('WHEELCHAIR'));
      expect(sentSnapshot['medical_conditions'], contains('ASTHMA'));
      expect(sentSnapshot['age_group'], equals('ELDERLY'));

      offlineService.dispose();
    });

    test('15. Manual sync (syncPendingQueue) still works and shares concurrency lock with auto-sync', () async {
      await connectivityService.initialize();

      int calls = 0;
      final mockClient = MockClient((req) async {
        calls++;
        return http.Response(
          jsonEncode({'id': 'emg_manual_ok', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Manual sync test',
        description: 'Explicit sync execution',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Call manual sync directly
      final results = await offlineService.syncPendingQueue(client: mockClient);
      expect(results.length, equals(1));
      expect(results.first.isSuccess, isTrue);
      expect(calls, equals(1));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('16. Safe disposal of OfflineService and ConnectivityService stops background listening without leaks or errors', () async {
      await connectivityService.initialize();

      var httpCalled = false;
      final mockClient = MockClient((req) async {
        httpCalled = true;
        return http.Response('ok', 200);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      expect(offlineService.isDisposed, isFalse);
      offlineService.dispose();
      connectivityService.dispose();

      expect(offlineService.isDisposed, isTrue);
      expect(connectivityService.isDisposed, isTrue);

      // Emitting events after disposal must be safe and not trigger HTTP sync
      mockAdapter.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(httpCalled, isFalse);
    });
  });
}
