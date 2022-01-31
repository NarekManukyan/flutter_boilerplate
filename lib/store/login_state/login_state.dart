import 'package:mobx/mobx.dart';

part 'login_state.g.dart';

class LoginState = _LoginState with _$LoginState;

abstract class _LoginState with Store {
  _LoginState() {
    setupValidations();
  }

  @observable
  String email = '';
  @observable
  String password = '';

  @observable
  String? emailError = '';
  @observable
  String? passwordError = '';

  List<ReactionDisposer>? _disposers;

  void setupValidations() {
    if (_disposers != null) {
      return;
    }
    _disposers = [
      reaction((_) => email, validateEmail),
      reaction((_) => password, validatePassword),
    ];
  }

  void dispose() {
    if (_disposers == null) {
      return;
    }
    for (final d in _disposers!) {
      d();
    }
  }

  @action
  void validateEmail(_) {
    if (email.isEmpty) {
      emailError = 'localValidationError.phone';
    } else {
      emailError = null;
    }
  }

  @action
  void validatePassword(_) {
    if (password.isEmpty) {
      passwordError = 'localValidationError.phone';
    } else {
      passwordError = null;
    }
  }
}
