// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EmergenciesTable extends Emergencies
    with TableInfo<$EmergenciesTable, EmergencyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 5, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _affectedCountMeta =
      const VerificationMeta('affectedCount');
  @override
  late final GeneratedColumn<int> affectedCount = GeneratedColumn<int>(
      'affected_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _vulnerabilitySnapshotMeta =
      const VerificationMeta('vulnerabilitySnapshot');
  @override
  late final GeneratedColumn<String> vulnerabilitySnapshot =
      GeneratedColumn<String>('vulnerability_snapshot', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('LOCAL_PENDING'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('LOCAL_PENDING'));
  static const VerificationMeta _priorityScoreMeta =
      const VerificationMeta('priorityScore');
  @override
  late final GeneratedColumn<double> priorityScore = GeneratedColumn<double>(
      'priority_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _priorityLevelMeta =
      const VerificationMeta('priorityLevel');
  @override
  late final GeneratedColumn<String> priorityLevel = GeneratedColumn<String>(
      'priority_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityReasonsMeta =
      const VerificationMeta('priorityReasons');
  @override
  late final GeneratedColumn<String> priorityReasons = GeneratedColumn<String>(
      'priority_reasons', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vulnerabilityScoreMeta =
      const VerificationMeta('vulnerabilityScore');
  @override
  late final GeneratedColumn<double> vulnerabilityScore =
      GeneratedColumn<double>('vulnerability_score', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncErrorMeta =
      const VerificationMeta('lastSyncError');
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
      'last_sync_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        id,
        idempotencyKey,
        title,
        description,
        category,
        latitude,
        longitude,
        affectedCount,
        vulnerabilitySnapshot,
        syncStatus,
        status,
        priorityScore,
        priorityLevel,
        priorityReasons,
        vulnerabilityScore,
        createdAt,
        updatedAt,
        lastSyncError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergencies';
  @override
  VerificationContext validateIntegrity(Insertable<EmergencyEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('affected_count')) {
      context.handle(
          _affectedCountMeta,
          affectedCount.isAcceptableOrUnknown(
              data['affected_count']!, _affectedCountMeta));
    }
    if (data.containsKey('vulnerability_snapshot')) {
      context.handle(
          _vulnerabilitySnapshotMeta,
          vulnerabilitySnapshot.isAcceptableOrUnknown(
              data['vulnerability_snapshot']!, _vulnerabilitySnapshotMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority_score')) {
      context.handle(
          _priorityScoreMeta,
          priorityScore.isAcceptableOrUnknown(
              data['priority_score']!, _priorityScoreMeta));
    }
    if (data.containsKey('priority_level')) {
      context.handle(
          _priorityLevelMeta,
          priorityLevel.isAcceptableOrUnknown(
              data['priority_level']!, _priorityLevelMeta));
    }
    if (data.containsKey('priority_reasons')) {
      context.handle(
          _priorityReasonsMeta,
          priorityReasons.isAcceptableOrUnknown(
              data['priority_reasons']!, _priorityReasonsMeta));
    }
    if (data.containsKey('vulnerability_score')) {
      context.handle(
          _vulnerabilityScoreMeta,
          vulnerabilityScore.isAcceptableOrUnknown(
              data['vulnerability_score']!, _vulnerabilityScoreMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
          _lastSyncErrorMeta,
          lastSyncError.isAcceptableOrUnknown(
              data['last_sync_error']!, _lastSyncErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  EmergencyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyEntry(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id']),
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      affectedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}affected_count'])!,
      vulnerabilitySnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}vulnerability_snapshot']),
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priorityScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}priority_score']),
      priorityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority_level']),
      priorityReasons: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}priority_reasons']),
      vulnerabilityScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}vulnerability_score']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastSyncError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_sync_error']),
    );
  }

  @override
  $EmergenciesTable createAlias(String alias) {
    return $EmergenciesTable(attachedDatabase, alias);
  }
}

class EmergencyEntry extends DataClass implements Insertable<EmergencyEntry> {
  /// Local SQLite primary key (auto-increment)
  final int localId;

  /// Authoritative backend emergency ID (e.g. `emg_a1b2c3d4`), null when offline created
  final String? id;

  /// Unique client-generated UUID v4 idempotency key for deduplication and retry safety
  final String idempotencyKey;

  /// Short summary / title of the emergency (5-150 chars)
  final String title;

  /// Optional detailed incident description (max 500 chars)
  final String? description;

  /// Incident category (e.g. FLOOD_RESCUE, MEDICAL_EMERGENCY, TRAPPED_CITIZENS)
  final String category;

  /// GPS or sector fallback latitude (-90 to 90)
  final double latitude;

  /// GPS or sector fallback longitude (-180 to 180)
  final double longitude;

  /// Number of individuals affected (>= 1)
  final int affectedCount;

  /// Immutable snapshot of citizen vulnerability profile as JSON string at creation time
  final String? vulnerabilitySnapshot;

  /// Local sync lifecycle state: LOCAL_PENDING, PENDING_SYNC, SYNCING, SYNCED, SYNC_FAILED
  final String syncStatus;

  /// Emergency lifecycle status: LOCAL_PENDING, PENDING, ASSIGNED, IN_PROGRESS, RESOLVED, CANCELLED
  final String status;

  /// Decision engine calculated priority score
  final double? priorityScore;

  /// Priority classification: LOW, MEDIUM, HIGH, CRITICAL
  final String? priorityLevel;

  /// JSON-encoded array of decision engine reasoning strings
  final String? priorityReasons;

  /// Decision engine calculated vulnerability heuristic score
  final double? vulnerabilityScore;

  /// Timestamp when emergency was initially created on device
  final DateTime createdAt;

  /// Timestamp of latest local or synced update
  final DateTime updatedAt;

  /// Diagnostic failure reason if sync encountered an error
  final String? lastSyncError;
  const EmergencyEntry(
      {required this.localId,
      this.id,
      required this.idempotencyKey,
      required this.title,
      this.description,
      required this.category,
      required this.latitude,
      required this.longitude,
      required this.affectedCount,
      this.vulnerabilitySnapshot,
      required this.syncStatus,
      required this.status,
      this.priorityScore,
      this.priorityLevel,
      this.priorityReasons,
      this.vulnerabilityScore,
      required this.createdAt,
      required this.updatedAt,
      this.lastSyncError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['affected_count'] = Variable<int>(affectedCount);
    if (!nullToAbsent || vulnerabilitySnapshot != null) {
      map['vulnerability_snapshot'] = Variable<String>(vulnerabilitySnapshot);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || priorityScore != null) {
      map['priority_score'] = Variable<double>(priorityScore);
    }
    if (!nullToAbsent || priorityLevel != null) {
      map['priority_level'] = Variable<String>(priorityLevel);
    }
    if (!nullToAbsent || priorityReasons != null) {
      map['priority_reasons'] = Variable<String>(priorityReasons);
    }
    if (!nullToAbsent || vulnerabilityScore != null) {
      map['vulnerability_score'] = Variable<double>(vulnerabilityScore);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    return map;
  }

  EmergenciesCompanion toCompanion(bool nullToAbsent) {
    return EmergenciesCompanion(
      localId: Value(localId),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      idempotencyKey: Value(idempotencyKey),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      latitude: Value(latitude),
      longitude: Value(longitude),
      affectedCount: Value(affectedCount),
      vulnerabilitySnapshot: vulnerabilitySnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(vulnerabilitySnapshot),
      syncStatus: Value(syncStatus),
      status: Value(status),
      priorityScore: priorityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(priorityScore),
      priorityLevel: priorityLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(priorityLevel),
      priorityReasons: priorityReasons == null && nullToAbsent
          ? const Value.absent()
          : Value(priorityReasons),
      vulnerabilityScore: vulnerabilityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(vulnerabilityScore),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
    );
  }

  factory EmergencyEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyEntry(
      localId: serializer.fromJson<int>(json['localId']),
      id: serializer.fromJson<String?>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      affectedCount: serializer.fromJson<int>(json['affectedCount']),
      vulnerabilitySnapshot:
          serializer.fromJson<String?>(json['vulnerabilitySnapshot']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      status: serializer.fromJson<String>(json['status']),
      priorityScore: serializer.fromJson<double?>(json['priorityScore']),
      priorityLevel: serializer.fromJson<String?>(json['priorityLevel']),
      priorityReasons: serializer.fromJson<String?>(json['priorityReasons']),
      vulnerabilityScore:
          serializer.fromJson<double?>(json['vulnerabilityScore']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'id': serializer.toJson<String?>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'affectedCount': serializer.toJson<int>(affectedCount),
      'vulnerabilitySnapshot':
          serializer.toJson<String?>(vulnerabilitySnapshot),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'status': serializer.toJson<String>(status),
      'priorityScore': serializer.toJson<double?>(priorityScore),
      'priorityLevel': serializer.toJson<String?>(priorityLevel),
      'priorityReasons': serializer.toJson<String?>(priorityReasons),
      'vulnerabilityScore': serializer.toJson<double?>(vulnerabilityScore),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
    };
  }

  EmergencyEntry copyWith(
          {int? localId,
          Value<String?> id = const Value.absent(),
          String? idempotencyKey,
          String? title,
          Value<String?> description = const Value.absent(),
          String? category,
          double? latitude,
          double? longitude,
          int? affectedCount,
          Value<String?> vulnerabilitySnapshot = const Value.absent(),
          String? syncStatus,
          String? status,
          Value<double?> priorityScore = const Value.absent(),
          Value<String?> priorityLevel = const Value.absent(),
          Value<String?> priorityReasons = const Value.absent(),
          Value<double?> vulnerabilityScore = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> lastSyncError = const Value.absent()}) =>
      EmergencyEntry(
        localId: localId ?? this.localId,
        id: id.present ? id.value : this.id,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        category: category ?? this.category,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        affectedCount: affectedCount ?? this.affectedCount,
        vulnerabilitySnapshot: vulnerabilitySnapshot.present
            ? vulnerabilitySnapshot.value
            : this.vulnerabilitySnapshot,
        syncStatus: syncStatus ?? this.syncStatus,
        status: status ?? this.status,
        priorityScore:
            priorityScore.present ? priorityScore.value : this.priorityScore,
        priorityLevel:
            priorityLevel.present ? priorityLevel.value : this.priorityLevel,
        priorityReasons: priorityReasons.present
            ? priorityReasons.value
            : this.priorityReasons,
        vulnerabilityScore: vulnerabilityScore.present
            ? vulnerabilityScore.value
            : this.vulnerabilityScore,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncError:
            lastSyncError.present ? lastSyncError.value : this.lastSyncError,
      );
  EmergencyEntry copyWithCompanion(EmergenciesCompanion data) {
    return EmergencyEntry(
      localId: data.localId.present ? data.localId.value : this.localId,
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      affectedCount: data.affectedCount.present
          ? data.affectedCount.value
          : this.affectedCount,
      vulnerabilitySnapshot: data.vulnerabilitySnapshot.present
          ? data.vulnerabilitySnapshot.value
          : this.vulnerabilitySnapshot,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      status: data.status.present ? data.status.value : this.status,
      priorityScore: data.priorityScore.present
          ? data.priorityScore.value
          : this.priorityScore,
      priorityLevel: data.priorityLevel.present
          ? data.priorityLevel.value
          : this.priorityLevel,
      priorityReasons: data.priorityReasons.present
          ? data.priorityReasons.value
          : this.priorityReasons,
      vulnerabilityScore: data.vulnerabilityScore.present
          ? data.vulnerabilityScore.value
          : this.vulnerabilityScore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyEntry(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('affectedCount: $affectedCount, ')
          ..write('vulnerabilitySnapshot: $vulnerabilitySnapshot, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('status: $status, ')
          ..write('priorityScore: $priorityScore, ')
          ..write('priorityLevel: $priorityLevel, ')
          ..write('priorityReasons: $priorityReasons, ')
          ..write('vulnerabilityScore: $vulnerabilityScore, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      id,
      idempotencyKey,
      title,
      description,
      category,
      latitude,
      longitude,
      affectedCount,
      vulnerabilitySnapshot,
      syncStatus,
      status,
      priorityScore,
      priorityLevel,
      priorityReasons,
      vulnerabilityScore,
      createdAt,
      updatedAt,
      lastSyncError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyEntry &&
          other.localId == this.localId &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.affectedCount == this.affectedCount &&
          other.vulnerabilitySnapshot == this.vulnerabilitySnapshot &&
          other.syncStatus == this.syncStatus &&
          other.status == this.status &&
          other.priorityScore == this.priorityScore &&
          other.priorityLevel == this.priorityLevel &&
          other.priorityReasons == this.priorityReasons &&
          other.vulnerabilityScore == this.vulnerabilityScore &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncError == this.lastSyncError);
}

class EmergenciesCompanion extends UpdateCompanion<EmergencyEntry> {
  final Value<int> localId;
  final Value<String?> id;
  final Value<String> idempotencyKey;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> category;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> affectedCount;
  final Value<String?> vulnerabilitySnapshot;
  final Value<String> syncStatus;
  final Value<String> status;
  final Value<double?> priorityScore;
  final Value<String?> priorityLevel;
  final Value<String?> priorityReasons;
  final Value<double?> vulnerabilityScore;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> lastSyncError;
  const EmergenciesCompanion({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.affectedCount = const Value.absent(),
    this.vulnerabilitySnapshot = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.priorityScore = const Value.absent(),
    this.priorityLevel = const Value.absent(),
    this.priorityReasons = const Value.absent(),
    this.vulnerabilityScore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
  });
  EmergenciesCompanion.insert({
    this.localId = const Value.absent(),
    this.id = const Value.absent(),
    required String idempotencyKey,
    required String title,
    this.description = const Value.absent(),
    required String category,
    required double latitude,
    required double longitude,
    this.affectedCount = const Value.absent(),
    this.vulnerabilitySnapshot = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.status = const Value.absent(),
    this.priorityScore = const Value.absent(),
    this.priorityLevel = const Value.absent(),
    this.priorityReasons = const Value.absent(),
    this.vulnerabilityScore = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncError = const Value.absent(),
  })  : idempotencyKey = Value(idempotencyKey),
        title = Value(title),
        category = Value(category),
        latitude = Value(latitude),
        longitude = Value(longitude),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<EmergencyEntry> custom({
    Expression<int>? localId,
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? affectedCount,
    Expression<String>? vulnerabilitySnapshot,
    Expression<String>? syncStatus,
    Expression<String>? status,
    Expression<double>? priorityScore,
    Expression<String>? priorityLevel,
    Expression<String>? priorityReasons,
    Expression<double>? vulnerabilityScore,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? lastSyncError,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (affectedCount != null) 'affected_count': affectedCount,
      if (vulnerabilitySnapshot != null)
        'vulnerability_snapshot': vulnerabilitySnapshot,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (status != null) 'status': status,
      if (priorityScore != null) 'priority_score': priorityScore,
      if (priorityLevel != null) 'priority_level': priorityLevel,
      if (priorityReasons != null) 'priority_reasons': priorityReasons,
      if (vulnerabilityScore != null) 'vulnerability_score': vulnerabilityScore,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
    });
  }

  EmergenciesCompanion copyWith(
      {Value<int>? localId,
      Value<String?>? id,
      Value<String>? idempotencyKey,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? category,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<int>? affectedCount,
      Value<String?>? vulnerabilitySnapshot,
      Value<String>? syncStatus,
      Value<String>? status,
      Value<double?>? priorityScore,
      Value<String?>? priorityLevel,
      Value<String?>? priorityReasons,
      Value<double?>? vulnerabilityScore,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? lastSyncError}) {
    return EmergenciesCompanion(
      localId: localId ?? this.localId,
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      affectedCount: affectedCount ?? this.affectedCount,
      vulnerabilitySnapshot:
          vulnerabilitySnapshot ?? this.vulnerabilitySnapshot,
      syncStatus: syncStatus ?? this.syncStatus,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      priorityReasons: priorityReasons ?? this.priorityReasons,
      vulnerabilityScore: vulnerabilityScore ?? this.vulnerabilityScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (affectedCount.present) {
      map['affected_count'] = Variable<int>(affectedCount.value);
    }
    if (vulnerabilitySnapshot.present) {
      map['vulnerability_snapshot'] =
          Variable<String>(vulnerabilitySnapshot.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priorityScore.present) {
      map['priority_score'] = Variable<double>(priorityScore.value);
    }
    if (priorityLevel.present) {
      map['priority_level'] = Variable<String>(priorityLevel.value);
    }
    if (priorityReasons.present) {
      map['priority_reasons'] = Variable<String>(priorityReasons.value);
    }
    if (vulnerabilityScore.present) {
      map['vulnerability_score'] = Variable<double>(vulnerabilityScore.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergenciesCompanion(')
          ..write('localId: $localId, ')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('affectedCount: $affectedCount, ')
          ..write('vulnerabilitySnapshot: $vulnerabilitySnapshot, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('status: $status, ')
          ..write('priorityScore: $priorityScore, ')
          ..write('priorityLevel: $priorityLevel, ')
          ..write('priorityReasons: $priorityReasons, ')
          ..write('vulnerabilityScore: $vulnerabilityScore, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncError: $lastSyncError')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _operationTypeMeta =
      const VerificationMeta('operationType');
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
      'operation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emergencyLocalIdMeta =
      const VerificationMeta('emergencyLocalId');
  @override
  late final GeneratedColumn<int> emergencyLocalId = GeneratedColumn<int>(
      'emergency_local_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAttemptedAtMeta =
      const VerificationMeta('lastAttemptedAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptedAt =
      GeneratedColumn<DateTime>('last_attempted_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operationType,
        emergencyLocalId,
        idempotencyKey,
        payload,
        status,
        attemptCount,
        lastAttemptedAt,
        createdAt,
        lastError,
        nextRetryAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
      Insertable<PendingOperationEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
          _operationTypeMeta,
          operationType.isAcceptableOrUnknown(
              data['operation_type']!, _operationTypeMeta));
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('emergency_local_id')) {
      context.handle(
          _emergencyLocalIdMeta,
          emergencyLocalId.isAcceptableOrUnknown(
              data['emergency_local_id']!, _emergencyLocalIdMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_attempted_at')) {
      context.handle(
          _lastAttemptedAtMeta,
          lastAttemptedAt.isAcceptableOrUnknown(
              data['last_attempted_at']!, _lastAttemptedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperationEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      operationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_type'])!,
      emergencyLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}emergency_local_id']),
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastAttemptedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperationEntry extends DataClass
    implements Insertable<PendingOperationEntry> {
  /// Local autoincrement operation ID
  final int id;

  /// Explicit operation type (e.g. `CREATE_EMERGENCY`)
  final String operationType;

  /// Associated emergency localId in SQLite Emergencies table, if available
  final int? emergencyLocalId;

  /// Unique client-generated UUID v4 idempotency key matching original emergency
  final String idempotencyKey;

  /// Exact JSON stringified request payload to be replayed verbatim
  final String payload;

  /// Operation queue state: PENDING, IN_FLIGHT, FAILED, COMPLETED
  final String status;

  /// Number of transmission attempts
  final int attemptCount;

  /// Timestamp of the latest transmission attempt
  final DateTime? lastAttemptedAt;

  /// Timestamp when operation was enqueued (for deterministic FIFO sorting)
  final DateTime createdAt;

  /// Diagnostic error message from latest failure
  final String? lastError;

  /// Timestamp when next retry is permitted (foundation for T058 backoff)
  final DateTime? nextRetryAt;
  const PendingOperationEntry(
      {required this.id,
      required this.operationType,
      this.emergencyLocalId,
      required this.idempotencyKey,
      required this.payload,
      required this.status,
      required this.attemptCount,
      this.lastAttemptedAt,
      required this.createdAt,
      this.lastError,
      this.nextRetryAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    if (!nullToAbsent || emergencyLocalId != null) {
      map['emergency_local_id'] = Variable<int>(emergencyLocalId);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAttemptedAt != null) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      operationType: Value(operationType),
      emergencyLocalId: emergencyLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyLocalId),
      idempotencyKey: Value(idempotencyKey),
      payload: Value(payload),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastAttemptedAt: lastAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptedAt),
      createdAt: Value(createdAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory PendingOperationEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperationEntry(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      emergencyLocalId: serializer.fromJson<int?>(json['emergencyLocalId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAttemptedAt: serializer.fromJson<DateTime?>(json['lastAttemptedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'emergencyLocalId': serializer.toJson<int?>(emergencyLocalId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAttemptedAt': serializer.toJson<DateTime?>(lastAttemptedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastError': serializer.toJson<String?>(lastError),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
    };
  }

  PendingOperationEntry copyWith(
          {int? id,
          String? operationType,
          Value<int?> emergencyLocalId = const Value.absent(),
          String? idempotencyKey,
          String? payload,
          String? status,
          int? attemptCount,
          Value<DateTime?> lastAttemptedAt = const Value.absent(),
          DateTime? createdAt,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> nextRetryAt = const Value.absent()}) =>
      PendingOperationEntry(
        id: id ?? this.id,
        operationType: operationType ?? this.operationType,
        emergencyLocalId: emergencyLocalId.present
            ? emergencyLocalId.value
            : this.emergencyLocalId,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        payload: payload ?? this.payload,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptedAt: lastAttemptedAt.present
            ? lastAttemptedAt.value
            : this.lastAttemptedAt,
        createdAt: createdAt ?? this.createdAt,
        lastError: lastError.present ? lastError.value : this.lastError,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
      );
  PendingOperationEntry copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperationEntry(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      emergencyLocalId: data.emergencyLocalId.present
          ? data.emergencyLocalId.value
          : this.emergencyLocalId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAttemptedAt: data.lastAttemptedAt.present
          ? data.lastAttemptedAt.value
          : this.lastAttemptedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationEntry(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('emergencyLocalId: $emergencyLocalId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      operationType,
      emergencyLocalId,
      idempotencyKey,
      payload,
      status,
      attemptCount,
      lastAttemptedAt,
      createdAt,
      lastError,
      nextRetryAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperationEntry &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.emergencyLocalId == this.emergencyLocalId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastAttemptedAt == this.lastAttemptedAt &&
          other.createdAt == this.createdAt &&
          other.lastError == this.lastError &&
          other.nextRetryAt == this.nextRetryAt);
}

class PendingOperationsCompanion
    extends UpdateCompanion<PendingOperationEntry> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<int?> emergencyLocalId;
  final Value<String> idempotencyKey;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime?> lastAttemptedAt;
  final Value<DateTime> createdAt;
  final Value<String?> lastError;
  final Value<DateTime?> nextRetryAt;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.emergencyLocalId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    this.emergencyLocalId = const Value.absent(),
    required String idempotencyKey,
    required String payload,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAttemptedAt = const Value.absent(),
    required DateTime createdAt,
    this.lastError = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
  })  : operationType = Value(operationType),
        idempotencyKey = Value(idempotencyKey),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<PendingOperationEntry> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<int>? emergencyLocalId,
    Expression<String>? idempotencyKey,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? lastAttemptedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? lastError,
    Expression<DateTime>? nextRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (emergencyLocalId != null) 'emergency_local_id': emergencyLocalId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAttemptedAt != null) 'last_attempted_at': lastAttemptedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastError != null) 'last_error': lastError,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
    });
  }

  PendingOperationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? operationType,
      Value<int?>? emergencyLocalId,
      Value<String>? idempotencyKey,
      Value<String>? payload,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<DateTime?>? lastAttemptedAt,
      Value<DateTime>? createdAt,
      Value<String?>? lastError,
      Value<DateTime?>? nextRetryAt}) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      emergencyLocalId: emergencyLocalId ?? this.emergencyLocalId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      createdAt: createdAt ?? this.createdAt,
      lastError: lastError ?? this.lastError,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (emergencyLocalId.present) {
      map['emergency_local_id'] = Variable<int>(emergencyLocalId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAttemptedAt.present) {
      map['last_attempted_at'] = Variable<DateTime>(lastAttemptedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('emergencyLocalId: $emergencyLocalId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAttemptedAt: $lastAttemptedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastError: $lastError, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EmergenciesTable emergencies = $EmergenciesTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [emergencies, pendingOperations];
}

typedef $$EmergenciesTableCreateCompanionBuilder = EmergenciesCompanion
    Function({
  Value<int> localId,
  Value<String?> id,
  required String idempotencyKey,
  required String title,
  Value<String?> description,
  required String category,
  required double latitude,
  required double longitude,
  Value<int> affectedCount,
  Value<String?> vulnerabilitySnapshot,
  Value<String> syncStatus,
  Value<String> status,
  Value<double?> priorityScore,
  Value<String?> priorityLevel,
  Value<String?> priorityReasons,
  Value<double?> vulnerabilityScore,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> lastSyncError,
});
typedef $$EmergenciesTableUpdateCompanionBuilder = EmergenciesCompanion
    Function({
  Value<int> localId,
  Value<String?> id,
  Value<String> idempotencyKey,
  Value<String> title,
  Value<String?> description,
  Value<String> category,
  Value<double> latitude,
  Value<double> longitude,
  Value<int> affectedCount,
  Value<String?> vulnerabilitySnapshot,
  Value<String> syncStatus,
  Value<String> status,
  Value<double?> priorityScore,
  Value<String?> priorityLevel,
  Value<String?> priorityReasons,
  Value<double?> vulnerabilityScore,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> lastSyncError,
});

class $$EmergenciesTableFilterComposer
    extends Composer<_$AppDatabase, $EmergenciesTable> {
  $$EmergenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get affectedCount => $composableBuilder(
      column: $table.affectedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vulnerabilitySnapshot => $composableBuilder(
      column: $table.vulnerabilitySnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priorityLevel => $composableBuilder(
      column: $table.priorityLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priorityReasons => $composableBuilder(
      column: $table.priorityReasons,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get vulnerabilityScore => $composableBuilder(
      column: $table.vulnerabilityScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError, builder: (column) => ColumnFilters(column));
}

class $$EmergenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmergenciesTable> {
  $$EmergenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get affectedCount => $composableBuilder(
      column: $table.affectedCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vulnerabilitySnapshot => $composableBuilder(
      column: $table.vulnerabilitySnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priorityLevel => $composableBuilder(
      column: $table.priorityLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priorityReasons => $composableBuilder(
      column: $table.priorityReasons,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get vulnerabilityScore => $composableBuilder(
      column: $table.vulnerabilityScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError,
      builder: (column) => ColumnOrderings(column));
}

class $$EmergenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmergenciesTable> {
  $$EmergenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get affectedCount => $composableBuilder(
      column: $table.affectedCount, builder: (column) => column);

  GeneratedColumn<String> get vulnerabilitySnapshot => $composableBuilder(
      column: $table.vulnerabilitySnapshot, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get priorityScore => $composableBuilder(
      column: $table.priorityScore, builder: (column) => column);

  GeneratedColumn<String> get priorityLevel => $composableBuilder(
      column: $table.priorityLevel, builder: (column) => column);

  GeneratedColumn<String> get priorityReasons => $composableBuilder(
      column: $table.priorityReasons, builder: (column) => column);

  GeneratedColumn<double> get vulnerabilityScore => $composableBuilder(
      column: $table.vulnerabilityScore, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
      column: $table.lastSyncError, builder: (column) => column);
}

class $$EmergenciesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmergenciesTable,
    EmergencyEntry,
    $$EmergenciesTableFilterComposer,
    $$EmergenciesTableOrderingComposer,
    $$EmergenciesTableAnnotationComposer,
    $$EmergenciesTableCreateCompanionBuilder,
    $$EmergenciesTableUpdateCompanionBuilder,
    (
      EmergencyEntry,
      BaseReferences<_$AppDatabase, $EmergenciesTable, EmergencyEntry>
    ),
    EmergencyEntry,
    PrefetchHooks Function()> {
  $$EmergenciesTableTableManager(_$AppDatabase db, $EmergenciesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmergenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmergenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmergenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String?> id = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<int> affectedCount = const Value.absent(),
            Value<String?> vulnerabilitySnapshot = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double?> priorityScore = const Value.absent(),
            Value<String?> priorityLevel = const Value.absent(),
            Value<String?> priorityReasons = const Value.absent(),
            Value<double?> vulnerabilityScore = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> lastSyncError = const Value.absent(),
          }) =>
              EmergenciesCompanion(
            localId: localId,
            id: id,
            idempotencyKey: idempotencyKey,
            title: title,
            description: description,
            category: category,
            latitude: latitude,
            longitude: longitude,
            affectedCount: affectedCount,
            vulnerabilitySnapshot: vulnerabilitySnapshot,
            syncStatus: syncStatus,
            status: status,
            priorityScore: priorityScore,
            priorityLevel: priorityLevel,
            priorityReasons: priorityReasons,
            vulnerabilityScore: vulnerabilityScore,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncError: lastSyncError,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String?> id = const Value.absent(),
            required String idempotencyKey,
            required String title,
            Value<String?> description = const Value.absent(),
            required String category,
            required double latitude,
            required double longitude,
            Value<int> affectedCount = const Value.absent(),
            Value<String?> vulnerabilitySnapshot = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<double?> priorityScore = const Value.absent(),
            Value<String?> priorityLevel = const Value.absent(),
            Value<String?> priorityReasons = const Value.absent(),
            Value<double?> vulnerabilityScore = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String?> lastSyncError = const Value.absent(),
          }) =>
              EmergenciesCompanion.insert(
            localId: localId,
            id: id,
            idempotencyKey: idempotencyKey,
            title: title,
            description: description,
            category: category,
            latitude: latitude,
            longitude: longitude,
            affectedCount: affectedCount,
            vulnerabilitySnapshot: vulnerabilitySnapshot,
            syncStatus: syncStatus,
            status: status,
            priorityScore: priorityScore,
            priorityLevel: priorityLevel,
            priorityReasons: priorityReasons,
            vulnerabilityScore: vulnerabilityScore,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastSyncError: lastSyncError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmergenciesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmergenciesTable,
    EmergencyEntry,
    $$EmergenciesTableFilterComposer,
    $$EmergenciesTableOrderingComposer,
    $$EmergenciesTableAnnotationComposer,
    $$EmergenciesTableCreateCompanionBuilder,
    $$EmergenciesTableUpdateCompanionBuilder,
    (
      EmergencyEntry,
      BaseReferences<_$AppDatabase, $EmergenciesTable, EmergencyEntry>
    ),
    EmergencyEntry,
    PrefetchHooks Function()>;
typedef $$PendingOperationsTableCreateCompanionBuilder
    = PendingOperationsCompanion Function({
  Value<int> id,
  required String operationType,
  Value<int?> emergencyLocalId,
  required String idempotencyKey,
  required String payload,
  Value<String> status,
  Value<int> attemptCount,
  Value<DateTime?> lastAttemptedAt,
  required DateTime createdAt,
  Value<String?> lastError,
  Value<DateTime?> nextRetryAt,
});
typedef $$PendingOperationsTableUpdateCompanionBuilder
    = PendingOperationsCompanion Function({
  Value<int> id,
  Value<String> operationType,
  Value<int?> emergencyLocalId,
  Value<String> idempotencyKey,
  Value<String> payload,
  Value<String> status,
  Value<int> attemptCount,
  Value<DateTime?> lastAttemptedAt,
  Value<DateTime> createdAt,
  Value<String?> lastError,
  Value<DateTime?> nextRetryAt,
});

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get emergencyLocalId => $composableBuilder(
      column: $table.emergencyLocalId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationType => $composableBuilder(
      column: $table.operationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get emergencyLocalId => $composableBuilder(
      column: $table.emergencyLocalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => column);

  GeneratedColumn<int> get emergencyLocalId => $composableBuilder(
      column: $table.emergencyLocalId, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptedAt => $composableBuilder(
      column: $table.lastAttemptedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);
}

class $$PendingOperationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingOperationsTable,
    PendingOperationEntry,
    $$PendingOperationsTableFilterComposer,
    $$PendingOperationsTableOrderingComposer,
    $$PendingOperationsTableAnnotationComposer,
    $$PendingOperationsTableCreateCompanionBuilder,
    $$PendingOperationsTableUpdateCompanionBuilder,
    (
      PendingOperationEntry,
      BaseReferences<_$AppDatabase, $PendingOperationsTable,
          PendingOperationEntry>
    ),
    PendingOperationEntry,
    PrefetchHooks Function()> {
  $$PendingOperationsTableTableManager(
      _$AppDatabase db, $PendingOperationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> operationType = const Value.absent(),
            Value<int?> emergencyLocalId = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> lastAttemptedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
          }) =>
              PendingOperationsCompanion(
            id: id,
            operationType: operationType,
            emergencyLocalId: emergencyLocalId,
            idempotencyKey: idempotencyKey,
            payload: payload,
            status: status,
            attemptCount: attemptCount,
            lastAttemptedAt: lastAttemptedAt,
            createdAt: createdAt,
            lastError: lastError,
            nextRetryAt: nextRetryAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String operationType,
            Value<int?> emergencyLocalId = const Value.absent(),
            required String idempotencyKey,
            required String payload,
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<DateTime?> lastAttemptedAt = const Value.absent(),
            required DateTime createdAt,
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
          }) =>
              PendingOperationsCompanion.insert(
            id: id,
            operationType: operationType,
            emergencyLocalId: emergencyLocalId,
            idempotencyKey: idempotencyKey,
            payload: payload,
            status: status,
            attemptCount: attemptCount,
            lastAttemptedAt: lastAttemptedAt,
            createdAt: createdAt,
            lastError: lastError,
            nextRetryAt: nextRetryAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingOperationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingOperationsTable,
    PendingOperationEntry,
    $$PendingOperationsTableFilterComposer,
    $$PendingOperationsTableOrderingComposer,
    $$PendingOperationsTableAnnotationComposer,
    $$PendingOperationsTableCreateCompanionBuilder,
    $$PendingOperationsTableUpdateCompanionBuilder,
    (
      PendingOperationEntry,
      BaseReferences<_$AppDatabase, $PendingOperationsTable,
          PendingOperationEntry>
    ),
    PendingOperationEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EmergenciesTableTableManager get emergencies =>
      $$EmergenciesTableTableManager(_db, _db.emergencies);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
}
