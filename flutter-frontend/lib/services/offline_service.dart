import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/citizen_profile.dart';
import '../models/vulnerability_profile.dart';
import '../models/emergency_tracking.dart';
import '../repositories/local_emergency_repository.dart';
import 'connectivity_service.dart';
import 'pending_operation_queue.dart';
import 'sync_service.dart';

export 'connectivity_service.dart' show ConnectivityState;

class OfflineService extends ChangeNotifier {
  static const String apiBase = "http://localhost:3000/api/v1";
  
  final LocalEmergencyRepository _repository;
  final PendingOperationQueue _queue;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;
  StreamSubscription<ConnectivityState>? _connectivitySubscription;

  ConnectivityState _connectivity = ConnectivityState.online;
  List<Map<String, dynamic>> _localQueue = [];
  CitizenProfile? _userCitizenProfile;
  VulnerabilityProfile? _userVulnerabilityProfile;
  Map<String, dynamic>? _activeEmergency;
  String _userId = "usr_citizen_local";
  String? _lastSyncError;
  final bool _autoSync;
  bool _isSyncing = false;
  bool _isDisposed = false;
  http.Client? _defaultClient;
  Future<void>? _currentSyncFuture;
  late final Future<void> _initFuture;

  LocalEmergencyRepository get repository => _repository;
  PendingOperationQueue get queue => _queue;
  ConnectivityService get connectivityService => _connectivityService;
  SyncService get syncService => _syncService;
  ConnectivityState get connectivity => _connectivity;
  ConnectivityState get connectivityState => _connectivity;
  bool get isOnline => _connectivity == ConnectivityState.online;
  bool get isOffline => _connectivity == ConnectivityState.offline;
  bool get isIntermittent => _connectivity == ConnectivityState.intermittent;
  List<Map<String, dynamic>> get localQueue => _localQueue;
  Map<String, dynamic>? get activeEmergency => _activeEmergency;
  bool get hasActiveEmergency => _activeEmergency != null || _localQueue.isNotEmpty;
  String? get lastSyncError => _lastSyncError;
  bool get autoSync => _autoSync;
  bool get isSyncing => _isSyncing;
  bool get isDisposed => _isDisposed;
  Future<void>? get currentSyncFuture => _currentSyncFuture;

  /// Sets a default HTTP client (useful for mock testing).
  void setDefaultHttpClient(http.Client? client) {
    _defaultClient = client;
    _syncService.setDefaultHttpClient(client);
  }

