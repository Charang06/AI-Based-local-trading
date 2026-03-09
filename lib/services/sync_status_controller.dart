import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Global app sync/connection state (for UI banner + auto sync)
class SyncStatusController extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<BoxEvent>? _outboxSub;

  bool _isOnline = false;
  bool _isSyncing = false;
  int _pending = 0;
  String? _lastError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pending => _pending;
  String? get lastError => _lastError;

  /// Start listening (bind outbox + auto-sync when internet comes back)
  Future<void> start({
    required Box outbox,
    required Future<void> Function() performSync,
  }) async {
    _bindOutbox(outbox);

    // initial real internet check
    await _refreshInternetStatus();

    // listen connectivity changes -> re-check real internet
    _connSub?.cancel();
    _connSub = _connectivity.onConnectivityChanged.listen((_) async {
      final wasOnline = _isOnline;
      await _refreshInternetStatus();

      // auto-sync when internet returns
      if (!wasOnline && _isOnline) {
        await Future.delayed(const Duration(milliseconds: 300));
        await syncNow(performSync);
      }
    });
  }

  /// Watch Hive outbox so pending updates automatically
  void _bindOutbox(Box outbox) {
    _pending = outbox.length;
    notifyListeners();

    _outboxSub?.cancel();
    _outboxSub = outbox.watch().listen((_) {
      final v = outbox.length;
      if (v != _pending) {
        _pending = v;
        notifyListeners();
      }
    });
  }

  /// Real internet check (Wi-Fi icon is not enough)
  Future<void> _refreshInternetStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);

      if (!hasNetwork) {
        _setOnline(false);
        return;
      }

      // ✅ correct API (works with your dependency)
      final ok = await InternetConnection().hasInternetAccess;
      _setOnline(ok);
    } catch (_) {
      // fallback: don't block user
      _setOnline(true);
    }
  }

  void _setOnline(bool v) {
    if (_isOnline == v) return;
    _isOnline = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _lastError = msg;
    notifyListeners();
  }

  /// Manual sync trigger
  Future<void> syncNow(Future<void> Function() performSync) async {
    if (_isSyncing) return;
    if (!_isOnline) return;

    _lastError = null;
    _isSyncing = true;
    notifyListeners();

    try {
      await performSync();
      // pending is updated by outbox.watch()
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _outboxSub?.cancel();
    super.dispose();
  }
}
