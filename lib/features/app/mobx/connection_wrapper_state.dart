import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

import '../../../core/constants/timing_constants.dart';
import '../../../core/utils/debounce_reaction.dart';
import './connectivity_store.dart';

part 'connection_wrapper_state.g.dart';

@injectable
class ConnectionWrapperState = _ConnectionWrapperStateBase
    with _$ConnectionWrapperState;

abstract class _ConnectionWrapperStateBase with Store {
  final ConnectivityStore _connectivityStore;
  late final ReactionDisposer _connectivityReaction;

  _ConnectionWrapperStateBase(this._connectivityStore) {
    _connectivityReaction = debounceReaction(
      (_) => _connectivityStore.hasConnection,
      _onConnectivityChange,
      delay: TimingConstants.connectivityDebounce,
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

  // Disposes only what this state created. ConnectivityStore is an app-wide
  // singleton: disposing it here cancelled connectivity tracking for the rest
  // of the session the first time this page unmounted.
  void dispose() {
    _connectivityReaction();
  }
}
