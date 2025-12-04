import 'dart:async';
import 'dart:io';

/// Service for monitoring network connectivity
class ConnectivityService {
  /// Private constructor for singleton pattern
  ConnectivityService._();

  /// Singleton instance
  static final ConnectivityService instance = ConnectivityService._();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  bool _isConnected = true;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  Timer? _periodicCheck;

  /// Initialize connectivity monitoring
  void initialize() {
    // Check initial connectivity
    _checkConnectivity();

    // Periodic connectivity checks (every 5 seconds)
    _periodicCheck = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnectivity(),
    );
  }

  /// Check current connectivity by attempting to lookup a host
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        _connectionController.add(_isConnected);
      }
    } catch (e) {
      // Network is unavailable
      if (_isConnected) {
        _isConnected = false;
        _connectionController.add(false);
      }
    }
  }

  /// Force a connectivity check
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _periodicCheck?.cancel();
    _connectionController.close();
  }
}
