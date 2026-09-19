import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/services/connectivity_service.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/services/pending_operation_queue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T055 — ConnectivityService Unit & Integration Tests', () {
    late MockConnectivityAdapter mockAdapter;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.wifi]);
    });

    tearDown(() {
      mockAdapter.dispose();
    });

    test('1. Initial connectivity state evaluates correctly upon initialization', () async {
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
        initialState: ConnectivityState.offline,
      );

      expect(service.isInitialized, isFalse);
      await service.initialize();
      expect(service.isInitialized, isTrue);
      expect(service.state, equals(ConnectivityState.online));
      expect(service.isOnline, isTrue);
      expect(service.isOffline, isFalse);
      expect(service.isIntermittent, isFalse);

      service.dispose();
    });

    test('2. Online state detection when network interface exists and probe succeeds', () async {
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.wifi]);
      var probeCalled = false;
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async {
          probeCalled = true;
          return true;
        },
      );

      final result = await service.checkConnectivity();
      expect(result, equals(ConnectivityState.online));
      expect(probeCalled, isTrue);
      expect(service.state, equals(ConnectivityState.online));

      service.dispose();
    });

    test('3. Offline state detection when no usable network interface exists (no probe called)', () async {
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.none]);
      var probeCalled = false;
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async {
          probeCalled = true;
          return true;
        },
      );

      final result = await service.checkConnectivity();
      expect(result, equals(ConnectivityState.offline));
      expect(probeCalled, isFalse); // Must not waste HTTP probe when no interface exists
      expect(service.isOffline, isTrue);

      service.dispose();
    });

    test('4. Intermittent state behavior when interface exists but probe returns false', () async {
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.mobile]);
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => false, // Backend unreachable
      );

      final result = await service.checkConnectivity();
      expect(result, equals(ConnectivityState.intermittent));
      expect(service.isIntermittent, isTrue);
      expect(service.isOnline, isFalse);

      service.dispose();
    });

    test('5. State transition: ONLINE -> OFFLINE via adapter stream event', () async {
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await service.initialize();
      expect(service.state, equals(ConnectivityState.online));

      final stateEvents = <ConnectivityState>[];
      final subscription = service.onConnectivityChanged.listen(stateEvents.add);

      // Simulate network disconnection
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(stateEvents, contains(ConnectivityState.offline));
      expect(service.state, equals(ConnectivityState.offline));

      await subscription.cancel();
      service.dispose();
    });

    test('6. State transition: OFFLINE -> ONLINE via adapter stream event', () async {
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.none]);
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await service.initialize();
      expect(service.state, equals(ConnectivityState.offline));

      final stateEvents = <ConnectivityState>[];
      final subscription = service.onConnectivityChanged.listen(stateEvents.add);

      // Simulate Wi-Fi connection restored
      mockAdapter.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(stateEvents, contains(ConnectivityState.online));
      expect(service.state, equals(ConnectivityState.online));

      await subscription.cancel();
      service.dispose();
    });

    test('7. State transition: ONLINE -> INTERMITTENT -> ONLINE', () async {
      var backendHealthy = true;
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => backendHealthy,
      );
      await service.initialize();
      expect(service.state, equals(ConnectivityState.online));

      final stateEvents = <ConnectivityState>[];
      final subscription = service.onConnectivityChanged.listen(stateEvents.add);

      // 1. Backend becomes unhealthy/unreachable while Wi-Fi stays up
      backendHealthy = false;
      await service.checkConnectivity();
      expect(service.state, equals(ConnectivityState.intermittent));

      // 2. Backend recovers
      backendHealthy = true;
      await service.checkConnectivity();
      expect(service.state, equals(ConnectivityState.online));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(stateEvents, equals([ConnectivityState.intermittent, ConnectivityState.online]));

      await subscription.cancel();
      service.dispose();
    });

    test('8. Repeated identical states do not emit duplicate events (strict deduplication)', () async {
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await service.initialize();
      expect(service.state, equals(ConnectivityState.online));

      final stateEvents = <ConnectivityState>[];
      final subscription = service.onConnectivityChanged.listen(stateEvents.add);

      // Re-emit identical wifi results multiple times
      mockAdapter.emit([ConnectivityResult.wifi]);
      mockAdapter.emit([ConnectivityResult.wifi]);
      await service.checkConnectivity();
      await service.checkConnectivity();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not have emitted any duplicate online event
      expect(stateEvents, isEmpty);

      await subscription.cancel();
      service.dispose();
    });

    test('9. Stream and listener disposal terminates subscriptions safely', () async {
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await service.initialize();

      expect(service.isDisposed, isFalse);
      service.dispose();
      expect(service.isDisposed, isTrue);

      // Subsequent calls do not throw or crash
      service.dispose();
      final afterState = await service.checkConnectivity();
      expect(afterState, isNotNull);
    });

    test('10. OfflineService receives and reflects connectivity updates from ConnectivityService', () async {
      final connectivityService = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await connectivityService.initialize();

      final repository = LocalEmergencyRepository.inMemory();
      final queue = PendingOperationQueue(repository.database);
      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
      );
      await offlineService.ensureInitialized();

      expect(offlineService.connectivity, equals(ConnectivityState.online));
      expect(offlineService.connectivityState, equals(ConnectivityState.online));

      var notified = false;
      offlineService.addListener(() {
        notified = true;
      });

      // Simulate connection dropping to offline
      mockAdapter.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(offlineService.connectivity, equals(ConnectivityState.offline));
      expect(notified, isTrue);

      offlineService.dispose();
      connectivityService.dispose();
      await repository.database.close();
    });

    test('11. Existing queue is NOT automatically synchronized when connectivity becomes ONLINE', () async {
      final connectivityService = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => true,
      );
      await connectivityService.initialize();

      final repository = LocalEmergencyRepository.inMemory();
      final queue = PendingOperationQueue(repository.database);
      final offlineService = OfflineService(
        repository: repository,
        queue: queue,
        connectivityService: connectivityService,
      );
      await offlineService.ensureInitialized();

      // Enqueue an emergency while offline
      offlineService.setConnectivity(ConnectivityState.offline);
      await offlineService.submitEmergency(
        title: 'Trapped citizen during Krishna surge',
        description: 'Water at first floor',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      final queueBefore = await queue.getPendingOperations();
      expect(queueBefore.length, equals(1));
      expect(offlineService.localQueue.length, equals(1));

      // Network transitions to ONLINE
      offlineService.setConnectivity(ConnectivityState.online);

      // Give event loop time to process any unexpected callbacks
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // CRITICAL T055 REQUIREMENT: Queue must NOT have been auto-synced or drained!
      final queueAfter = await queue.getPendingOperations();
      expect(queueAfter.length, equals(1));
      expect(queueAfter.first.status, equals('PENDING'));
      expect(offlineService.localQueue.length, equals(1));

      offlineService.dispose();
      connectivityService.dispose();
      await repository.database.close();
    });

    test('12. Connectivity detection can be mocked deterministically with custom adapters', () async {
      final customMock = MockConnectivityAdapter([ConnectivityResult.vpn]);
      var callCount = 0;

      final service = ConnectivityService(
        adapter: customMock,
        reachabilityProbe: () async {
          callCount++;
          return true;
        },
      );

      final state = await service.checkConnectivity();
      expect(state, equals(ConnectivityState.online));
      expect(callCount, equals(1));

      customMock.dispose();
      service.dispose();
    });

    test('13. Network interface presence without backend reachability yields INTERMITTENT (not false ONLINE)', () async {
      // Simulates Wi-Fi connected to a captive portal or isolated LAN with backend offline
      mockAdapter = MockConnectivityAdapter([ConnectivityResult.wifi]);
      final service = ConnectivityService(
        adapter: mockAdapter,
        reachabilityProbe: () async => throw TimeoutException('Probe timed out after 3000ms'),
      );

      final state = await service.checkConnectivity();
      expect(state, equals(ConnectivityState.intermittent));
      expect(service.isOnline, isFalse);
      expect(service.isIntermittent, isTrue);

      service.dispose();
    });
  });
}

