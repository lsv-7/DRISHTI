import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vulnerability_profile.dart';

enum ConnectivityState { online, intermittent, offline }

class OfflineService extends ChangeNotifier {
  static const String apiBase = "http://localhost:3000/api/v1";
  
  ConnectivityState _connectivity = ConnectivityState.online;
  List<Map<String, dynamic>> _localQueue = [];
  VulnerabilityProfile? _userVulnerabilityProfile;
  String _userId = "usr_citizen_local";
  late final Future<void> _initFuture;

  ConnectivityState get connectivity => _connectivity;
  List<Map<String, dynamic>> get localQueue => _localQueue;
  
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
      _localQueue.add(payload);
      await _saveQueueLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": "Emergency saved to local offline queue. Will sync when online.",
        "item": payload,
      };
    }

    try {
      final res = await http.post(
        Uri.parse("$apiBase/emergencies"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        data["sync_status"] = "SYNCED";
        return {
          "status": "SUCCESS",
          "sync_status": "SYNCED",
          "message": "Emergency synchronized with command center server.",
          "item": data,
        };
      } else {
        throw Exception("Server responded with status ${res.statusCode}");
      }
    } catch (e) {
      payload["sync_status"] = "PENDING_SYNC";
      _localQueue.add(payload);
      await _saveQueueLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": "Network request failed. Saved to offline queue.",
        "item": payload,
      };
    }
  }

  /// Synchronizes pending queued emergencies using their ORIGINAL stored vulnerability snapshots.
  Future<void> syncPendingQueue() async {
    if (_localQueue.isEmpty) return;

    List<Map<String, dynamic>> remaining = [];
    for (var item in List<Map<String, dynamic>>.from(_localQueue)) {
      try {
        final res = await http.post(
          Uri.parse("$apiBase/emergencies"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(item), // Retains original vulnerability_snapshot inside item
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode != 200 && res.statusCode != 201) {
          remaining.add(item);
        }
      } catch (e) {
        remaining.add(item);
      }
    }

    _localQueue = remaining;
    await _saveQueueLocally();
    notifyListeners();
  }

  Future<void> _saveQueueLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_queue', jsonEncode(_localQueue));
  }
}
