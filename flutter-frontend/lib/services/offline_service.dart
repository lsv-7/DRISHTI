import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vulnerability_profile.dart';
import '../models/emergency_tracking.dart';

enum ConnectivityState { online, intermittent, offline }

class OfflineService extends ChangeNotifier {
  static const String apiBase = "http://localhost:3000/api/v1";
  
  ConnectivityState _connectivity = ConnectivityState.online;
  List<Map<String, dynamic>> _localQueue = [];
  VulnerabilityProfile? _userVulnerabilityProfile;
  Map<String, dynamic>? _activeEmergency;
  String _userId = "usr_citizen_local";
  String? _lastSyncError;
  late final Future<void> _initFuture;

  ConnectivityState get connectivity => _connectivity;
  List<Map<String, dynamic>> get localQueue => _localQueue;
  Map<String, dynamic>? get activeEmergency => _activeEmergency;
  bool get hasActiveEmergency => _activeEmergency != null || _localQueue.isNotEmpty;
  String? get lastSyncError => _lastSyncError;
  
  /// Returns the current active vulnerability profile, or a default profile if not configured.
  VulnerabilityProfile get vulnerabilityProfile =>
      _userVulnerabilityProfile ?? VulnerabilityProfile.defaultProfile();

  /// Profile completion status: completed, defaultProfile, or notCompleted.
  ProfileStatus get profileStatus =>
      _userVulnerabilityProfile?.status ?? ProfileStatus.notCompleted;

  /// True if user completed the profile or explicitly selected default.
  bool get hasCompletedOnboarding =>
      _userVulnerabilityProfile != null &&
      _userVulnerabilityProfile!.status != ProfileStatus.notCompleted;

  String get userId => _userId;

  OfflineService() {
    _initFuture = _loadLocalData();
  }

  Future<void> ensureInitialized() => _initFuture;

  void setConnectivity(ConnectivityState state) {
    _connectivity = state;
    notifyListeners();
    if (_connectivity == ConnectivityState.online) {
      syncPendingQueue();
    }
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

    // Load Pending Offline Queue
    final queueStr = prefs.getString('pending_queue') ?? '[]';
    try {
      _localQueue = List<Map<String, dynamic>>.from(jsonDecode(queueStr));
    } catch (_) {
      _localQueue = [];
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
        _activeEmergency = jsonDecode(activeStr) as Map<String, dynamic>;
      } catch (_) {
        _activeEmergency = null;
      }
    }

    notifyListeners();
  }

  /// Saves the vulnerability profile locally and attempts background server synchronization.
  Future<void> saveVulnerabilityProfile(VulnerabilityProfile profile) async {
    await _initFuture;
    _userVulnerabilityProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vulnerability_profile', jsonEncode(profile.toPersistenceJson()));
    notifyListeners();

    // If online, sync to backend PUT /api/v1/vulnerability/{user_id}
    if (_connectivity == ConnectivityState.online) {
      try {
        await http.put(
          Uri.parse("$apiBase/vulnerability/$_userId"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(profile.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Vulnerability profile backend sync deferred (offline or unreachable): $e");
      }
    }
  }

  /// Skips onboarding by assigning a clearly defined default profile.
  Future<void> skipOnboarding() async {
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
      "vulnerability_snapshot": Map<String, dynamic>.from(snapshot),
      "sync_status": _connectivity == ConnectivityState.online ? "SYNCING" : "PENDING_SYNC",
      "created_at": DateTime.now().toIso8601String(),
    };

    if (_connectivity == ConnectivityState.offline) {
      payload["status"] = "LOCAL_PENDING";
      _localQueue.add(payload);
      _activeEmergency = Map<String, dynamic>.from(payload);
      await _saveQueueLocally();
      await _saveActiveEmergencyLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": "Emergency saved to local offline queue. Will sync when online.",
        "item": payload,
      };
    }

    final httpClient = client ?? http.Client();
    try {
      final res = await httpClient.post(
        Uri.parse("$apiBase/emergencies"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        data["sync_status"] = "SYNCED";
        _activeEmergency = Map<String, dynamic>.from(data);
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
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Synchronizes pending queued emergencies using their ORIGINAL stored vulnerability snapshots.
  Future<void> syncPendingQueue({http.Client? client}) async {
    if (_localQueue.isEmpty) return;

    final httpClient = client ?? http.Client();
    List<Map<String, dynamic>> remaining = [];
    String? latestError;

    try {
      for (var item in List<Map<String, dynamic>>.from(_localQueue)) {
        try {
          final res = await httpClient.post(
            Uri.parse("$apiBase/emergencies"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(item), // Retains original vulnerability_snapshot inside item
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200 || res.statusCode == 201) {
            // Synced successfully
          } else {
            item["last_sync_error"] = "Status ${res.statusCode}";
            remaining.add(item);
            latestError = "Server rejected item (status ${res.statusCode})";
          }
        } catch (e) {
          item["last_sync_error"] = e.toString();
          remaining.add(item);
          latestError = "Network error: $e";
        }
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    _localQueue = remaining;
    _lastSyncError = remaining.isNotEmpty ? latestError : null;
    await _saveQueueLocally();
    notifyListeners();
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
  /// (`GET /api/v1/emergencies/{id}`), or resolves from the local offline queue.
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

    // 2. If device is offline, check if activeEmergency matches
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

    // 3. Online fetch directly from backend endpoint GET /api/v1/emergencies/{id}
    final httpClient = client ?? http.Client();
    try {
      final res = await httpClient.get(
        Uri.parse("$apiBase/emergencies/$emergencyId"),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        data["sync_status"] = "SYNCED";
        _activeEmergency = Map<String, dynamic>.from(data);
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

      throw Exception("Network request failed: $e");
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
