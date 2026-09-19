import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/main.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/connectivity_service.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';
import 'package:disaster_response_flutter/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T060 — End-to-End Offline → Online Synchronization Tests', () {
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

    test('1. Full End-to-End Lifecycle: Offline emergency submission -> Online auto-sync -> Server reconciliation -> Tracking fetch', () async {
      await connectivityService.initialize();

      var syncCalled = false;
      var trackingCalled = false;

      final mockClient = MockClient((req) async {
        if (req.method == 'POST' && req.url.path.contains('/api/v1/emergencies')) {
          syncCalled = true;
          return http.Response(
            jsonEncode({
              'id': 'emg_authoritative_e2e_001',
              'title': 'Flash flood rescue at Krishna riverbank',
              'description': 'Family stranded on rooftop',
              'category': 'FLOOD_RESCUE',
              'latitude': 16.5062,
              'longitude': 80.6480,
              'status': 'PENDING',
              'priority_score': 92.5,
              'priority_level': 'CRITICAL',
              'priority_reasons': ['Elderly resident', 'Limited mobility'],
              'vulnerability_score': 42.5,
              'affected_count': 3,
            }),
            201,
            headers: {'Content-Type': 'application/json'},
          );
        } else if (req.method == 'GET' && req.url.path.contains('/api/v1/emergencies/emg_authoritative_e2e_001')) {
          trackingCalled = true;
          return http.Response(
            jsonEncode({
              'id': 'emg_authoritative_e2e_001',
              'title': 'Flash flood rescue at Krishna riverbank',
              'description': 'Family stranded on rooftop',
              'category': 'FLOOD_RESCUE',
              'latitude': 16.5062,
              'longitude': 80.6480,
              'status': 'ASSIGNED',
              'priority_score': 92.5,
              'priority_level': 'CRITICAL',
              'affected_count': 3,
              'assigned_resource': {
                'id': 'res_boat_01',
                'name': 'NDRF Rescue Boat Alpha',
                'resource_type': 'BOAT',
                'status': 'DISPATCHED',
              },
            }),
            200,
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

      // Step 1: Device is OFFLINE
      expect(offlineService.isOffline, isTrue);

      // Step 2: Citizen submits emergency while offline
      final submission = await offlineService.submitEmergency(
        title: 'Flash flood rescue at Krishna riverbank',
        description: 'Family stranded on rooftop',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 3,
      );

      expect(submission['sync_status'], equals('PENDING_SYNC'));
      expect(submission['status'], equals('SAVED_LOCALLY'));
      final item = submission['item'] as Map<String, dynamic>;
      final localId = item['local_id'] as int;

      // Verify local persistence
      final localBeforeSync = await repository.getEmergencyByLocalId(localId);
      expect(localBeforeSync, isNotNull);
      expect(localBeforeSync!.syncStatus, equals('PENDING_SYNC'));
      expect(await queue.getPendingCount(), equals(1));
      expect(offlineService.localQueue.length, equals(1));

      // Step 3: Device transitions to ONLINE
      await emitOnline(offlineService);

      // Step 4: Verification of automatic reconciliation
      expect(syncCalled, isTrue);
      expect(await queue.getPendingCount(), equals(0));
      expect(offlineService.localQueue.isEmpty, isTrue);

      final localAfterSync = await repository.getEmergencyById('emg_authoritative_e2e_001');
      expect(localAfterSync, isNotNull);
      expect(localAfterSync!.syncStatus, equals('SYNCED'));
      expect(localAfterSync.id, equals('emg_authoritative_e2e_001'));
      expect(localAfterSync.localId, equals(localId));

      // Step 5: Citizen opens tracking screen and queries tracking
      final tracking = await offlineService.fetchEmergencyTracking('emg_authoritative_e2e_001');
      expect(trackingCalled, isTrue);
      expect(tracking.id, equals('emg_authoritative_e2e_001'));
      expect(tracking.status, equals('ASSIGNED'));

      offlineService.dispose();
    });

    test('2. Intermittent Flapping Network: Heavy multi-incident queue accumulation and safe resume', () async {
      var probeSuccess = false;
      final flappingConnectivity = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => probeSuccess,
        initialState: ConnectivityState.offline,
      );
      await flappingConnectivity.initialize();

      final syncedIds = <String>[];
      int syncAttempts = 0;

      final mockClient = MockClient((req) async {
        syncAttempts++;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final key = body['idempotency_key'] as String;

        // Simulate network drop during second operation
        if (syncAttempts == 2) {
          throw const SocketException('Tower signal lost during flood surge');
        }

        final serverId = 'emg_srv_$key';
        syncedIds.add(serverId);
        return http.Response(
          jsonEncode({
            'id': serverId,
            'title': body['title'],
            'status': 'PENDING',
          }),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: flappingConnectivity,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      // Submit 3 emergencies in offline state
      await offlineService.submitEmergency(
        title: 'Incident 1 - Boat Rescue',
        description: 'First emergency in queue',
        category: 'FLOOD_RESCUE',
        latitude: 16.501,
        longitude: 80.641,
        affectedCount: 2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Incident 2 - Oxygen Cylinder',
        description: 'Second emergency in queue',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.502,
        longitude: 80.642,
        affectedCount: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Incident 3 - Food Packets',
        description: 'Third emergency in queue',
        category: 'FOOD_WATER',
        latitude: 16.503,
        longitude: 80.643,
        affectedCount: 5,
      );

      expect(await queue.getPendingCount(), equals(3));

      // Network transitions to INTERMITTENT (probe fails) -> Queue remains untouched!
      mockAdapter.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(flappingConnectivity.isIntermittent, isTrue);
      expect(await queue.getPendingCount(), equals(3));
      expect(syncAttempts, equals(0));

      // Network transitions to ONLINE (probe succeeds)
      probeSuccess = true;
      mockAdapter.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await offlineService.waitForSync();

      // First succeeded, second threw SocketException, halting the loop
      expect(syncedIds.length, equals(1));
      final opsAfterDrop = await queue.getAllOperations();
      expect(opsAfterDrop[0].status, equals('COMPLETED'));
      expect(opsAfterDrop[1].status, equals('FAILED'));
      expect(SyncService.isRetryableError(opsAfterDrop[1].lastError), isTrue);
      expect(opsAfterDrop[2].status, equals('PENDING'));

      // Network restores to ONLINE and retries
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await emitOnline(offlineService);

      // Remaining operations drain completely
      expect(syncedIds.length, equals(3));
      expect(await queue.getPendingCount(), equals(0));
      expect(offlineService.localQueue.isEmpty, isTrue);

      offlineService.dispose();
      flappingConnectivity.dispose();
    });

    test('3. Manual Trigger Parity: "Sync Now" respects concurrency lock and mirrors automatic sync', () async {
      await connectivityService.initialize();

      int calls = 0;
      final mockClient = MockClient((req) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response(
          jsonEncode({'id': 'emg_manual_parity', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
        autoSync: false, // Explicitly disable autoSync to test manual invocation
      );
      await offlineService.ensureInitialized();

      await offlineService.submitEmergency(
        title: 'Manual sync parity test',
        description: 'User initiated sync',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      // Set online
      offlineService.setConnectivity(ConnectivityState.online);
      expect(calls, equals(0)); // Auto-sync was disabled

      // Invoke manual sync
      final syncFuture = offlineService.syncPendingQueue(client: mockClient);
      // Concurrency guard: immediate second invocation while syncing returns []
      final concurrentResults = await offlineService.syncPendingQueue(client: mockClient);
      expect(concurrentResults.isEmpty, isTrue);

      final results = await syncFuture;
      expect(results.length, equals(1));
      expect(results.first.isSuccess, isTrue);
      expect(calls, equals(1));
      expect(await queue.getPendingCount(), equals(0));

      offlineService.dispose();
    });

    test('4. Vulnerability Snapshot Immutability: Server receives frozen snapshot regardless of subsequent profile edits', () async {
      await connectivityService.initialize();

      Map<String, dynamic>? receivedPayload;
      final mockClient = MockClient((req) async {
        receivedPayload = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'id': 'emg_snapshot_immutability', 'status': 'PENDING'}),
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

      // Step 1: User saves profile with specific constraints
      const originalProfile = VulnerabilityProfile(
        status: ProfileStatus.completed,
        mobilityStatus: 'BEDRIDDEN',
        medicalConditions: ['HYPERTENSION', 'DIABETES'],
        canSwim: false,
        ageGroup: 'ELDERLY',
        age: 78,
      );
      await offlineService.saveVulnerabilityProfile(originalProfile);

      // Step 2: Emergency submitted while offline
      await offlineService.submitEmergency(
        title: 'Bedridden elder evacuation',
        description: 'Oxygen and stretcher needed',
        category: 'EVACUATION',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Step 3: User edits active profile in UI before reconnecting
      const editedProfile = VulnerabilityProfile(
        status: ProfileStatus.completed,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        canSwim: true,
        ageGroup: 'ADULT',
        age: 25,
      );
      await offlineService.saveVulnerabilityProfile(editedProfile);

      // Step 4: Device reconnects and auto-sync triggers
      await emitOnline(offlineService);

      expect(receivedPayload, isNotNull);
      final snapshot = receivedPayload!['vulnerability_snapshot'] as Map<String, dynamic>?;
      expect(snapshot, isNotNull);
      expect(snapshot!['mobility_status'], equals('BEDRIDDEN'));
      expect(snapshot['can_swim'], isFalse);
      expect(snapshot['age_group'], equals('ELDERLY'));
      expect(snapshot['age'], equals(78));
      expect(snapshot['medical_conditions'], containsAll(['HYPERTENSION', 'DIABETES']));

      offlineService.dispose();
    });

    test('5. Cold Boot Simulation: New OfflineService instance restores persistent SQLite queue and completes sync upon connect', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({'id': 'emg_cold_boot_auth', 'status': 'PENDING'}),
          201,
          headers: {'Content-Type': 'application/json'},
        );
      });

      // App Session 1: User creates emergency while offline
      final session1 = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
        autoSync: false,
      );
      await session1.ensureInitialized();

      await session1.submitEmergency(
        title: 'Cold boot test report',
        description: 'Must persist across app kill',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      expect(await queue.getPendingCount(), equals(1));
      session1.dispose();

      // App Session 2: Fresh OfflineService starts up (simulating process restart)
      final session2 = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
        autoSync: true,
      );
      await session2.ensureInitialized();

      // Verifies restored in-memory queue from SQLite / SharedPreferences
      expect(session2.localQueue.length, equals(1));
      expect(session2.localQueue.first['title'], equals('Cold boot test report'));

      // Device goes online -> triggers auto-sync
      await emitOnline(session2);

      expect(await queue.getPendingCount(), equals(0));
      expect(session2.localQueue.isEmpty, isTrue);
      final record = await repository.getEmergencyById('emg_cold_boot_auth');
      expect(record, isNotNull);
      expect(record!.syncStatus, equals('SYNCED'));

      session2.dispose();
    });

    test('6. Server Idempotency Replay (HTTP 200) reconciles cleanly without duplicating SQLite entries', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        // Server responds 200 OK indicating request was previously received
        return http.Response(
          jsonEncode({
            'id': 'emg_replayed_server_id',
            'title': 'Replayed incident',
            'status': 'PENDING',
            'sync_status': 'SYNCED',
          }),
          200,
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
        title: 'Replayed incident',
        description: 'Testing 200 OK idempotent replay',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      await emitOnline(offlineService);

      expect(await queue.getPendingCount(), equals(0));
      final record = await repository.getEmergencyById('emg_replayed_server_id');
      expect(record, isNotNull);
      expect(record!.syncStatus, equals('SYNCED'));

      offlineService.dispose();
    });

    test('7. Batch Draining with Transient 503 Server Error halts queue and resumes when recovered', () async {
      await connectivityService.initialize();

      var serverHealthy = false;
      int callCount = 0;

      final mockClient = MockClient((req) async {
        callCount++;
        if (!serverHealthy) {
          return http.Response('Service Temporarily Unavailable', 503);
        }
        return http.Response(
          jsonEncode({'id': 'emg_recovered_$callCount', 'status': 'PENDING'}),
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
        title: 'First Emergency in Batch',
        description: 'Desc 1',
        category: 'FLOOD_RESCUE',
        latitude: 16.501,
        longitude: 80.641,
        affectedCount: 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await offlineService.submitEmergency(
        title: 'Second Emergency in Batch',
        description: 'Desc 2',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.502,
        longitude: 80.642,
        affectedCount: 2,
      );

      // Attempt 1: Server 503
      await emitOnline(offlineService);

      final ops = await queue.getAllOperations();
      expect(ops[0].status, equals('FAILED'));
      expect(SyncService.isRetryableError(ops[0].lastError), isTrue);

      // Server recovers
      serverHealthy = true;
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await emitOnline(offlineService);

      expect(await queue.getPendingCount(), equals(0));
      final finalOps = await queue.getAllOperations();
      expect(finalOps.every((o) => o.status == 'COMPLETED'), isTrue);

      offlineService.dispose();
    });

    test('8. Tracking Fetch Offline vs Online Fallback', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        if (req.url.path.contains('/api/v1/emergencies/emg_online_track')) {
          return http.Response(
            jsonEncode({
              'id': 'emg_online_track',
              'title': 'Online tracking query',
              'status': 'RESOLVED',
            }),
            200,
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

      // Submit while offline
      final submission = await offlineService.submitEmergency(
        title: 'Offline track query',
        description: 'Cached locally',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );
      final item = submission['item'] as Map<String, dynamic>;
      final idempKey = item['idempotency_key'] as String;

      // When OFFLINE: fetchEmergencyTracking returns local tracking
      final offlineTrack = await offlineService.fetchEmergencyTracking(idempKey);
      expect(offlineTrack.title, equals('Offline track query'));
      expect(offlineTrack.syncStatus, equals('PENDING_SYNC'));

      // When ONLINE: fetchEmergencyTracking fetches authoritative record from backend
      offlineService.setConnectivity(ConnectivityState.online);
      final onlineTrack = await offlineService.fetchEmergencyTracking('emg_online_track');
      expect(onlineTrack.status, equals('RESOLVED'));

      offlineService.dispose();
    });

    test('9. Zero Data Loss Invariant: Local SQLite records remain completely intact across repeated network failures', () async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        return http.Response('Fatal Server Error', 500);
      });

      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
        defaultClient: mockClient,
      );
      await offlineService.ensureInitialized();

      final created = await offlineService.submitEmergency(
        title: 'Critical lifeline rescue',
        description: 'Submerged home with children',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 4,
      );
      final item = created['item'] as Map<String, dynamic>;
      final localId = item['local_id'] as int;

      // Trigger 5 repeated failed online attempts
      for (int i = 0; i < 3; i++) {
        mockAdapter.emit([ConnectivityResult.wifi]);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await offlineService.waitForSync();
        mockAdapter.emit([ConnectivityResult.none]);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      // Query database directly
      final localRecord = await repository.getEmergencyByLocalId(localId);
      expect(localRecord, isNotNull);
      expect(localRecord!.title, equals('Critical lifeline rescue'));
      expect(localRecord.description, equals('Submerged home with children'));
      expect(localRecord.affectedCount, equals(4));
      expect(localRecord.category, equals('FLOOD_RESCUE'));
      expect(localRecord.syncStatus, equals('PENDING_SYNC'));

      offlineService.dispose();
    });

    testWidgets('10. UI Widget State Transition: HomeScreen truthful offline-to-online visual update with DRISHTI palette', (WidgetTester tester) async {
      await connectivityService.initialize();

      final mockClient = MockClient((req) async {
        return http.Response(
          jsonEncode({'id': 'emg_ui_synced', 'status': 'PENDING'}),
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

      // Submit emergency while offline
      await offlineService.submitEmergency(
        title: 'UI Visual Test Emergency',
        description: 'Testing color & state transition',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      await offlineService.saveVulnerabilityProfile(
        const VulnerabilityProfile(status: ProfileStatus.completed),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OfflineService>.value(value: offlineService),
          ],
          child: const DrishtiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Verify Offline UI rendering
      expect(find.text("You're Offline"), findsOneWidget);
      expect(find.text('Request saved locally'), findsOneWidget);
      expect(find.text('Will sync automatically when connection returns'), findsOneWidget);
      expect(find.text('1 Pending'), findsOneWidget);

      // Step 2: Transition connectivity to ONLINE
      offlineService.setConnectivity(ConnectivityState.online);
      await tester.pump();
      await offlineService.waitForSync();
      await tester.pumpAndSettle();

      // Step 3: Verify Online Synchronized UI rendering
      expect(find.text("You're Offline"), findsNothing);
      expect(find.text('Offline Sync Queue: 0 Pending'), findsOneWidget);
      expect(find.text('All emergency reports are synchronized.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);

      offlineService.dispose();
    });
  });
}
