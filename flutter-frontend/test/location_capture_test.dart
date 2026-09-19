import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/services/location_service.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/models/emergency_report.dart';
import 'package:disaster_response_flutter/screens/emergency_reporting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T049 — Location Capture & Validation Tests', () {
    test('1. GPS acquisition returns valid Vijayawada operational coordinates', () async {
      final result = await LocationService.acquireCoordinates(simulateDelay: false);

      expect(result.isValid, true);
      expect(result.status, LocationCaptureStatus.acquired);
      expect(result.source, LocationSource.gps);
      expect(result.sourceBadge, 'GPS LOCKED');
      expect(result.sourceDescription, 'Device GPS Lock');
      expect(result.latitude, closeTo(16.5062, 0.001));
      expect(result.longitude, closeTo(80.6480, 0.001));
      expect(result.accuracyMeters, 5.0);
      expect(result.accuracy, '±5.0m');
      expect(result.permissionState, LocationPermissionState.granted);
      expect(result.hardwareState, GpsHardwareState.enabled);
    });

    test('2. Permission denied produces LocationPermissionState.denied', () async {
      final result = await LocationService.acquireCoordinates(
        mockPermission: LocationPermissionState.denied,
        simulateDelay: false,
      );

      expect(result.isValid, false);
      expect(result.status, LocationCaptureStatus.failed);
      expect(result.permissionState, LocationPermissionState.denied);
      expect(result.errorMessage, contains('permission denied'));
    });

    test('3. Permanently denied state is handled', () async {
      final result = await LocationService.acquireCoordinates(
        mockPermission: LocationPermissionState.permanentlyDenied,
        simulateDelay: false,
      );

      expect(result.isValid, false);
      expect(result.status, LocationCaptureStatus.failed);
      expect(result.permissionState, LocationPermissionState.permanentlyDenied);
      expect(result.errorMessage, contains('permanently denied'));
    });

    test('4. GPS disabled produces GpsHardwareState.disabled', () async {
      final result = await LocationService.acquireCoordinates(
        mockHardware: GpsHardwareState.disabled,
        simulateDelay: false,
      );

      expect(result.isValid, false);
      expect(result.status, LocationCaptureStatus.failed);
      expect(result.hardwareState, GpsHardwareState.disabled);
      expect(result.errorMessage, contains('GPS/Location services are turned off'));
    });

    test('5. forceFail produces deterministic acquisition failure', () async {
      final result = await LocationService.acquireCoordinates(
        forceFail: true,
        simulateDelay: false,
      );

      expect(result.isValid, false);
      expect(result.status, LocationCaptureStatus.failed);
      expect(result.errorMessage, contains('Signal unavailable'));
    });

    test('6. Retry successfully recovers from acquisition failure', () async {
      // Step 1: Initial failure
      final attempt1 = await LocationService.acquireCoordinates(
        forceFail: true,
        simulateDelay: false,
      );
      expect(attempt1.isValid, false);
      expect(attempt1.status, LocationCaptureStatus.failed);

      // Step 2: Retry with recovery
      final attempt2 = await LocationService.acquireCoordinates(
        forceFail: false,
        simulateDelay: false,
      );
      expect(attempt2.isValid, true);
      expect(attempt2.status, LocationCaptureStatus.acquired);
      expect(attempt2.latitude, closeTo(16.5062, 0.001));
      expect(attempt2.longitude, closeTo(80.6480, 0.001));
    });

    test('7. All 5 Vijayawada disaster sectors work with fromSector()', () {
      const sectors = LocationService.vijayawadaDisasterSectors;
      expect(sectors.length, 5);

      for (var sec in sectors) {
        final res = LocationResult.fromSector(
          sectorName: sec['name'] as String,
          lat: sec['latitude'] as double,
          lon: sec['longitude'] as double,
        );

        expect(res.isValid, true);
        expect(res.status, LocationCaptureStatus.acquired);
        expect(res.source, LocationSource.disasterSector);
        expect(res.sourceBadge, 'SECTOR FALLBACK');
        expect(res.sourceDescription, 'Operational Disaster Sector Fallback');
        expect(res.label, sec['name']);
        expect(res.accuracyMeters, 25.0);
        expect(res.latitude, sec['latitude']);
        expect(res.longitude, sec['longitude']);
      }
    });

    test('8. All 5 sectors work with selectSector()', () {
      for (int i = 0; i < 5; i++) {
        final res = LocationService.selectSector(i);
        expect(res.isValid, true);
        expect(res.status, LocationCaptureStatus.acquired);
        expect(res.source, LocationSource.disasterSector);
        expect(res.sourceBadge, 'SECTOR FALLBACK');
        expect(res.latitude, LocationService.vijayawadaDisasterSectors[i]['latitude']);
        expect(res.longitude, LocationService.vijayawadaDisasterSectors[i]['longitude']);
      }

      // Out of bounds falls back gracefully
      final outOfBounds = LocationService.selectSector(-1);
      expect(outOfBounds.isValid, true);
      expect(outOfBounds.source, LocationSource.disasterSector);
    });

    test('9. Latitude bounds are enforced', () {
      final validReport = EmergencyReport(
        title: 'Valid Lat',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(validReport.validate(), isNull);

      final overLat = EmergencyReport(
        title: 'Too High Lat',
        category: 'FLOOD_RESCUE',
        latitude: 91.0,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(overLat.isValid, false);
      expect(overLat.validate(), contains('Invalid latitude'));

      final underLat = EmergencyReport(
        title: 'Too Low Lat',
        category: 'FLOOD_RESCUE',
        latitude: -90.5,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(underLat.isValid, false);
      expect(underLat.validate(), contains('Invalid latitude'));
    });

    test('10. Longitude bounds are enforced', () {
      final overLon = EmergencyReport(
        title: 'Too High Lon',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 181.0,
        createdAt: DateTime.now(),
      );
      expect(overLon.isValid, false);
      expect(overLon.validate(), contains('Invalid longitude'));

      final underLon = EmergencyReport(
        title: 'Too Low Lon',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: -180.1,
        createdAt: DateTime.now(),
      );
      expect(underLon.isValid, false);
      expect(underLon.validate(), contains('Invalid longitude'));
    });

    test('11. 0,0 is rejected', () {
      final zeroReport = EmergencyReport(
        title: 'Zero Island',
        category: 'FLOOD_RESCUE',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
      );
      expect(zeroReport.isValid, false);
      expect(zeroReport.validate(), contains('cannot be at (0, 0)'));

      final zeroLoc = LocationResult(
        latitude: 0.0,
        longitude: 0.0,
        label: 'Zero',
        timestamp: DateTime.now(),
      );
      expect(zeroLoc.isValid, false);
    });

    test('12. Emergency form cannot submit with invalid/missing location', () {
      final invalidReport = EmergencyReport(
        title: 'Emergency without location',
        category: 'FLOOD_RESCUE',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
      );
      expect(invalidReport.isValid, false);
      expect(invalidReport.validate(), isNotNull);
    });

    test('13. Valid sector fallback can be submitted', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // User selects Sector C (MG Road & Governorpet)
      final sectorC = LocationService.selectSector(2);
      expect(sectorC.label, contains('MG Road & Governorpet'));

      final result = await service.submitEmergency(
        title: 'Governorpet commercial block flooding',
        description: 'Water level rising near hospital feeder road',
        category: 'FLOOD_RESCUE',
        latitude: sectorC.latitude,
        longitude: sectorC.longitude,
        affectedCount: 6,
      );

      expect(result['status'], 'SAVED_LOCALLY');
      final item = result['item'] as Map<String, dynamic>;
      expect(item['latitude'], sectorC.latitude);
      expect(item['longitude'], sectorC.longitude);
      expect(item['affected_count'], 6);
    });

    testWidgets('14. UI Interaction: Choose Sector modal updates location and enables submission', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final offlineService = OfflineService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OfflineService>.value(
            value: offlineService,
            child: const EmergencyReportingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify incident location section
      expect(find.text('3. Incident Location'), findsOneWidget);
      expect(find.text('Refresh GPS'), findsOneWidget);
      expect(find.text('Choose Sector'), findsOneWidget);

      // Open Choose Sector modal
      await tester.tap(find.text('Choose Sector'));
      await tester.pumpAndSettle();

      expect(find.text('Select Operational Sector'), findsOneWidget);
      final sectorBFinder = find.textContaining('Sector B — Prakasam Barrage Southern Bank');
      expect(sectorBFinder, findsOneWidget);

      // Select Sector B
      await tester.tap(sectorBFinder);
      await tester.pumpAndSettle();

      // Modal closed, location updated to Sector B coordinates
      expect(find.text('Select Operational Sector'), findsNothing);
      expect(find.textContaining('16.5075° N'), findsOneWidget);
      expect(find.textContaining('80.6055° E'), findsOneWidget);
      expect(find.text('SECTOR FALLBACK'), findsOneWidget);

      // Submit button is active
      expect(find.text('TRANSMIT EMERGENCY REPORT / SOS'), findsOneWidget);
    });
  });
}
