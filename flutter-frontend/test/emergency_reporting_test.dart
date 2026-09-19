import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/models/emergency_report.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T048 — Emergency Reporting Flow & Model Tests', () {
    test('1. EmergencyReport model serialization and deserialization', () {
      final now = DateTime.now();
      final report = EmergencyReport(
        id: 'emg_test123',
        idempotencyKey: 'key_1234',
        title: 'Trapped in rising flood water',
        description: 'First floor submerged near bus stop',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 4,
        vulnerabilitySnapshot: {
          'age': 68,
          'age_group': 'ELDERLY',
          'can_swim': false,
          'mobility_status': 'LIMITED',
          'medical_conditions': ['Hypertension'],
          'disability_notes': 'Walking assistance needed',
        },
        syncStatus: 'SYNCED',
        createdAt: now,
        priorityScore: 92.0,
        priorityLevel: 'CRITICAL',
        priorityReasons: ['Active flood rescue', 'Elderly non-swimmer in flood zone'],
        vulnerabilityScore: 70.0,
      );

      final localJson = report.toLocalJson();
      expect(localJson['id'], 'emg_test123');
      expect(localJson['title'], 'Trapped in rising flood water');
      expect(localJson['category'], 'FLOOD_RESCUE');
      expect(localJson['latitude'], 16.5062);
      expect(localJson['longitude'], 80.6480);
      expect(localJson['affected_count'], 4);
      expect(localJson['sync_status'], 'SYNCED');
      expect(localJson['priority_level'], 'CRITICAL');
      expect(localJson['priority_score'], 92.0);

      // Deserialization check
      final parsed = EmergencyReport.fromJson(localJson);
      expect(parsed.id, 'emg_test123');
      expect(parsed.title, report.title);
      expect(parsed.category, report.category);
      expect(parsed.latitude, report.latitude);
      expect(parsed.longitude, report.longitude);
      expect(parsed.affectedCount, 4);
      expect(parsed.priorityLevel, 'CRITICAL');
      expect(parsed.vulnerabilitySnapshot!['mobility_status'], 'LIMITED');
    });

    test('2. Required-field and coordinate validation', () {
      // Missing title
      final invalidTitle = EmergencyReport(
        title: '   ',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(invalidTitle.isValid, false);
      expect(invalidTitle.validate(), contains('title or summary is required'));

      // Missing category
      final invalidCategory = EmergencyReport(
        title: 'Valid title',
        category: '',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(invalidCategory.isValid, false);
      expect(invalidCategory.validate(), contains('category must be selected'));

      // Invalid latitude (> 90)
      final invalidLat = EmergencyReport(
        title: 'Valid title',
        category: 'FLOOD_RESCUE',
        latitude: 95.0,
        longitude: 80.6480,
        createdAt: DateTime.now(),
      );
      expect(invalidLat.isValid, false);
      expect(invalidLat.validate(), contains('Invalid latitude'));

      // Invalid (0,0) coordinate
      final zeroCoords = EmergencyReport(
        title: 'Valid title',
        category: 'FLOOD_RESCUE',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
      );
      expect(zeroCoords.isValid, false);
      expect(zeroCoords.validate(), contains('(0, 0)'));

      // Invalid affected count
      final invalidCount = EmergencyReport(
        title: 'Valid title',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 0,
        createdAt: DateTime.now(),
      );
      expect(invalidCount.isValid, false);
      expect(invalidCount.validate(), contains('at least 1 person'));

      // Valid report
      final validReport = EmergencyReport(
        title: 'Water rising at door',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
        createdAt: DateTime.now(),
      );
      expect(validReport.isValid, true);
      expect(validReport.validate(), isNull);
    });

    test('3. Backend EmergencyCreate payload structure matches contract', () {
      final report = EmergencyReport(
        idempotencyKey: 'idempotency_uuid_789',
        title: 'Submerged ground floor',
        description: 'Need boat extraction',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 3,
        vulnerabilitySnapshot: {
          'age': 75,
          'age_group': 'ELDERLY',
          'can_swim': false,
          'mobility_status': 'WHEELCHAIR',
          'medical_conditions': ['Asthma / Respiratory'],
          'disability_notes': null,
        },
        createdAt: DateTime.now(),
      );

      final payload = report.toBackendPayload();

      // Verify exact keys expected by FastAPI EmergencyCreate schema
      expect(payload['idempotency_key'], 'idempotency_uuid_789');
      expect(payload['title'], 'Submerged ground floor');
      expect(payload['description'], 'Need boat extraction');
      expect(payload['category'], 'FLOOD_RESCUE');
      expect(payload['latitude'], 16.5062);
      expect(payload['longitude'], 80.6480);
      expect(payload['affected_count'], 3);
      expect(payload.containsKey('vulnerability_snapshot'), true);
      expect(payload['vulnerability_snapshot']['mobility_status'], 'WHEELCHAIR');
    });

    test('4. LocationService acquisition and coordinate validity', () async {
      final location = await LocationService.acquireCoordinates();
      expect(location.isValid, true);
      expect(location.latitude, closeTo(16.5062, 0.001));
      expect(location.longitude, closeTo(80.6480, 0.001));
      expect(location.status, LocationCaptureStatus.acquired);

      final failedLoc = await LocationService.acquireCoordinates(forceFail: true);
      expect(failedLoc.isValid, false);
      expect(failedLoc.status, LocationCaptureStatus.failed);
      expect(failedLoc.errorMessage, isNotNull);
    });

    test('5. Emergency reporting flow attaches immutable snapshot from active profile', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // Save a custom vulnerability profile
      const activeProfile = VulnerabilityProfile(
        age: 82,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'BEDRIDDEN',
        medicalConditions: ['Oxygen Dependent', 'Cardiac Condition'],
        disabilityNotes: 'Patient is on ventilator/power backup needed',
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(activeProfile);

      // Submit emergency
      final result = await service.submitEmergency(
        title: 'Critical power failure for life support',
        description: 'Water entering ground floor generator room',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      expect(result['status'], 'SAVED_LOCALLY');
      expect(result['sync_status'], 'PENDING_SYNC');

      final item = result['item'] as Map<String, dynamic>;
      final snapshot = item['vulnerability_snapshot'] as Map<String, dynamic>;

      expect(snapshot['age'], 82);
      expect(snapshot['age_group'], 'ELDERLY');
      expect(snapshot['can_swim'], false);
      expect(snapshot['mobility_status'], 'BEDRIDDEN');
      expect(snapshot['medical_conditions'], contains('Oxygen Dependent'));
      expect(snapshot['disability_notes'], contains('ventilator'));
    });

    test('6. Regression: Profile update does NOT alter snapshot of existing report', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // 1. Citizen creates profile A (Elderly non-swimmer)
      const profileA = VulnerabilityProfile(
        age: 77,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['Hypertension'],
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profileA);

      // 2. Submit Emergency E1
      final res1 = await service.submitEmergency(
        title: 'Emergency E1 - Wheelchair rescue needed',
        description: 'Water at 2 feet',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );
      final e1 = res1['item'] as Map<String, dynamic>;
      expect(e1['vulnerability_snapshot']['age'], 77);
      expect(e1['vulnerability_snapshot']['mobility_status'], 'WHEELCHAIR');

      // 3. User modifies profile to Profile B (Adult, fully mobile)
      const profileB = VulnerabilityProfile(
        age: 26,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profileB);

      // 4. Verify original queued emergency E1 still has Snapshot A!
      final queuedE1 = service.localQueue.first;
      expect(queuedE1['vulnerability_snapshot']['age'], 77);
      expect(queuedE1['vulnerability_snapshot']['mobility_status'], 'WHEELCHAIR');
      expect(queuedE1['vulnerability_snapshot']['can_swim'], false);

      // 5. Current profile in service is indeed Profile B
      expect(service.vulnerabilityProfile.age, 26);
      expect(service.vulnerabilityProfile.mobilityStatus, 'FULL');
    });

    test('7. Offline emergency report persistence and queue retention', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      await service.submitEmergency(
        title: 'Evacuation required',
        description: 'Sector A road cut off',
        category: 'SHELTER_EVACUATION',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 5,
      );

      expect(service.localQueue.length, 1);
      final report = service.localQueue.first;
      expect(report['sync_status'], 'PENDING_SYNC');
      expect(report['category'], 'SHELTER_EVACUATION');
      expect(report['affected_count'], 5);

      // Verify SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString('pending_queue');
      expect(queueStr, isNotNull);
      expect(queueStr, contains('SHELTER_EVACUATION'));
    });
  });
}
