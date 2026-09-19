import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_response_flutter/models/emergency_tracking.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/screens/emergency_tracking_screen.dart';
import 'package:disaster_response_flutter/screens/emergency_confirmation_screen.dart';
import 'package:disaster_response_flutter/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T050 — Emergency Tracking Model Tests', () {
    test('1. EmergencyTracking model serialization and deserialization', () {
      final now = DateTime.now();
      final tracking = EmergencyTracking(
        id: 'emg_trk_100',
        userId: 'usr_abc',
        zoneId: 'zone_north',
        title: 'Elderly citizen trapped on roof',
        description: 'Water level reached 4 feet',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        status: 'ASSIGNED',
        priorityScore: 92.5,
        priorityLevel: 'CRITICAL',
        priorityReasons: const ['Active flood', 'Elderly non-swimmer', 'Mobility limited'],
        vulnerabilityScore: 78.0,
        vulnerabilityFactors: const {'age_risk': 1.5, 'mobility_factor': 2.0},
        affectedCount: 2,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'SYNCED',
        locationLabel: 'Sector 4, Vijayawada',
        hasVulnerabilitySnapshot: true,
      );

      final json = tracking.toJson();
      expect(json['id'], 'emg_trk_100');
      expect(json['title'], 'Elderly citizen trapped on roof');
      expect(json['category'], 'FLOOD_RESCUE');
      expect(json['status'], 'ASSIGNED');
      expect(json['priority_level'], 'CRITICAL');
      expect(json['priority_score'], 92.5);
      expect(json['affected_count'], 2);
      expect(json['has_vulnerability_snapshot'], true);

      final parsed = EmergencyTracking.fromJson(json);
      expect(parsed.id, tracking.id);
      expect(parsed.title, tracking.title);
      expect(parsed.description, tracking.description);
      expect(parsed.category, tracking.category);
      expect(parsed.status, 'ASSIGNED');
      expect(parsed.priorityLevel, 'CRITICAL');
      expect(parsed.priorityScore, 92.5);
      expect(parsed.priorityReasons.length, 3);
      expect(parsed.affectedCount, 2);
      expect(parsed.timelineStep, 2);
      expect(parsed.isLocalPending, false);
    });

    test('2. EmergencyTracking from local offline queue item', () {
      final localMap = {
        'idempotency_key': 'idem_local_888',
        'title': 'Flash flood assistance required',
        'category': 'FLASH_FLOOD',
        'latitude': 16.5120,
        'longitude': 80.6410,
        'affected_count': 3,
        'created_at': DateTime.now().toIso8601String(),
        'vulnerability_snapshot': {
          'age': 72,
          'can_swim': false,
          'mobility_status': 'LIMITED',
        },
      };

      final tracking = EmergencyTracking.fromLocalEmergency(localMap);
      expect(tracking.id, 'idem_local_888');
      expect(tracking.status, 'LOCAL_PENDING');
      expect(tracking.syncStatus, 'PENDING_SYNC');
      expect(tracking.isLocalPending, true);
      expect(tracking.priorityLevel, isNull);
      expect(tracking.priorityScore, isNull);
      expect(tracking.hasVulnerabilitySnapshot, true);
      expect(tracking.timelineStep, 0);
      expect(tracking.statusDisplay, contains('SAVED LOCALLY'));
      expect(tracking.statusDescription, contains('offline queue'));
    });

    test('3. Status progression, badge colors, and timeline steps for all backend statuses', () {
      final now = DateTime.now();

      final statuses = ['LOCAL_PENDING', 'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CANCELLED'];
      final expectedSteps = [0, 1, 2, 3, 4, 0];

      for (int i = 0; i < statuses.length; i++) {
        final trk = EmergencyTracking(
          id: 'test_$i',
          title: 'Test Status $i',
          category: 'FLOOD_RESCUE',
          latitude: 16.5,
          longitude: 80.6,
          status: statuses[i],
          createdAt: now,
          updatedAt: now,
        );

        expect(trk.timelineStep, expectedSteps[i]);
        expect(trk.statusDisplay.isNotEmpty, true);
        expect(trk.statusDescription.isNotEmpty, true);
        expect(trk.statusColor, isNotNull);
        expect(trk.statusIcon, isNotNull);
      }
    });
  });

  group('T050 — OfflineService Tracking Integration Tests', () {
    test('4. Fetch online emergency tracking via GET /api/v1/emergencies/{id}', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      final mockBackendResponse = {
        'id': 'emg_srv_777',
        'title': 'Water rescue needed',
        'description': 'Rapid current near main road',
        'category': 'WATER_RESCUE',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'status': 'IN_PROGRESS',
        'priority_level': 'HIGH',
        'priority_score': 84.0,
        'priority_reasons': ['Water current above threshold', 'High density sector'],
        'affected_count': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'vulnerability_snapshot': {'can_swim': false},
      };

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, contains('/emergencies/emg_srv_777'));
        return http.Response(jsonEncode(mockBackendResponse), 200, headers: {'content-type': 'application/json'});
      });

      final result = await service.fetchEmergencyTracking('emg_srv_777', client: client);

      expect(result.id, 'emg_srv_777');
      expect(result.status, 'IN_PROGRESS');
      expect(result.priorityLevel, 'HIGH');
      expect(result.priorityScore, 84.0);
      expect(result.priorityReasons.length, 2);
      expect(result.timelineStep, 3);
      expect(service.hasActiveEmergency, true);
      expect(service.activeEmergency!['id'], 'emg_srv_777');
    });

    test('5. Handle 404 Emergency Not Found truthfully without fabrication', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      final client = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Emergency not found.'}), 404);
      });

      expect(
        () async => await service.fetchEmergencyTracking('non_existent_id', client: client),
        throwsA(predicate((e) => e.toString().contains('not found on server'))),
      );
    });

    test('6. Resolve tracking from local queue when device is offline', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // Submit offline emergency
      final submitResult = await service.submitEmergency(
        title: 'Offline distress call',
        description: 'Power line down in water',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );

      final item = submitResult['item'] as Map<String, dynamic>;
      final idempotencyKey = item['idempotency_key'] as String;

      // Fetch tracking for the offline queued emergency
      final tracking = await service.fetchEmergencyTracking(idempotencyKey);

      expect(tracking.id, idempotencyKey);
      expect(tracking.status, 'LOCAL_PENDING');
      expect(tracking.isLocalPending, true);
      expect(tracking.title, 'Offline distress call');
      expect(tracking.statusDisplay, contains('SAVED LOCALLY'));
    });

    test('7. Fallback to cached active emergency when network fails during refresh', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      // Seed cached active emergency
      final cachedMap = {
        'id': 'emg_cached_555',
        'title': 'Medical evacuation',
        'category': 'MEDICAL_EMERGENCY',
        'latitude': 16.5062,
        'longitude': 80.6480,
        'status': 'ASSIGNED',
        'priority_level': 'HIGH',
        'priority_score': 85.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await service.setActiveEmergency(cachedMap);

      // Network throws error
      final client = MockClient((request) async {
        throw http.ClientException('Connection reset by peer');
      });

      final tracking = await service.fetchEmergencyTracking('emg_cached_555', client: client);

      expect(tracking.id, 'emg_cached_555');
      expect(tracking.status, 'ASSIGNED');
      expect(tracking.title, 'Medical evacuation');
    });
  });

  group('T050 — UI Widget Tests for Emergency Tracking & Navigation', () {
    testWidgets('8. EmergencyTrackingScreen displays incident data, timeline, and priority', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();

      final initialTracking = EmergencyTracking(
        id: 'emg_trk_widget',
        title: 'Trapped family in ground floor',
        description: 'Water rising up to window sill',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        status: 'ASSIGNED',
        priorityLevel: 'CRITICAL',
        priorityScore: 94.0,
        priorityReasons: const ['Water rising rapidly', 'Non-swimmers present'],
        affectedCount: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hasVulnerabilitySnapshot: true,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            home: EmergencyTrackingScreen(
              emergencyId: 'emg_trk_widget',
              initialData: initialTracking,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Header & ID
      expect(find.text('DRISHTI EMERGENCY TRACKING'), findsOneWidget);
      expect(find.textContaining('emg_trk_widget'), findsOneWidget);
      expect(find.text('RESCUE RESOURCE ASSIGNED'), findsOneWidget);

      // Verify Incident Details
      expect(find.text('Trapped family in ground floor'), findsOneWidget);
      expect(find.text('FLOOD RESCUE'), findsOneWidget);
      expect(find.text('4 person(s)'), findsOneWidget);

      // Verify Priority Evaluation
      expect(find.text('CRITICAL (94.0 pts)'), findsOneWidget);
      expect(find.text('Water rising rapidly'), findsOneWidget);

      // Verify Vulnerability Snapshot Confirmation (Privacy Preserving)
      expect(find.textContaining('VULNERABILITY PROFILE ATTACHED'), findsOneWidget);

      // Verify Progression Timeline
      expect(find.text('Response Progression'), findsOneWidget);
      expect(find.text('Report Created'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // Verify Refresh button presence
      expect(find.byIcon(Icons.refresh_rounded), findsWidgets);
    });

    testWidgets('9. EmergencyTrackingScreen displays truthful LOCAL_PENDING status for offline emergency', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      final offlineTracking = EmergencyTracking(
        id: 'idem_offline_999',
        title: 'Power failure medical equipment',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5062,
        longitude: 80.6480,
        status: 'LOCAL_PENDING',
        affectedCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: 'PENDING_SYNC',
        hasVulnerabilitySnapshot: true,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            home: EmergencyTrackingScreen(
              emergencyId: 'idem_offline_999',
              initialData: offlineTracking,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('SAVED LOCALLY (OFFLINE)'), findsOneWidget);
      expect(find.text('LOCAL QUEUE'), findsOneWidget);
      expect(find.textContaining('SAVED LOCALLY (Offline Queue)'), findsOneWidget);
    });

    testWidgets('10. HomeScreen shows active emergency banner and navigates to tracking screen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();

      // Seed active emergency
      await service.setActiveEmergency({
        'id': 'emg_active_home',
        'title': 'Elderly resident trapped',
        'category': 'FLOOD_RESCUE',
        'status': 'ASSIGNED',
        'sync_status': 'SYNCED',
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Expect Active Emergency card
      expect(find.text('ACTIVE EMERGENCY'), findsOneWidget);
      expect(find.text('Elderly resident trapped'), findsOneWidget);
      expect(find.text('ID: emg_active_home'), findsOneWidget);
      expect(find.text('Track Response'), findsOneWidget);

      // Tap Track Response
      await tester.tap(find.text('Track Response'));
      await tester.pumpAndSettle();

      // Expect navigation to EmergencyTrackingScreen
      expect(find.byType(EmergencyTrackingScreen), findsOneWidget);
    });

    testWidgets('11. EmergencyConfirmationScreen contains TRACK EMERGENCY STATUS button and navigates to tracking', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();

      final submissionResult = {
        'status': 'SUCCESS',
        'sync_status': 'SYNCED',
        'item': {
          'id': 'emg_confirm_track_1',
          'title': 'Rapid flood near bridge',
          'category': 'FLOOD_RESCUE',
          'latitude': 16.5062,
          'longitude': 80.6480,
          'affected_count': 2,
          'priority_level': 'HIGH',
          'priority_score': 82.0,
          'priority_reasons': ['Submerged bridge'],
        },
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            home: EmergencyConfirmationScreen(
              submissionResult: submissionResult,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect Track button
      expect(find.text('TRACK EMERGENCY STATUS'), findsOneWidget);
      expect(find.byIcon(Icons.track_changes_rounded), findsOneWidget);

      // Tap Track Emergency Status
      await tester.ensureVisible(find.text('TRACK EMERGENCY STATUS'));
      await tester.tap(find.text('TRACK EMERGENCY STATUS'));
      await tester.pumpAndSettle();

      // Verify navigated to tracking screen
      expect(find.byType(EmergencyTrackingScreen), findsOneWidget);
    });
  });
}
