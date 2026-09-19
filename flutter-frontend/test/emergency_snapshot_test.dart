import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency Vulnerability Snapshot & Immutability Tests (T043)', () {
    test('5. Emergency payload contains vulnerability_snapshot matching schema', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      const profile = VulnerabilityProfile(
        age: 65,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['Hypertension'],
        disabilityNotes: 'Wheelchair dependent',
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profile);

      final result = await service.submitEmergency(
        title: 'Trapped in rising flood water',
        description: 'First floor submerged, urgent boat needed',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 3,
      );

      expect(result['status'], 'SAVED_LOCALLY');
      expect(result['sync_status'], 'PENDING_SYNC');

      final item = result['item'] as Map<String, dynamic>;
      expect(item.containsKey('vulnerability_snapshot'), true);

      final snapshot = item['vulnerability_snapshot'] as Map<String, dynamic>;
      expect(snapshot['age'], 65);
      expect(snapshot['age_group'], 'ELDERLY');
      expect(snapshot['can_swim'], false);
      expect(snapshot['mobility_status'], 'WHEELCHAIR');
      expect(snapshot['medical_conditions'], ['Hypertension']);
      expect(snapshot['disability_notes'], 'Wheelchair dependent');
    });

    test('6. CRITICAL: Snapshot Immutability (Profile A -> Emergency -> Profile B -> Snapshot still A)', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // STEP 1: Set Profile A (Elderly, cannot swim, limited mobility)
      const profileA = VulnerabilityProfile(
        age: 70,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'LIMITED',
        medicalConditions: ['Cardiac Condition'],
        disabilityNotes: 'Walks with assistance',
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profileA);

      // STEP 2: Create Emergency E1 under Profile A
      final resA = await service.submitEmergency(
        title: 'Emergency E1 - House surrounded by water',
        description: 'Water at doorstep',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
      );
      final emergencyPayloadA = resA['item'] as Map<String, dynamic>;
      final snapshotA = emergencyPayloadA['vulnerability_snapshot'] as Map<String, dynamic>;

      expect(snapshotA['age'], 70);
      expect(snapshotA['can_swim'], false);
      expect(snapshotA['mobility_status'], 'LIMITED');

      // STEP 3: User edits profile to Profile B (Adult, fully mobile, can swim)
      const profileB = VulnerabilityProfile(
        age: 28,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        disabilityNotes: null,
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profileB);

      // Verify current profile is now Profile B
      expect(service.vulnerabilityProfile.age, 28);
      expect(service.vulnerabilityProfile.canSwim, true);
      expect(service.vulnerabilityProfile.mobilityStatus, 'FULL');

      // STEP 4: VERIFY Historical Emergency E1 SNAPSHOT MUST STILL EQUAL PROFILE A!
      // Check from in-memory queue
      final queuedEmergencyE1 = service.localQueue.first;
      final e1Snapshot = queuedEmergencyE1['vulnerability_snapshot'] as Map<String, dynamic>;

      expect(e1Snapshot['age'], 70);
      expect(e1Snapshot['age_group'], 'ELDERLY');
      expect(e1Snapshot['can_swim'], false);
      expect(e1Snapshot['mobility_status'], 'LIMITED');
      expect(e1Snapshot['medical_conditions'], ['Cardiac Condition']);
      expect(e1Snapshot['disability_notes'], 'Walks with assistance');

      // STEP 5: Create Emergency E2 under Profile B
      final resB = await service.submitEmergency(
        title: 'Emergency E2 - Assisting neighbor',
        description: 'Need sandbags',
        category: 'RELIEF_SUPPLY',
        latitude: 16.5100,
        longitude: 80.6500,
        affectedCount: 1,
      );
      final emergencyPayloadB = resB['item'] as Map<String, dynamic>;
      final snapshotB = emergencyPayloadB['vulnerability_snapshot'] as Map<String, dynamic>;

      // Verify E2 has Profile B snapshot
      expect(snapshotB['age'], 28);
      expect(snapshotB['can_swim'], true);
      expect(snapshotB['mobility_status'], 'FULL');

      // And E1 STILL has Profile A snapshot!
      final e1StillInQueue = service.localQueue.first;
      expect(e1StillInQueue['vulnerability_snapshot']['age'], 70);
      expect(e1StillInQueue['vulnerability_snapshot']['can_swim'], false);
    });

    test('7. Offline queue snapshot retention in persistent storage', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      const profile = VulnerabilityProfile(
        age: 80,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'BEDRIDDEN',
        medicalConditions: ['Oxygen Dependent'],
        disabilityNotes: 'Requires continuous medical power',
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(profile);

      await service.submitEmergency(
        title: 'Power cut, oxygen concentrator failing',
        description: 'Critical life support emergency',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      // Verify persistent storage retains the exact snapshot
      final prefs = await SharedPreferences.getInstance();
      final queueStr = prefs.getString('pending_queue');
      expect(queueStr, isNotNull);

      final decodedQueue = List<Map<String, dynamic>>.from(jsonDecode(queueStr!));
      expect(decodedQueue.length, 1);

      final persistedItem = decodedQueue.first;
      final persistedSnapshot = persistedItem['vulnerability_snapshot'] as Map<String, dynamic>;

      expect(persistedSnapshot['mobility_status'], 'BEDRIDDEN');
      expect(persistedSnapshot['can_swim'], false);
      expect(persistedSnapshot['medical_conditions'], ['Oxygen Dependent']);
      expect(persistedItem['sync_status'], 'PENDING_SYNC');
    });

    test('8. Offline -> Queue -> Profile Change -> Sync preserves original snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService();
      service.setConnectivity(ConnectivityState.offline);

      // 1. Initial Profile (Elderly non-swimmer)
      const initialProfile = VulnerabilityProfile(
        age: 78,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['Hypertension'],
        disabilityNotes: 'Wheelchair bound',
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(initialProfile);

      // 2. Submit emergency while offline
      await service.submitEmergency(
        title: 'Trapped during flood',
        description: 'Need evacuation',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
      );

      expect(service.localQueue.length, 1);
      final originalSnapshot = service.localQueue.first['vulnerability_snapshot'];
      expect(originalSnapshot['age'], 78);
      expect(originalSnapshot['can_swim'], false);

      // 3. Profile changes subsequently
      const updatedProfile = VulnerabilityProfile(
        age: 30,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        disabilityNotes: null,
        status: ProfileStatus.completed,
      );
      await service.saveVulnerabilityProfile(updatedProfile);

      // 4. Queue item payload for sync MUST STILL hold original snapshot
      final queuedItem = service.localQueue.first;
      expect(queuedItem['vulnerability_snapshot']['age'], 78);
      expect(queuedItem['vulnerability_snapshot']['can_swim'], false);
      expect(queuedItem['vulnerability_snapshot']['mobility_status'], 'WHEELCHAIR');
      expect(service.vulnerabilityProfile.age, 30); // Current profile is updated, but queue is unchanged!
    });
  });
}
