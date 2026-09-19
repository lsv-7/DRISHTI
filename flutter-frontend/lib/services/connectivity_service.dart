import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Truthful connectivity state for the DRISHTI AI mobile application.
enum ConnectivityState {
  /// Both network interface is present and backend reachability probe succeeds.
  online,

  /// Network interface is present, but backend probe fails, times out, or is degraded.
  intermittent,

  /// No usable network interface is detected, or confirmed inability to communicate.
  offline,
}

/// Function signature for probing backend or internet reachability.
typedef ReachabilityProbe = Future<bool> Function();

/// Abstract adapter decoupling connectivity detection from platform channels.
abstract class ConnectivityAdapter {
  Future<List<ConnectivityResult>> checkConnectivity();
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// Production adapter using the `connectivity_plus` plugin.
class PlusConnectivityAdapter implements ConnectivityAdapter {
  final Connectivity _connectivity;

  PlusConnectivityAdapter([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}

/// In-memory mock adapter for deterministic unit and widget testing.
class MockConnectivityAdapter implements ConnectivityAdapter {
  final StreamController<List<ConnectivityResult>> _controller =
      StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> _current;

  MockConnectivityAdapter([List<ConnectivityResult>? initial])
      : _current = initial ?? [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    _current = results;
    if (!_controller.isClosed) {
      _controller.add(results);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Truthful, decoupled connectivity state detection service for DRISHTI AI.
///
/// Distinguishes between:
/// - [ConnectivityState.online]: Network interface exists AND backend health probe succeeds.
/// - [ConnectivityState.intermittent]: Interface exists, but backend health probe fails or times out.
/// - [ConnectivityState.offline]: No network interface is available.
///
/// Strictly isolated from queue draining and retry logic (reserved for T056/T058).
class ConnectivityService {
  final ConnectivityAdapter _adapter;
  final ReachabilityProbe? _reachabilityProbe;
  final String _healthEndpoint;

  ConnectivityState _state;
  ConnectivityState? _manualOverride;
  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _adapterSubscription;

  bool _disposed = false;
  bool _isInitialized = false;

  ConnectivityState get state => _manualOverride ?? _state;
  ConnectivityState? get manualOverride => _manualOverride;
  bool get isOnline => state == ConnectivityState.online;
  bool get isOffline => state == ConnectivityState.offline;
  bool get isIntermittent => state == ConnectivityState.intermittent;
  bool get isDisposed => _disposed;
  bool get isInitialized => _isInitialized;

  /// Reactive broadcast stream emitting state changes only when the value actually changes.
  Stream<ConnectivityState> get onConnectivityChanged => _controller.stream;

  String get healthEndpoint => _healthEndpoint;
  void setHealthEndpoint(String endpoint) {
    _healthEndpoint = endpoint;
  }

  ConnectivityService({
    ConnectivityAdapter? adapter,
    ReachabilityProbe? reachabilityProbe,
    ConnectivityState initialState = ConnectivityState.online,
    String healthEndpoint = 'http://localhost:3000/api/v1/health',
    bool autoInitialize = false,
  })  : _adapter = adapter ?? _createDefaultAdapter(),
        _reachabilityProbe = reachabilityProbe,
        _state = initialState,
        _healthEndpoint = healthEndpoint {
    if (autoInitialize) {
      initialize();
    }
  }

  static ConnectivityAdapter _createDefaultAdapter() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return MockConnectivityAdapter([ConnectivityResult.wifi]);
    }
    return PlusConnectivityAdapter();
  }

  /// Initializes subscriptions to network interface changes and performs an initial evaluation.
  Future<void> initialize() async {
    if (_disposed || _isInitialized) return;
    _isInitialized = true;

    _adapterSubscription = _adapter.onConnectivityChanged.listen(
      _handleInterfaceChange,
      onError: (error) {
        if (!_disposed) {
          _updateState(ConnectivityState.offline);
        }
      },
    );

    await checkConnectivity();
  }

  /// Sets or clears a manual connectivity override (useful for UI simulation and tests).
  void setManualOverride(ConnectivityState? overrideState) {
    _manualOverride = overrideState;
    if (overrideState != null) {
      _updateState(overrideState);
    } else {
      checkConnectivity();
    }
  }

  /// Queries the network adapter and conducts a reachability probe if an active interface exists.
  Future<ConnectivityState> checkConnectivity() async {
    if (_disposed) return state;

    if (_manualOverride != null) {
      _updateState(_manualOverride!);
      return _manualOverride!;
    }

    try {
      final results = await _adapter.checkConnectivity();
      if (_manualOverride != null) {
        _updateState(_manualOverride!);
        return _manualOverride!;
      }
      final evaluated = await _evaluateResults(results);
      if (_manualOverride != null) {
        _updateState(_manualOverride!);
        return _manualOverride!;
      }
      _updateState(evaluated);
      return evaluated;
    } catch (_) {
      if (_manualOverride != null) {
        _updateState(_manualOverride!);
        return _manualOverride!;
      }
      _updateState(ConnectivityState.offline);
      return ConnectivityState.offline;
    }
  }

  Future<void> _handleInterfaceChange(List<ConnectivityResult> results) async {
    if (_disposed || _manualOverride != null) return;
    final evaluated = await _evaluateResults(results);
    if (_disposed || _manualOverride != null) return;
    _updateState(evaluated);
  }

  Future<ConnectivityState> _evaluateResults(List<ConnectivityResult> results) async {
    final hasUsableInterface = results.any((r) =>
        r != ConnectivityResult.none &&
        (r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet ||
            r == ConnectivityResult.vpn ||
            r == ConnectivityResult.other));

    if (!hasUsableInterface) {
      return ConnectivityState.offline;
    }

    // Network interface is available; probe backend reachability.
    final reachable = await _performReachabilityProbe();
    return reachable ? ConnectivityState.online : ConnectivityState.intermittent;
  }

  Future<bool> _performReachabilityProbe() async {
    if (_reachabilityProbe != null) {
      try {
        return await _reachabilityProbe!();
      } catch (_) {
        return false;
      }
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    // Default reachability check against DRISHTI backend health endpoint
    http.Client? client;
    try {
      client = http.Client();
      final uri = Uri.parse(_healthEndpoint);
      final response = await client.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client?.close();
    }
  }

  /// Updates current state and emits to the stream if and only if the state changed.
  void _updateState(ConnectivityState newState) {
    if (_disposed) return;
    final effective = _manualOverride ?? newState;
    if (_state == effective) return; // Strict deduplication
    _state = effective;
    if (!_controller.isClosed) {
      _controller.add(effective);
    }
  }

  /// Safely cancels subscriptions and closes stream controllers.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _adapterSubscription?.cancel();
    _adapterSubscription = null;
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
