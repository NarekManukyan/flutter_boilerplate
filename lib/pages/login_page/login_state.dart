import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../routes/app_navigator.dart';
import '../../store/auth_store/auth_store.dart';
import '../../store/loading_state/loading_state.dart';

part 'login_state.g.dart';

class LoginState = LoginStateBase with _$LoginState;

abstract class LoginStateBase with Store {
  final _appNavigator = GetIt.I<AppNavigator>();
  final _authStore = GetIt.I<AuthStore>();
  final _disposers = <ReactionDisposer>[];
  final loadingState = LoadingState();

  @readonly
  String _email = '';
  @readonly
  String _password = '';

  @readonly
  String? _emailError = '';
  @readonly
  String? _passwordError = '';

  @computed
  bool get isLoading => loadingState.isLoading;

  @action
  void setEmail(String value) {
    _email = value;
  }

  @action
  void setPassword(String value) {
    _password = value;
  }

  void setupValidations() {
    _disposers.addAll(
      [
        reaction(
          (_) => _email,
          validateEmail,
          fireImmediately: true,
        ),
        reaction(
          (_) => _password,
          validatePassword,
          fireImmediately: true,
        ),
      ],
    );
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }

  @action
  void validateEmail(_) {
    if (_email.isEmpty) {
      _emailError = 'localValidationError.phone';
    } else {
      _emailError = null;
    }
  }

  @action
  void validatePassword(_) {
    if (_password.isEmpty) {
      _passwordError = 'localValidationError.phone';
    } else {
      _passwordError = null;
    }
  }

  Future<void> onLogin() async {
    loadingState.startLoading();
    setupValidations();
    if (_emailError == null && _passwordError == null) {
      Future.delayed(const Duration(seconds: 2), () {
        _authStore.getCurrentUser();
        _appNavigator.push(const DashboardRoute());
      });
    }
    loadingState.stopLoading();
  }
}
