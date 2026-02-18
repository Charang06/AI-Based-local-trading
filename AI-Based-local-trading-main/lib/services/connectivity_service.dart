import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get isOnlineStream => _controller.stream;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    Connectivity().onConnectivityChanged.listen((r) {
      _controller.add(r != ConnectivityResult.none);
    });

    // initial check
    Connectivity().checkConnectivity().then((r) {
      _controller.add(r != ConnectivityResult.none);
    });
  }

  void dispose() => _controller.close();
}
