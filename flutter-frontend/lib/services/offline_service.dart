import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum ConnectivityState { ONLINE, INTERMITTENT, OFFLINE }

class OfflineService extends ChangeNotifier {
  static const String apiBase = "http://localhost:3000/api/v1";
  ConnectivityState _connectivity = ConnectivityState.ONLINE;
  List<Map<String, dynamic>> _localQueue = [];
  Map<String, dynamic>? _userVulnerabilityProfile;

  ConnectivityState get connectivity => _connectivity;
  List<Map<String, dynamic>> get localQueue => _localQueue;
  Map<String, dynamic>? get userVulnerabilityProfile => _userVulnerabilityProfile;

  OfflineService() {
    _loadLocalData();
  }

  void setConnectivity(ConnectivityState state) {
    _connectivity = state;
    notifyListeners();
    if (_connectivity == ConnectivityState.ONLINE) {
      syncPendingQueue();
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString('pending_queue') ?? '[]';
    _localQueue = List<Map<String, dynamic>>.from(jsonDecode(queueStr));

    final profileStr = prefs.getString('vulnerability_profile');
    if (profileStr != null) {
      _userVulnerabilityProfile = jsonDecode(profileStr);
    }
    notifyListeners();
  }

  Future<void> saveVulnerabilityProfile(Map<String, dynamic> profile) async {
    _userVulnerabilityProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vulnerability_profile', jsonEncode(profile));
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitEmergency({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required int affectedCount,
  }) async {
    final idempotencyKey = const Uuid().v4();
    final payload = {
      "idempotency_key": idempotencyKey,
      "title": title,
      "description": description,
      "category": category,
      "latitude": latitude,
      "longitude": longitude,
      "affected_count": affectedCount,
      "vulnerability_snapshot": _userVulnerabilityProfile,
      "sync_status": _connectivity == ConnectivityState.ONLINE ? "SYNCING" : "PENDING_SYNC",
      "created_at": DateTime.now().toIso8601String(),
    };

    if (_connectivity == ConnectivityState.OFFLINE) {
      _localQueue.add(payload);
      await _saveQueueLocally();
      notifyListeners();
      return {
        "status": "SAVED_LOCALLY",
        "sync_status": "PENDING_SYNC",
        "message": "Emergency saved to local offline queue. Will sync when online.",
        "item": payload
      };
    }

    try {
      final res = await http.post(
        Uri.parse("$apiBase/emergencies"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        data["sync_status"] = "SYNCED";
        return {
          "status": "SUCCESS",
          "sync_status": "SYNCED",
          "message": "Emergency synchronized with command center server.",
          "item": data
        };
      } else {
        throw Exception("Server status ${res.statusCode}");
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
        "item": payload
      };
    }
  }

  Future<void> syncPendingQueue() async {
    if (_localQueue.isEmpty) return;

    List<Map<String, dynamic>> remaining = [];
    for (var item in _localQueue) {
      try {
        final res = await http.post(
          Uri.parse("$apiBase/emergencies"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(item),
        );
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
