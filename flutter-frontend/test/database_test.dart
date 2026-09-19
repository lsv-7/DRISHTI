import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:disaster_response_flutter/database/app_database.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';

void main() {
  group('T052 — Drift/SQLite AppDatabase Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      // Use hermetic in-memory SQLite database for test isolation
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Database initializes with correct schema version and empty tables', () async {
      expect(db.schemaVersion, equals(2));
      final all = await db.getAllEmergencies();
      expect(all, isEmpty);
    });

    test('2. Emergency insertion returns auto-incremented localId and persists fields', () async {
      final now = DateTime.now().toUtc();
      final localId1 = await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'idemp-001',
          title: 'Trapped citizens on rooftop',
          category: 'TRAPPED_CITIZENS',
          latitude: 16.5062,
          longitude: 80.6480,
          createdAt: now,
          updatedAt: now,
          description: const Value('Water reached 2nd floor balcony'),
          affectedCount: const Value(4),
          status: const Value('LOCAL_PENDING'),
          syncStatus: const Value('LOCAL_PENDING'),
        ),
      );

      final localId2 = await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'idemp-002',
          title: 'Oxygen cylinder needed urgently',
          category: 'MEDICAL_EMERGENCY',
          latitude: 16.5033,
          longitude: 80.6465,
          createdAt: now.add(const Duration(minutes: 5)),
          updatedAt: now.add(const Duration(minutes: 5)),
          description: const Value('Power cut in ward 14'),
          affectedCount: const Value(1),
          status: const Value('LOCAL_PENDING'),
          syncStatus: const Value('LOCAL_PENDING'),
        ),
      );

      expect(localId1, equals(1));
      expect(localId2, equals(2));

      final retrieved = await db.getEmergencyByLocalId(localId1);
      expect(retrieved, isNotNull);
      expect(retrieved!.localId, equals(1));
      expect(retrieved.idempotencyKey, equals('idemp-001'));
      expect(retrieved.title, equals('Trapped citizens on rooftop'));
      expect(retrieved.category, equals('TRAPPED_CITIZENS'));
      expect(retrieved.latitude, equals(16.5062));
      expect(retrieved.longitude, equals(80.6480));
      expect(retrieved.affectedCount, equals(4));
      expect(retrieved.status, equals('LOCAL_PENDING'));
      expect(retrieved.syncStatus, equals('LOCAL_PENDING'));
    });

    test('3. Query by unique idempotencyKey returns matching emergency', () async {
      final now = DateTime.now().toUtc();
      await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'uuid-key-abc',
          title: 'Flash flood rescue required',
          category: 'FLOOD_RESCUE',
          latitude: 16.5200,
          longitude: 80.6700,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final found = await db.getEmergencyByIdempotencyKey('uuid-key-abc');
      expect(found, isNotNull);
      expect(found!.title, equals('Flash flood rescue required'));

      final notFound = await db.getEmergencyByIdempotencyKey('uuid-non-existent');
      expect(notFound, isNull);
    });

    test('4. Query by server-assigned emergency ID returns matching emergency', () async {
      final now = DateTime.now().toUtc();
      await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'uuid-server-test',
          title: 'Relief supply distribution',
          category: 'RELIEF_SUPPLY',
          latitude: 16.5180,
          longitude: 80.6020,
          createdAt: now,
          updatedAt: now,
          id: const Value('emg_srv_9988'),
          syncStatus: const Value('SYNCED'),
        ),
      );

      final found = await db.getEmergencyByServerId('emg_srv_9988');
      expect(found, isNotNull);
      expect(found!.id, equals('emg_srv_9988'));
      expect(found.syncStatus, equals('SYNCED'));
    });

    test('5. Vulnerability snapshot immutability: snapshot JSON survives persistence unchanged', () async {
      final now = DateTime.now().toUtc();

      // Create a specific vulnerability profile snapshot
      const initialProfile = VulnerabilityProfile(
        age: 78,
        ageGroup: 'ELDERLY',
        canSwim: false,
        mobilityStatus: 'WHEELCHAIR',
        medicalConditions: ['OXYGEN_DEPENDENT', 'DIALYSIS'],
        disabilityNotes: 'Requires wheelchair ramp',
        status: ProfileStatus.completed,
      );

      final snapshotMap = initialProfile.toSnapshot();
      final snapshotJson = jsonEncode(snapshotMap);

      final localId = await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'uuid-vuln-snap',
          title: 'Severe flood at ground floor with wheelchair resident',
          category: 'FLOOD_RESCUE',
          latitude: 16.5075,
          longitude: 80.6055,
          createdAt: now,
          updatedAt: now,
          vulnerabilitySnapshot: Value(snapshotJson),
        ),
      );

      // Verify stored snapshot matches exact JSON
      final saved = await db.getEmergencyByLocalId(localId);
      expect(saved, isNotNull);
      expect(saved!.vulnerabilitySnapshot, isNotNull);

      final decodedSnap = jsonDecode(saved.vulnerabilitySnapshot!) as Map<String, dynamic>;
      expect(decodedSnap['mobility_status'], equals('WHEELCHAIR'));
      expect(decodedSnap['medical_conditions'], containsAll(['OXYGEN_DEPENDENT', 'DIALYSIS']));
      expect(decodedSnap['age'], equals(78));
      expect(decodedSnap['age_group'], equals('ELDERLY'));
      expect(decodedSnap['can_swim'], isFalse);
      expect(decodedSnap['disability_notes'], equals('Requires wheelchair ramp'));

      // Simulate user editing their active profile later on the device
      const mutatedProfile = VulnerabilityProfile(
        age: 25,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: [],
        disabilityNotes: null,
        status: ProfileStatus.completed,
      );
      expect(mutatedProfile.mobilityStatus, equals('FULL'));

      // Verify the persisted emergency in SQLite was NOT mutated
      final reloaded = await db.getEmergencyByLocalId(localId);
      final reloadedSnap = jsonDecode(reloaded!.vulnerabilitySnapshot!) as Map<String, dynamic>;
      expect(reloadedSnap['mobility_status'], equals('WHEELCHAIR'),
          reason: 'Emergency snapshot in database must remain immutable regardless of subsequent profile changes');
      expect(reloadedSnap['age'], equals(78));
      expect(reloadedSnap['medical_conditions'], containsAll(['OXYGEN_DEPENDENT', 'DIALYSIS']));
    });

    test('6. Status and priority updates preserve snapshot and update timestamps', () async {
      final now = DateTime.now().toUtc();
      final snapJson = jsonEncode({
        'mobility_status': 'BEDRIDDEN',
        'age': 82,
        'medical_conditions': ['HYPERTENSION'],
      });

      final localId = await db.insertEmergency(
        EmergenciesCompanion.insert(
          idempotencyKey: 'uuid-update-test',
          title: 'Evacuation assistance needed',
          category: 'SHELTER_EVACUATION',
          latitude: 16.5062,
          longitude: 80.6480,
          createdAt: now,
          updatedAt: now,
          vulnerabilitySnapshot: Value(snapJson),
          status: const Value('LOCAL_PENDING'),
          syncStatus: const Value('PENDING_SYNC'),
        ),
      );

      // Perform update to mark as ASSIGNED and SYNCED with priority breakdown
      final updatedTime = now.add(const Duration(minutes: 10));
      final rowsAffected = await db.updateEmergencyStatus(
        localId: localId,
        status: 'ASSIGNED',
        syncStatus: 'SYNCED',
        serverId: 'emg_server_123',
        priorityScore: 92.5,
        priorityLevel: 'CRITICAL',
        priorityReasons: ['Bedridden resident requiring stretcher', 'Zone flood depth 1.8m'],
        vulnerabilityScore: 35.0,
        updatedAt: updatedTime,
      );

      expect(rowsAffected, equals(1));

      final updated = await db.getEmergencyByLocalId(localId);
      expect(updated, isNotNull);
      expect(updated!.status, equals('ASSIGNED'));
      expect(updated.syncStatus, equals('SYNCED'));
      expect(updated.id, equals('emg_server_123'));
      expect(updated.priorityScore, equals(92.5));
      expect(updated.priorityLevel, equals('CRITICAL'));
      expect(updated.priorityReasons, isNotNull);
      final reasons = jsonDecode(updated.priorityReasons!) as List;
      expect(reasons, contains('Bedridden resident requiring stretcher'));
      expect(updated.vulnerabilityScore, equals(35.0));

      // CRITICAL: Verify vulnerability snapshot is still intact
      expect(updated.vulnerabilitySnapshot, equals(snapJson));
    });

    test('7. getAllEmergencies returns records in reverse chronological order', () async {
      final t1 = DateTime.utc(2026, 9, 19, 8, 0);
      final t2 = DateTime.utc(2026, 9, 19, 8, 15);
      final t3 = DateTime.utc(2026, 9, 19, 8, 30);

      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'id-t1',
        title: 'Emergency at 08:00',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t1,
        updatedAt: t1,
      ));

      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'id-t3',
        title: 'Emergency at 08:30',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t3,
        updatedAt: t3,
      ));

      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'id-t2',
        title: 'Emergency at 08:15',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: t2,
        updatedAt: t2,
      ));

      final list = await db.getAllEmergencies();
      expect(list.length, equals(3));
      expect(list[0].idempotencyKey, equals('id-t3')); // newest first
      expect(list[1].idempotencyKey, equals('id-t2'));
      expect(list[2].idempotencyKey, equals('id-t1'));
    });

    test('8. watchAllEmergencies emits reactive updates upon insert and delete', () async {
      final now = DateTime.now().toUtc();
      final stream = db.watchAllEmergencies();

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty, // initial emission
          hasLength(1), // after stream-1 insert
          hasLength(2), // after stream-2 insert
          hasLength(1), // after id1 delete
        ]),
      );

      // Yield to let the initial query execute and emit empty list
      await pumpEventQueue();

      final id1 = await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'stream-1',
        title: 'Stream test 1',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
        updatedAt: now,
      ));

      await pumpEventQueue();

      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'stream-2',
        title: 'Stream test 2',
        category: 'MEDICAL_EMERGENCY',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      ));

      await pumpEventQueue();

      await db.deleteEmergency(id1);

      await expectation;
    });

    test('9. deleteEmergency removes record and clearAllEmergencies cleans database', () async {
      final now = DateTime.now().toUtc();
      final id = await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'to-delete',
        title: 'Accidental report to delete',
        category: 'OTHER',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
        updatedAt: now,
      ));

      expect(await db.getEmergencyByLocalId(id), isNotNull);

      final deleted = await db.deleteEmergency(id);
      expect(deleted, equals(1));
      expect(await db.getEmergencyByLocalId(id), isNull);

      // Insert two new items
      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'batch-1',
        title: 'Batch item 1',
        category: 'OTHER',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
        updatedAt: now,
      ));
      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'batch-2',
        title: 'Batch item 2',
        category: 'OTHER',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
        updatedAt: now,
      ));

      expect((await db.getAllEmergencies()).length, equals(2));

      await db.clearAllEmergencies();
      expect(await db.getAllEmergencies(), isEmpty);
    });

    test('10. Unique constraint on idempotencyKey prevents duplicates', () async {
      final now = DateTime.now().toUtc();
      await db.insertEmergency(EmergenciesCompanion.insert(
        idempotencyKey: 'duplicate-key-1',
        title: 'Initial report',
        category: 'FLOOD_RESCUE',
        latitude: 16.5,
        longitude: 80.6,
        createdAt: now,
        updatedAt: now,
      ));

      // Attempting to insert another emergency with identical idempotencyKey throws SQLite constraint exception
      expect(
        () async => await db.insertEmergency(EmergenciesCompanion.insert(
          idempotencyKey: 'duplicate-key-1',
          title: 'Duplicate retry attempt',
          category: 'FLOOD_RESCUE',
          latitude: 16.5,
          longitude: 80.6,
          createdAt: now,
          updatedAt: now,
        )),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
