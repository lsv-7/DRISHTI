import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_response_flutter/database/app_database.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';
import 'package:disaster_response_flutter/models/emergency_report.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';

void main() {
  group('T053 — LocalEmergencyRepository Unit Tests', () {
    late AppDatabase db;
    late LocalEmergencyRepository repository;

    setUp(() {
      // In-memory isolated SQLite database for hermetic testing
      db = AppDatabase(NativeDatabase.memory());
      repository = LocalEmergencyRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Save emergency through repository returns persistent EmergencyEntry', () async {
      final now = DateTime.now().toUtc();
      final report = EmergencyReport(
        idempotencyKey: 'idemp-t053-1',
        title: 'Elderly rescue from rising water',
        description: 'Water at waist level in ground floor',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 2,
        createdAt: now,
        syncStatus: 'LOCAL_PENDING',
        vulnerabilitySnapshot: const {
          'mobility_status': 'WHEELCHAIR',
          'age': 76,
          'elderly_count': 1,
        },
      );

      final entry = await repository.saveEmergency(report);

      expect(entry.localId, equals(1));
      expect(entry.idempotencyKey, equals('idemp-t053-1'));
      expect(entry.title, equals('Elderly rescue from rising water'));
      expect(entry.category, equals('FLOOD_RESCUE'));
      expect(entry.affectedCount, equals(2));
      expect(entry.syncStatus, equals('LOCAL_PENDING'));
      expect(entry.status, equals('LOCAL_PENDING'));
      expect(entry.vulnerabilitySnapshot, isNotNull);
    });

    test('2. Retrieve emergency by localId returns matching record', () async {
      final now = DateTime.now().toUtc();
      final report = EmergencyReport(
        idempotencyKey: 'idemp-t053-2',
        title: 'Trapped on terrace',
        category: 'TRAPPED_CITIZENS',
        latitude: 16.5033,
        longitude: 80.6465,
        createdAt: now,
      );

      final saved = await repository.saveEmergency(report);
      final fetched = await repository.getEmergencyByLocalId(saved.localId);

      expect(fetched, isNotNull);
      expect(fetched!.localId, equals(saved.localId));
      expect(fetched.title, equals('Trapped on terrace'));
    });

    test('3. Retrieve emergency by authoritative server ID', () async {
      final now = DateTime.now().toUtc();
      final saved = await repository.saveEmergencyMap({
        'id': 'emg_srv_1001',
        'idempotency_key': 'idemp-server-1',
        'title': 'Medical evacuation required',
        'category': 'MEDICAL_EMERGENCY',
        'latitude': 16.5075,
        'longitude': 80.6055,
        'created_at': now.toIso8601String(),
        'sync_status': 'SYNCED',
        'status': 'PENDING',
      });

      final fetched = await repository.getEmergencyByServerId('emg_srv_1001');

      expect(fetched, isNotNull);
      expect(fetched!.localId, equals(saved.localId));
      expect(fetched.id, equals('emg_srv_1001'));
      expect(fetched.syncStatus, equals('SYNCED'));
    });

    test('4. Retrieve emergency by unique idempotencyKey', () async {
      final now = DateTime.now().toUtc();
      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'idemp-lookup-unique',
        title: 'Relief kit request',
        category: 'RELIEF_SUPPLY',
        latitude: 16.5200,
        longitude: 80.6700,
        createdAt: now,
      ));

      final found = await repository.getEmergencyByIdempotencyKey('idemp-lookup-unique');
      expect(found, isNotNull);
      expect(found!.title, equals('Relief kit request'));

      final notFound = await repository.getEmergencyByIdempotencyKey('non-existent-key');
      expect(notFound, isNull);
    });

    test('5. Polymorphic getEmergencyById finds by server ID, idempotency key, and local ID', () async {
      final now = DateTime.now().toUtc();
      final saved = await repository.saveEmergencyMap({
        'id': 'emg_poly_99',
        'idempotency_key': 'key_poly_99',
        'title': 'Shelter evacuation',
        'category': 'SHELTER_EVACUATION',
        'latitude': 16.5180,
        'longitude': 80.6020,
        'created_at': now.toIso8601String(),
      });

      // Lookup by server ID
      final byServer = await repository.getEmergencyById('emg_poly_99');
      expect(byServer, isNotNull);
      expect(byServer!.localId, equals(saved.localId));

      // Lookup by idempotency key
      final byKey = await repository.getEmergencyById('key_poly_99');
      expect(byKey, isNotNull);
      expect(byKey!.localId, equals(saved.localId));

      // Lookup by numeric local ID string
      final byLocal = await repository.getEmergencyById(saved.localId.toString());
      expect(byLocal, isNotNull);
      expect(byLocal!.idempotencyKey, equals('key_poly_99'));

      // Unknown lookup returns null
      final unknown = await repository.getEmergencyById('unknown_xyz');
      expect(unknown, isNull);
    });

    test('6. Retrieve all emergencies in reverse chronological order', () async {
      final t1 = DateTime.utc(2026, 9, 19, 8, 0);
      final t2 = DateTime.utc(2026, 9, 19, 8, 20);
      final t3 = DateTime.utc(2026, 9, 19, 8, 40);

      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'time-1',
        title: 'Report 1',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t1,
      ));

      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'time-3',
        title: 'Report 3',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t3,
      ));

      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'time-2',
        title: 'Report 2',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t2,
      ));

      final all = await repository.getAllEmergencies();
      expect(all.length, equals(3));
      expect(all[0].idempotencyKey, equals('time-3'));
      expect(all[1].idempotencyKey, equals('time-2'));
      expect(all[2].idempotencyKey, equals('time-1'));
    });

    test('7. watchAllEmergencies emits reactive stream updates', () async {
      final now = DateTime.now().toUtc();
      final stream = repository.watchAllEmergencies();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
          hasLength(2),
          hasLength(1),
        ]),
      );

      await pumpEventQueue();

      final entry1 = await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'stream-r-1',
        title: 'Stream Report 1',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
      ));

      await pumpEventQueue();

      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'stream-r-2',
        title: 'Stream Report 2',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now.add(const Duration(seconds: 1)),
      ));

      await pumpEventQueue();

      await repository.deleteEmergency(entry1.localId);

      await expectation;
    });

    test('8. Update emergency status and priority without snapshot mutation', () async {
      final now = DateTime.now().toUtc();
      final snap = {'mobility_status': 'BEDRIDDEN', 'age': 84};

      final saved = await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'update-priority-test',
        title: 'Bedridden citizen needs rescue boat',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: now,
        vulnerabilitySnapshot: snap,
      ));

      final updatedCount = await repository.updateEmergencyStatus(
        localId: saved.localId,
        status: 'ASSIGNED',
        syncStatus: 'SYNCED',
        serverId: 'emg_srv_assigned_77',
        priorityScore: 94.0,
        priorityLevel: 'CRITICAL',
        priorityReasons: ['Bedridden patient requiring evacuation raft', 'Water height 1.5m'],
        vulnerabilityScore: 38.0,
      );

      expect(updatedCount, equals(1));

      final updated = await repository.getEmergencyByLocalId(saved.localId);
      expect(updated, isNotNull);
      expect(updated!.status, equals('ASSIGNED'));
      expect(updated.syncStatus, equals('SYNCED'));
      expect(updated.id, equals('emg_srv_assigned_77'));
      expect(updated.priorityScore, equals(94.0));
      expect(updated.priorityLevel, equals('CRITICAL'));
      expect(updated.vulnerabilityScore, equals(38.0));

      // CRITICAL: Verify vulnerability snapshot is 100% preserved
      expect(jsonDecode(updated.vulnerabilitySnapshot!), equals(snap));
    });

    test('9. Delete emergency by localId and clearAllEmergencies', () async {
      final now = DateTime.now().toUtc();
      final entry = await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'to-delete-repo',
        title: 'Duplicate click report',
        category: 'OTHER',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
      ));

      expect(await repository.getEmergencyByLocalId(entry.localId), isNotNull);

      final count = await repository.deleteEmergency(entry.localId);
      expect(count, equals(1));
      expect(await repository.getEmergencyByLocalId(entry.localId), isNull);

      // Clear all
      await repository.saveEmergency(EmergencyReport(
        idempotencyKey: 'clear-1',
        title: 'Report 1',
        category: 'OTHER',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
      ));
      expect((await repository.getAllEmergencies()).length, equals(1));

      await repository.clearAllEmergencies();
      expect(await repository.getAllEmergencies(), isEmpty);
    });

    test('10. Duplicate idempotencyKey handled idempotently without duplicate rows or errors', () async {
      final now = DateTime.now().toUtc();
      final report1 = EmergencyReport(
        idempotencyKey: 'idemp-retry-safe',
        title: 'First submission attempt',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: now,
      );

      final firstSaved = await repository.saveEmergency(report1);

      // Subsequent attempt with identical idempotencyKey (network retry simulation)
      final report2 = EmergencyReport(
        idempotencyKey: 'idemp-retry-safe',
        title: 'Duplicate submission attempt',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: now,
      );

      final secondSaved = await repository.saveEmergency(report2);

      // Verify same localId returned
      expect(secondSaved.localId, equals(firstSaved.localId));
      expect(secondSaved.idempotencyKey, equals('idemp-retry-safe'));

      // Verify no duplicate row was created in SQLite
      final all = await repository.getAllEmergencies();
      expect(all.length, equals(1));
    });

    test('11. Vulnerability snapshot immutability: external profile changes do not alter saved snapshot', () async {
      final now = DateTime.now().toUtc();

      const profile = VulnerabilityProfile(
        age: 72,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['DIABETES', 'HYPERTENSION'],
        disabilityNotes: 'Requires ramp',
        status: ProfileStatus.completed,
      );

      final report = EmergencyReport(
        idempotencyKey: 'vuln-immutability-check',
        title: 'Rescue flood emergency with profile snapshot',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        createdAt: now,
        vulnerabilitySnapshot: profile.toSnapshot(),
      );

      final saved = await repository.saveEmergency(report);

      // Mutate profile representation externally
      const changedProfile = VulnerabilityProfile(
        age: 22,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        disabilityNotes: null,
        status: ProfileStatus.completed,
      );
      expect(changedProfile.mobilityStatus, equals('FULL'));

      // Retrieve emergency from repository
      final fetched = await repository.getEmergencyByLocalId(saved.localId);
      final decodedSnap = jsonDecode(fetched!.vulnerabilitySnapshot!) as Map<String, dynamic>;

      expect(decodedSnap['mobility_status'], equals('WHEELCHAIR'),
          reason: 'Vulnerability snapshot in local repository must remain immutable');
      expect(decodedSnap['age'], equals(72));
      expect(decodedSnap['medical_conditions'], containsAll(['DIABETES', 'HYPERTENSION']));
    });

    test('12. Domain mapping extensions (toReport and toTracking) round-trip correctly', () async {
      final now = DateTime.now().toUtc();
      final report = EmergencyReport(
        id: 'emg_roundtrip_1',
        idempotencyKey: 'idemp-roundtrip',
        title: 'Trapped on first floor',
        description: 'Flood water depth 1.2m',
        category: 'TRAPPED_CITIZENS',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 3,
        createdAt: now,
        syncStatus: 'SYNCED',
        priorityScore: 85.0,
        priorityLevel: 'HIGH',
        priorityReasons: const ['Fast current', 'Elderly resident'],
        vulnerabilityScore: 25.0,
        vulnerabilitySnapshot: const {'mobility_status': 'LIMITED'},
      );

      final saved = await repository.saveEmergency(report);

      // Test toReport()
      final domainReport = saved.toReport();
      expect(domainReport.id, equals('emg_roundtrip_1'));
      expect(domainReport.idempotencyKey, equals('idemp-roundtrip'));
      expect(domainReport.title, equals('Trapped on first floor'));
      expect(domainReport.description, equals('Flood water depth 1.2m'));
      expect(domainReport.category, equals('TRAPPED_CITIZENS'));
      expect(domainReport.latitude, equals(16.5062));
      expect(domainReport.longitude, equals(80.6480));
      expect(domainReport.affectedCount, equals(3));
      expect(domainReport.priorityScore, equals(85.0));
      expect(domainReport.priorityLevel, equals('HIGH'));
      expect(domainReport.priorityReasons, containsAll(['Fast current', 'Elderly resident']));
      expect(domainReport.vulnerabilityScore, equals(25.0));
      expect(domainReport.vulnerabilitySnapshot!['mobility_status'], equals('LIMITED'));

      // Test toTracking()
      final tracking = saved.toTracking();
      expect(tracking.id, equals('emg_roundtrip_1'));
      expect(tracking.title, equals('Trapped on first floor'));
      expect(tracking.priorityScore, equals(85.0));
      expect(tracking.priorityLevel, equals('HIGH'));
      expect(tracking.priorityReasons, containsAll(['Fast current', 'Elderly resident']));
      expect(tracking.vulnerabilityFactors!['mobility_status'], equals('LIMITED'));
      expect(tracking.hasVulnerabilitySnapshot, isTrue);
    });

    test('13. OfflineService integration: emergency submissions persist through repository', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService(repository: repository);
      await service.ensureInitialized();

      service.setConnectivity(ConnectivityState.offline);

      // Submit emergency while offline
      final result = await service.submitEmergency(
        title: 'Offline emergency via service',
        description: 'Power cut in Sector B',
        category: 'FLOOD_RESCUE',
        latitude: 16.5075,
        longitude: 80.6055,
        affectedCount: 2,
      );

      expect(result['status'], equals('SAVED_LOCALLY'));
      final payload = result['item'] as Map<String, dynamic>;
      final idempotencyKey = payload['idempotency_key'] as String;

      // Verify that the emergency was persisted into SQLite via LocalEmergencyRepository
      final savedInRepo = await repository.getEmergencyByIdempotencyKey(idempotencyKey);
      expect(savedInRepo, isNotNull);
      expect(savedInRepo!.title, equals('Offline emergency via service'));
      expect(savedInRepo.category, equals('FLOOD_RESCUE'));
      expect(savedInRepo.status, equals('LOCAL_PENDING'));
      expect(savedInRepo.syncStatus, equals('PENDING_SYNC'));

      // Verify fetchEmergencyTracking retrieves directly from repository when offline
      final tracking = await service.fetchEmergencyTracking(idempotencyKey);
      expect(tracking.title, equals('Offline emergency via service'));
      expect(tracking.isLocalPending, isTrue);
    });

    test('14. OfflineService integration: online submission persists SYNCED emergency to repository', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OfflineService(repository: repository);
      await service.ensureInitialized();

      service.setConnectivity(ConnectivityState.online);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/emergencies') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'emg_online_success_1',
              'idempotency_key': body['idempotency_key'],
              'title': body['title'],
              'category': body['category'],
              'latitude': body['latitude'],
              'longitude': body['longitude'],
              'affected_count': body['affected_count'],
              'status': 'PENDING',
              'priority_score': 88.0,
              'priority_level': 'HIGH',
              'vulnerability_score': 30.0,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await service.submitEmergency(
        title: 'Online emergency submission',
        description: 'Water entering house',
        category: 'FLOOD_RESCUE',
        latitude: 16.5062,
        longitude: 80.6480,
        affectedCount: 1,
        client: mockClient,
      );

      expect(result['status'], equals('SUCCESS'));
      expect(result['item'], isNotNull);

      // Verify that repository has the SYNCED record
      final repoRecord = await repository.getEmergencyByServerId('emg_online_success_1');
      expect(repoRecord, isNotNull);
      expect(repoRecord!.title, equals('Online emergency submission'));
      expect(repoRecord.syncStatus, equals('SYNCED'));
      expect(repoRecord.priorityScore, equals(88.0));
      expect(repoRecord.priorityLevel, equals('HIGH'));
    });
  });
}
