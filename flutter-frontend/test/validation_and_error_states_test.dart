import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_response_flutter/models/emergency_report.dart';
import 'package:disaster_response_flutter/models/emergency_tracking.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/screens/emergency_reporting_screen.dart';
import 'package:disaster_response_flutter/screens/emergency_tracking_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T051 — Domain Field-Level Validation Tests', () {
    test('1. Valid emergency report passes all constraints', () {
      final report = EmergencyReport(
        title: 'Trapped on terrace with infant',
        description: 'Water reached 5 feet near temple',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 3,
        createdAt: DateTime.now(),
      );

      final result = report.validateDetailed();
      expect(result.isValid, true);
      expect(result.primaryError, isNull);
      expect(result.fieldErrors.isEmpty, true);
      expect(report.isValid, true);
      expect(report.validate(), isNull);
    });

    test('2. Title constraint validation (empty, < 5 chars, > 150 chars)', () {
      // Empty title
      final emptyTitle = EmergencyReport(
        title: '   ',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      final emptyResult = emptyTitle.validateDetailed();
      expect(emptyResult.isValid, false);
      expect(emptyResult.fieldErrors['title'], contains('title or summary is required'));

      // Too short (< 5 chars)
      final shortTitle = EmergencyReport(
        title: 'Help',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      final shortResult = shortTitle.validateDetailed();
      expect(shortResult.isValid, false);
      expect(shortResult.fieldErrors['title'], contains('at least 5 characters'));

      // Too long (> 150 chars)
      final longTitle = EmergencyReport(
        title: 'A' * 151,
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      final longResult = longTitle.validateDetailed();
      expect(longResult.isValid, false);
      expect(longResult.fieldErrors['title'], contains('cannot exceed 150 characters'));
    });

    test('3. Description length constraint (> 500 chars)', () {
      final longDesc = EmergencyReport(
        title: 'Valid emergency report title',
        description: 'D' * 501,
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      final descResult = longDesc.validateDetailed();
      expect(descResult.isValid, false);
      expect(descResult.fieldErrors['description'], contains('cannot exceed 500 characters'));
    });

    test('4. Category constraint validation (empty or invalid)', () {
      final emptyCat = EmergencyReport(
        title: 'Valid title here',
        category: '',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(emptyCat.validateDetailed().fieldErrors['category'], contains('category must be selected'));

      final invalidCat = EmergencyReport(
        title: 'Valid title here',
        category: 'UNRECOGNIZED_HAZARD',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(invalidCat.validateDetailed().fieldErrors['category'], contains('Invalid emergency category'));
    });

    test('5. Affected count constraint validation (< 1 or > 1000)', () {
      final zeroCount = EmergencyReport(
        title: 'Valid emergency title',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 0,
        createdAt: DateTime.now(),
      );
      expect(zeroCount.validateDetailed().fieldErrors['affected_count'], contains('at least 1 person'));

      final hugeCount = EmergencyReport(
        title: 'Valid emergency title',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1500,
        createdAt: DateTime.now(),
      );
      expect(hugeCount.validateDetailed().fieldErrors['affected_count'], contains('cannot exceed 1000 people'));
    });

    test('6. Coordinate constraints (latitude, longitude, zero coords)', () {
      final outLat = EmergencyReport(
        title: 'Valid emergency title',
        category: 'FLOOD_RESCUE',
        latitude: 95.0,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(outLat.validateDetailed().fieldErrors['latitude'], contains('Invalid latitude'));

      final outLon = EmergencyReport(
        title: 'Valid emergency title',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 195.0,
        createdAt: DateTime.now(),
      );
      expect(outLon.validateDetailed().fieldErrors['longitude'], contains('Invalid longitude'));

      final zeroCoords = EmergencyReport(
        title: 'Valid emergency title',
        category: 'FLOOD_RESCUE',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
      );
      expect(zeroCoords.validateDetailed().fieldErrors['location'], contains('Location cannot be at (0, 0)'));
    });
  });

  group('T051 — Service Submission & Network Error States', () {
    test('7. Client validation error (422) throws and does NOT corrupt local queue', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Validation failed: affected_count must be positive'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () async => await service.submitEmergency(
          title: 'Emergency report title',
          description: '',
          category: 'FLOOD_RESCUE',
          latitude: 16.5062,
          longitude: 80.6480,
          affectedCount: 1,
          client: client,
        ),
        throwsA(predicate((e) => e.toString().contains('Validation Error (422)'))),
      );

      // Local queue must remain empty to avoid syncing corrupt payloads
      expect(service.localQueue.isEmpty, true);
    });

    test('8. Server failure (500) gracefully falls back to local offline queue', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await service.submitEmergency(
        title: 'Emergency during server outage',
        description: 'Server returned 500 error',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
        client: client,
      );

      expect(result['status'], 'SAVED_LOCALLY');
      expect(result['sync_status'], 'PENDING_SYNC');
      expect(result['message'], contains('temporarily unavailable'));
      expect(service.localQueue.length, 1);
      expect(service.localQueue.first['last_sync_error'], contains('500'));
    });

    test('9. SyncPendingQueue tracks lastSyncError on failure and clears on success', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // Seed offline queue
      await service.submitEmergency(
        title: 'Pending rescue incident',
        description: '',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );
      expect(service.localQueue.length, 1);

      // Attempt sync with failing client
      final failingClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      await service.syncPendingQueue(client: failingClient);
      expect(service.localQueue.length, 1);
      expect(service.lastSyncError, contains('503'));

      // Attempt sync with succeeding client
      final successClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'synced_emg_101',
            'title': 'Pending rescue incident',
            'status': 'PENDING',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      await service.syncPendingQueue(client: successClient);
      expect(service.localQueue.isEmpty, true);
      expect(service.lastSyncError, isNull);
    });
  });

  group('T051 — UI Form Validation & Error State Rendering', () {
    testWidgets('10. EmergencyReportingScreen displays inline validation errors and banner', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: const MaterialApp(home: EmergencyReportingScreen()),
        ),
      );
      await tester.pump();

      // Clear the title text field
      final titleField = find.widgetWithText(TextFormField, 'Immediate Flood Rescue Required');
      await tester.enterText(titleField, '   '); // Empty whitespace
      await tester.pump();

      // Tap Transmit SOS
      final submitBtn = find.text('TRANSMIT EMERGENCY REPORT / SOS');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      // Verify inline validation error
      expect(find.text('Emergency title or summary is required.'), findsOneWidget);
      // Verify top validation error alert banner
      expect(find.text('Please fix the highlighted form errors before submitting.'), findsOneWidget);
    });

    testWidgets('11. EmergencyTrackingScreen renders distinct 404 Not Found card', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.online);

      // Client returning 404
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Emergency not found.'}), 404);
      });

      // Pump screen with an ID that doesn't exist and pass mock client
      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            home: EmergencyTrackingScreen(
              emergencyId: 'emg_nonexistent_999',
              client: client,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Emergency Report Not Found (404)'), findsOneWidget);
      expect(find.textContaining('No incident matches ID'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('12. EmergencyTrackingScreen renders offline warning banner when device is offline', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      final tracking = EmergencyTracking(
        id: 'emg_offline_disp',
        title: 'Trapped citizen',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        status: 'ASSIGNED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            home: EmergencyTrackingScreen(
              emergencyId: 'emg_offline_disp',
              initialData: tracking,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Device is currently OFFLINE'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsWidgets);
    });
  });
}
