import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/constants/regexp.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/state/loading_state.dart';
import '../mobx/auth_store.dart';

part 'login_page_state.g.dart';

@injectable
class LoginPageState = _LoginPageStateBase with _$LoginPageState;

abstract class _LoginPageStateBase with Store {
  final AppNavigator _appNavigator;
  final AuthStore _authStore;

  _LoginPageStateBase(this._appNavigator, this._authStore);

  final TextEditingController emailController = TextEditingController();
  final LoadingState loadingState = LoadingState();

  @readonly
  String? _emailError;

  @action
  Future<void> onContinuePressed() async {
    final email = emailController.text.trim();
    if (!RegExp(emailRegExp).hasMatch(email)) {
      _emailError = 'invalid';
      return;
    }
    _emailError = null;
    loadingState.startLoading();
    await _authStore.login(email);
    loadingState.stopLoading();
    await _appNavigator.pushAndPopAll(const HomeRoute());
  }

  void dispose() {
    emailController.dispose();
  }
}