  /// Waits for any in-flight automatic or manual sync to complete.
  Future<void> waitForSync() async {
    while (_isSyncing || _currentSyncFuture != null) {
      final f = _currentSyncFuture;
      if (f != null) {
        await f;
      }
      if (!_isSyncing) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Returns the current active citizen profile, or an empty profile if not configured.
  CitizenProfile get citizenProfile =>
      _userCitizenProfile ?? CitizenProfile.defaultProfile();

  /// Whether basic citizen identification details have been completed.
  bool get isBasicProfileComplete =>
      _userCitizenProfile != null && _userCitizenProfile!.isComplete;

  /// Returns the current active vulnerability profile, or a default profile if not configured.
  VulnerabilityProfile get vulnerabilityProfile =>
      _userVulnerabilityProfile ?? VulnerabilityProfile.defaultProfile();

  /// Profile completion status: completed, defaultProfile, or notCompleted.
  ProfileStatus get profileStatus =>
      _userVulnerabilityProfile?.status ?? ProfileStatus.notCompleted;

  /// True if user completed both basic citizen profile and vulnerability profile.
  bool get hasCompletedOnboarding =>
      (isBasicProfileComplete || _userCitizenProfile == null) &&
      _userVulnerabilityProfile != null &&
      _userVulnerabilityProfile!.status != ProfileStatus.notCompleted;

  String get userId => _userId;

  factory OfflineService({
    LocalEmergencyRepository? repository,
    PendingOperationQueue? queue,
    ConnectivityService? connectivityService,
    SyncService? syncService,
    http.Client? defaultClient,
    bool autoSync = true,
  }) {
    final repo = repository ?? LocalEmergencyRepository();
    final q = queue ?? PendingOperationQueue(repo.database);
    final cs = connectivityService ?? ConnectivityService(autoInitialize: true);
    final ss = syncService ??
        SyncService(repository: repo, queue: q, defaultClient: defaultClient);
    return OfflineService._(repo, q, cs, ss,
        defaultClient: defaultClient, autoSync: autoSync);
  }

  OfflineService._(
    this._repository,
    this._queue,
    this._connectivityService,
    this._syncService, {
    http.Client? defaultClient,
    bool autoSync = true,
  })  : _defaultClient = defaultClient,
        _autoSync = autoSync {
    _connectivity = _connectivityService.state;
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((state) {
      if (_isDisposed) return;
      if (_connectivityService.manualOverride != null) {
        state = _connectivityService.manualOverride!;
      }
      if (_connectivity != state) {
        final oldState = _connectivity;
        _connectivity = state;
        if (!_isDisposed) notifyListeners();

        // T058: Trigger automatic sync when transitioning from non-online to online
        if (oldState != ConnectivityState.online &&
            state == ConnectivityState.online) {
          _triggerAutomaticSync();
        }
      }
    });
    _initFuture = _loadLocalData();
  }

  Future<void> ensureInitialized() => _initFuture;

  void setConnectivity(ConnectivityState state) {
    if (_isDisposed) return;
    final oldState = _connectivity;
    _connectivity = state;
    _connectivityService.setManualOverride(state);
    if (!_isDisposed) notifyListeners();

    // T058: Trigger automatic sync when transitioning from non-online to online
    if (oldState != ConnectivityState.online &&
        state == ConnectivityState.online) {
      _triggerAutomaticSync();
    }
  }

  void _triggerAutomaticSync() {
    if (!_autoSync ||
        _isDisposed ||
        _connectivity != ConnectivityState.online ||
        _isSyncing) {
      return;
    }
    final completer = Completer<void>();
    _currentSyncFuture = completer.future;
    Future.microtask(() async {
      try {
        await syncPendingQueue();
      } catch (e) {
        debugPrint('Automatic sync error: $e');
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load User ID or generate stable one
    final savedUserId = prefs.getString('user_id');
    if (savedUserId != null && savedUserId.isNotEmpty) {
      _userId = savedUserId;
    } else {
      _userId = "usr_${const Uuid().v4().substring(0, 8)}";
      await prefs.setString('user_id', _userId);
    }

    // Load Pending Offline Queue from durable SQLite queue
    try {
      final dbPending = await _queue.getPendingOperations();
      _localQueue = dbPending.map((op) {
        try {
          return jsonDecode(op.payload) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{
            'idempotency_key': op.idempotencyKey,
            'status': 'LOCAL_PENDING',
            'sync_status': 'PENDING_SYNC',
          };
        }
      }).toList();
    } catch (_) {
      _localQueue = [];
    }

    // Migrate any legacy SharedPreferences queue into SQLite queue
    final queueStr = prefs.getString('pending_queue');
    if (queueStr != null && queueStr.isNotEmpty && queueStr != '[]') {
      try {
        final legacyItems = List<Map<String, dynamic>>.from(jsonDecode(queueStr));
        for (var item in legacyItems) {
          final idempKey = item['idempotency_key'] as String? ?? const Uuid().v4();
          await _queue.enqueue(
            operationType: 'CREATE_EMERGENCY',
            idempotencyKey: idempKey,
            payload: item,
          );
        }
        final refreshed = await _queue.getPendingOperations();
        _localQueue = refreshed.map((op) {
          try {
            return jsonDecode(op.payload) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{
              'idempotency_key': op.idempotencyKey,
              'status': 'LOCAL_PENDING',
              'sync_status': 'PENDING_SYNC',
            };
          }
        }).toList();
      } catch (_) {}
    }

    // Load Citizen Profile
    final citizenStr = prefs.getString('citizen_profile');
    if (citizenStr != null) {
      try {
        final decoded = jsonDecode(citizenStr) as Map<String, dynamic>;
        _userCitizenProfile = CitizenProfile.fromJson(decoded);
      } catch (_) {
        _userCitizenProfile = null;
      }
    }

    // Load Vulnerability Profile
    final profileStr = prefs.getString('vulnerability_profile');
    if (profileStr != null) {
      try {
        final decoded = jsonDecode(profileStr) as Map<String, dynamic>;
        _userVulnerabilityProfile = VulnerabilityProfile.fromJson(decoded);
      } catch (_) {
        _userVulnerabilityProfile = null;
      }
    }

    // Load Active Emergency
    final activeStr = prefs.getString('active_emergency');
    if (activeStr != null) {
      try {
        final decoded = jsonDecode(activeStr) as Map<String, dynamic>;
        _activeEmergency = decoded;
      } catch (_) {
        _activeEmergency = null;
      }
    }

    notifyListeners();
  }

  /// Saves the citizen profile locally and attempts background server synchronization.
  Future<void> saveCitizenProfile(CitizenProfile profile, {http.Client? client}) async {
    await _initFuture;
    _userCitizenProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('citizen_profile', jsonEncode(profile.toPersistenceJson()));
    notifyListeners();

    // If online, sync to backend PUT /api/v1/profile/{user_id}
    if (_connectivity == ConnectivityState.online) {
      final httpClient = client ?? _defaultClient ?? http.Client();
      final shouldCloseClient = client == null && _defaultClient == null;
      try {
        await httpClient.put(
          Uri.parse("$apiBase/profile/$_userId"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(profile.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Citizen profile backend sync deferred (offline or unreachable): $e");
      } finally {
        if (shouldCloseClient) {
          httpClient.close();
        }
      }
    }
  }

  /// Saves the vulnerability profile locally and attempts background server synchronization.
  Future<void> saveVulnerabilityProfile(VulnerabilityProfile profile, {http.Client? client}) async {
    await _initFuture;
    _userVulnerabilityProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vulnerability_profile', jsonEncode(profile.toPersistenceJson()));
    
    // If citizen profile is not explicitly set, ensure a default so tests and onboarding stay consistent
    if (_userCitizenProfile == null) {
      _userCitizenProfile = CitizenProfile.defaultProfile();
      await prefs.setString('citizen_profile', jsonEncode(_userCitizenProfile!.toPersistenceJson()));
    }

    notifyListeners();

    // If online, sync to backend PUT /api/v1/vulnerability/{user_id}
    if (_connectivity == ConnectivityState.online) {
      final httpClient = client ?? _defaultClient ?? http.Client();
      final shouldCloseClient = client == null && _defaultClient == null;
      try {
        await httpClient.put(
          Uri.parse("$apiBase/vulnerability/$_userId"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(profile.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Vulnerability profile backend sync deferred (offline or unreachable): $e");
      } finally {
        if (shouldCloseClient) {
          httpClient.close();
        }
      }
    }
  }

  /// Skips onboarding by assigning clearly defined default citizen and vulnerability profiles.
  Future<void> skipOnboarding() async {
    if (_userCitizenProfile == null || !_userCitizenProfile!.isComplete) {
      await saveCitizenProfile(CitizenProfile.defaultProfile());
    }
    final defaultProf = VulnerabilityProfile.defaultProfile();
    await saveVulnerabilityProfile(defaultProf);
  }

  /// Submits an emergency report.
  /// 
  /// T043 IMMUTABILITY REQUIREMENT:
  /// Captures an immutable deep copy of the vulnerability profile at the exact moment
  /// of submission. The snapshot is saved within the payload and preserved in the offline
  /// queue, ensuring historical reports never change when the user later updates their profile.
  Future<Map<String, dynamic>> submitEmergency({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required int affectedCount,
    http.Client? client,
  }) async {
    await _initFuture;
    final idempotencyKey = const Uuid().v4();
    
    // T043: Deep copy snapshot of current vulnerability profile
    final Map<String, dynamic> snapshot = vulnerabilityProfile.toSnapshot();

    final payload = {
      "idempotency_key": idempotencyKey,
      "title": title,
      "description": description,
      "category": category,
      "latitude": latitude,
      "longitude": longitude,
      "affected_count": affectedCount,
      "reporter_name": citizenProfile.fullName,
      "contact_phone": citizenProfile.phoneNumber,
      "vulnerability_snapshot": Map<String, dynamic>.from(snapshot),
      "sync_status": _connectivity == ConnectivityState.online ? "SYNCING" : "PENDING_SYNC",
      "created_at": DateTime.now().toIso8601String(),
    };

    if (_connectivity == ConnectivityState.offline ||
        _connectivity == ConnectivityState.intermittent) {
      payload["status"] = "LOCAL_PENDING";
      _localQueue.add(payload);
      final savedEntry = await _repository.saveAndEnqueueEmergency(
        payload: payload,
        queue: _queue,
      );
      payload["local_id"] = savedEntry.localId;
      _activeEmergency = Map<String, dynamic>.from(payload);
      await _saveQueueLocally();
      await _saveActiveEmergencyLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": _connectivity == ConnectivityState.offline
            ? "Emergency saved to local offline queue. Will sync when online."
            : "Connection intermittent. Saved to local offline queue. Will sync when online.",
        "item": payload,
      };
    }

    final httpClient = client ?? _defaultClient ?? http.Client();
    final shouldCloseClient = client == null && _defaultClient == null;
    try {
      final res = await httpClient.post(
        Uri.parse("$apiBase/emergencies"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        data["sync_status"] = "SYNCED";
        data["idempotency_key"] ??= idempotencyKey;
        _activeEmergency = Map<String, dynamic>.from(data);
        await _repository.saveEmergencyMap(data);
        await _saveActiveEmergencyLocally();
        notifyListeners();
        return {
          "status": "SUCCESS",
          "sync_status": "SYNCED",
          "message": "Emergency synchronized with command center server.",
          "item": data,
        };
      } else if (res.statusCode == 400 || res.statusCode == 422) {
        // Client validation error from backend schema
        String detailMessage = "Server validation failed (status ${res.statusCode}).";
        try {
          final errorJson = jsonDecode(res.body);
          if (errorJson is Map && errorJson['detail'] != null) {
            detailMessage = errorJson['detail'].toString();
          }
        } catch (_) {}
        throw Exception("Validation Error (${res.statusCode}): $detailMessage");
      } else {
        // 5xx Server failure: Gracefully fall back to local queue
        payload["sync_status"] = "PENDING_SYNC";
        payload["status"] = "LOCAL_PENDING";
        payload["last_sync_error"] = "Server error ${res.statusCode}";
        _localQueue.add(payload);
        _activeEmergency = Map<String, dynamic>.from(payload);
        await _repository.saveAndEnqueueEmergency(
          payload: payload,
          queue: _queue,
        );
        await _saveQueueLocally();
        await _saveActiveEmergencyLocally();
        notifyListeners();
        return {
          "status": "SAVED_LOCALLY",
          "sync_status": "PENDING_SYNC",
          "message": "Server temporarily unavailable (status ${res.statusCode}). Saved to local queue.",
          "item": payload,
        };
      }
    } catch (e) {
      if (e is Exception && e.toString().contains("Validation Error")) {
        rethrow;
      }
      payload["sync_status"] = "PENDING_SYNC";
      payload["status"] = "LOCAL_PENDING";
      payload["last_sync_error"] = e.toString();
      _localQueue.add(payload);
      _activeEmergency = Map<String, dynamic>.from(payload);
      await _repository.saveAndEnqueueEmergency(
        payload: payload,
        queue: _queue,
      );
      await _saveQueueLocally();
      await _saveActiveEmergencyLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": "Network request failed. Saved to offline queue.",
        "item": payload,
      };
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Synchronizes pending queued emergencies using their ORIGINAL stored vulnerability snapshots via [SyncService].
  Future<List<SyncResult>> syncPendingQueue({http.Client? client}) async {
    if (_isDisposed) return [];
    // T058 Requirement 3: Queue must remain untouched when OFFLINE or INTERMITTENT
    // (unless an explicit mock client is injected for testing)
    if (_connectivity != ConnectivityState.online && client == null) {
      return [];
    }
    // T058 Requirement 4: Concurrency protection lock
    if (_isSyncing) return [];

    _isSyncing = true;
    if (!_isDisposed) notifyListeners();

    final httpClient = client ?? _defaultClient ?? http.Client();
    final shouldCloseClient = client == null && _defaultClient == null;
    List<SyncResult> results = [];
    String? latestError;

    try {
      final pendingCount = await _queue.getPendingCount();
      if (_localQueue.isEmpty && pendingCount == 0) {
        return [];
      }

      // 1. Drain pending operations via the single SyncService engine in strict FIFO order
      results = await _syncService.syncAllPending(client: httpClient);

      // 2. Reconcile in-memory _localQueue and _activeEmergency with authoritative results
      final successfulKeys = results
          .where((r) => r.isSuccess && r.idempotencyKey != null)
          .map((r) => r.idempotencyKey!)
          .toSet();

      final failedResults = {
        for (var r in results.where((r) => !r.isSuccess && r.idempotencyKey != null))
          r.idempotencyKey!: r
      };

      final remaining = <Map<String, dynamic>>[];

      for (var item in _localQueue) {
        final key = item["idempotency_key"] as String?;
        if (key != null && successfulKeys.contains(key)) {
          final result = results.firstWhere((r) => r.idempotencyKey == key);
          if (_activeEmergency != null &&
              _activeEmergency!['idempotency_key'] == key) {
            _activeEmergency =
                Map<String, dynamic>.from(result.authoritativeData ?? item)
                  ..['sync_status'] = 'SYNCED';
            await _saveActiveEmergencyLocally();
          }
        } else {
          if (key != null && failedResults.containsKey(key)) {
            final failed = failedResults[key]!;
            item["last_sync_error"] = failed.errorMessage;
            item["sync_status"] = failed.isRetryable ? 'PENDING_SYNC' : 'SYNC_FAILED';
            latestError = failed.errorMessage;
          }
          remaining.add(item);
        }
      }

      _localQueue = remaining;
      _lastSyncError = remaining.isNotEmpty ? latestError : null;
      await _saveQueueLocally();
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
      _isSyncing = false;
      if (!_isDisposed) notifyListeners();
    }

    return results;
  }

  Future<void> _saveQueueLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_queue', jsonEncode(_localQueue));
  }

  Future<void> _saveActiveEmergencyLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeEmergency != null) {
      await prefs.setString('active_emergency', jsonEncode(_activeEmergency));
    } else {
      await prefs.remove('active_emergency');
    }
  }

  /// Sets the currently tracked active emergency explicitly (e.g. for testing or selection)
  Future<void> setActiveEmergency(Map<String, dynamic>? emergency) async {
    await _initFuture;
    _activeEmergency = emergency != null ? Map<String, dynamic>.from(emergency) : null;
    await _saveActiveEmergencyLocally();
    notifyListeners();
  }

  /// Fetches emergency tracking details from the authoritative FastAPI backend
  /// (`GET /api/v1/emergencies/{id}`), or resolves from the local offline repository/queue.
  Future<EmergencyTracking> fetchEmergencyTracking(
    String emergencyId, {
    http.Client? client,
  }) async {
    await _initFuture;

    // 1. Check local offline queue first for LOCAL_PENDING item
    for (var item in _localQueue) {
      final itemId = item['id'] as String? ?? item['idempotency_key'] as String?;
      if (itemId == emergencyId || item['idempotency_key'] == emergencyId) {
        return EmergencyTracking.fromLocalEmergency(item);
      }
    }

    // 2. Check local repository
    final localRecord = await _repository.getEmergencyById(emergencyId);
    if (localRecord != null &&
        (_connectivity == ConnectivityState.offline ||
            localRecord.syncStatus == 'PENDING_SYNC' ||
            localRecord.status == 'LOCAL_PENDING')) {
      return localRecord.toTracking();
    }

    // 3. If device is offline, check if activeEmergency matches
    if (_connectivity == ConnectivityState.offline) {
      if (_activeEmergency != null) {
        final actId = _activeEmergency!['id'] as String? ?? _activeEmergency!['idempotency_key'] as String?;
        if (actId == emergencyId || _activeEmergency!['idempotency_key'] == emergencyId) {
          if (_activeEmergency!['sync_status'] == 'PENDING_SYNC' || _activeEmergency!['status'] == 'LOCAL_PENDING') {
            return EmergencyTracking.fromLocalEmergency(_activeEmergency!);
          } else {
            return EmergencyTracking.fromJson(_activeEmergency!);
          }
        }
      }
      throw Exception("Device is offline. Emergency data cannot be retrieved from server.");
    }

    // 4. Online fetch directly from backend endpoint GET /api/v1/emergencies/{id}
    final httpClient = client ?? _defaultClient ?? http.Client();
    final shouldCloseClient = client == null && _defaultClient == null;
    try {
      final res = await httpClient.get(
        Uri.parse("$apiBase/emergencies/$emergencyId"),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        data["sync_status"] = "SYNCED";
        _activeEmergency = Map<String, dynamic>.from(data);
        await _repository.saveEmergencyMap(data);
        await _saveActiveEmergencyLocally();
        notifyListeners();
        return EmergencyTracking.fromJson(data);
      } else if (res.statusCode == 404) {
        throw Exception("Emergency report not found on server.");
      } else {
        throw Exception("Server returned error ${res.statusCode} while fetching emergency tracking.");
      }
    } catch (e) {
      if (e is Exception &&
          (e.toString().contains("not found on server") ||
              e.toString().contains("Emergency report not found"))) {
        rethrow;
      }

      // If network fails but we have cached active emergency matching the ID, use it
      if (_activeEmergency != null) {
        final actId = _activeEmergency!['id'] as String? ?? _activeEmergency!['idempotency_key'] as String?;
        if (actId == emergencyId) {
          return EmergencyTracking.fromJson(_activeEmergency!);
        }
      }

      if (localRecord != null) {
        return localRecord.toTracking();
      }

      throw Exception("Network request failed: $e");
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}
