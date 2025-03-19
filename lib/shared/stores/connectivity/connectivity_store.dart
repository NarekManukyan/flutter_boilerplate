import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

part 'connectivity_store.g.dart';

@singleton
class ConnectivityStore = _ConnectivityStore with _$ConnectivityStore;

abstract class _ConnectivityStore with Store {
  final Connectivity connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @observable
  bool hasConnection = true;

  _ConnectivityStore() {
    _init();
  }

  Future<void> _init() async {
    final initialStatus = await connectivity.checkConnectivity();
    _addStatus(initialStatus);

    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_addStatus);
  }

  @action
  void _addStatus(List<ConnectivityResult> result) {
    hasConnection = _checkConnectionType(result);
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  bool _checkConnectionType(List<ConnectivityResult> result) {
    return result.any(_isConnectionType);
  }

  bool _isConnectionType(ConnectivityResult result) {
    return [
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
    ].contains(result);
  }
}
