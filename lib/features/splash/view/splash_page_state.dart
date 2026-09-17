import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../auth/mobx/auth_store.dart';

part 'splash_page_state.g.dart';

@injectable
class SplashPageState = _SplashPageStateBase with _$SplashPageState;

abstract class _SplashPageStateBase with Store {
  _SplashPageStateBase(this._authStore, this._appNavigator);

  final AuthStore _authStore;
  final AppNavigator _appNavigator;

  /// Decides where the app starts. The splash route used to sit behind
  /// AuthGuard, which let a signed-in user through to the splash page and then
  /// left them there: nothing ever navigated on.
  Future<void> init() async {
    await _authStore.getAccessToken();
    await _appNavigator.pushAndPopAll(
      _authStore.isAuthed ? const HomeRoute() : const LoginRoute(),
    );
  }

  void dispose() {}
}
