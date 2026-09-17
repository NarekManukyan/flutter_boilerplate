import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/services/issue_tracking_service.dart';

part 'connectivity_store.g.dart';

// `dispose:` rather than `@disposeMethod`: injectable does not see annotations
// on the MobX base class, so the method-level marker registered nothing.
@Singleton(dispose: disposeConnectivityStore)
class ConnectivityStore = _ConnectivityStore with _$ConnectivityStore;

Future<void> disposeConnectivityStore(ConnectivityStore store) =>
    store.dispose();

abstract class _ConnectivityStore with Store {
  _ConnectivityStore(this._connectivity, this._issueTrackingService) {
    unawaited(_init());
  }

  final Connectivity _connectivity;
  final IssueTrackingService _issueTrackingService;

  // Nullable, not `late`: dispose() can run before the first status arrives,
  // and cancelling an unassigned `late` field throws.
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _disposed = false;

  @readonly
  bool _hasConnection = true;

  Future<void> _init() async {
    try {
      final initialStatus = await _connectivity.checkConnectivity();
      if (_disposed) {
        return;
      }
      _addStatus(initialStatus);
      _subscription = _connectivity.onConnectivityChanged.listen(_addStatus);
    } catch (e, stackTrace) {
      // Stay "online": the offline page would otherwise lock the user out
      // over a plugin failure they cannot fix.
      _issueTrackingService.trackSilentError(
        e,
        stackTrace: stackTrace,
        context: 'connectivity_init',
      );
    }
  }

  @action
  void _addStatus(List<ConnectivityResult> result) {
    _hasConnection = result.any(_isConnectionType);
  }

  /// App-wide store: disposed by GetIt on reset, never by a screen.
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
  }

  bool _isConnectionType(ConnectivityResult result) {
    return const [
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
    ].contains(result);
  }
}
