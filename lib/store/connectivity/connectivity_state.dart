import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobx/mobx.dart';

part 'connectivity_state.g.dart';

class ConnectivityState = _ConnectivityState with _$ConnectivityState;

abstract class _ConnectivityState with Store {
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @observable
  bool hasConnection = true;

  _ConnectivityState() {
    init();
  }

  bool setConnection(ConnectivityResult currentStatus) => [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
      ].contains(currentStatus);

  Future<void> init() async {
    // Get the initial connectivity status.
    final initialStatus = await connectivity.checkConnectivity();
    _addStatus(initialStatus);

    // Subscribe to connectivity changes.
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_addStatus);
  }

  void _addStatus(List<ConnectivityResult> result) {
    hasConnection = setConnection(result.first);
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
