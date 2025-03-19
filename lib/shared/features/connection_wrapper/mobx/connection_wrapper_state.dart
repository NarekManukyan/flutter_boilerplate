import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import '../../../../core/utils/debounce_reaction.dart';
import '../../../stores/connectivity/connectivity_store.dart';

part 'connection_wrapper_state.g.dart';

@injectable
class ConnectionWrapperState = _ConnectionWrapperStateBase
    with _$ConnectionWrapperState;

abstract class _ConnectionWrapperStateBase with Store {
  final ConnectivityStore _connectivityStore;

  _ConnectionWrapperStateBase(
    this._connectivityStore,
  ) {
    debounceReaction(
      (_) => _connectivityStore.hasConnection,
      _onConnectivityChange,
      delay: 200,
      fireImmediately: true,
    );
  }

  @readonly
  bool _hasConnection = true;

  @action
  void _onConnectivityChange(bool hasConnection) {
    _hasConnection = hasConnection;
  }

  Future<bool> onSettingsTap() {
    return switch (OpenSettingsPlus.shared) {
      final OpenSettingsPlusAndroid settings => settings.wifi(),
      final OpenSettingsPlusIOS settings => settings.wifi(),
      _ => throw Exception('Platform not supported'),
    };
  }

  void dispose() {
    _connectivityStore.dispose();
  }
}
