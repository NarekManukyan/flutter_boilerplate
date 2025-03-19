import 'dart:async';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/social_provider_enum.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/social_auth_service.dart';
import '../../../shared/state/loading_state/loading_state.dart';

part 'login_page_state.g.dart';

@injectable
class LoginPageState = _LoginPageStateBase with _$LoginPageState;

abstract class _LoginPageStateBase with Store {
  final AppNavigator _appNavigator;
  final SocialAuthService _socialAuthService;

  final loadingState = LoadingState();
  final socialLoadingState = LoadingState();

  _LoginPageStateBase(
    this._appNavigator,
    this._socialAuthService,
  );

  Future<void> onEmailTap() async {}

  Future<void> onSocialLoginTap(SocialProviderEnum provider) async {
    try {
      final isLogged = await _onSelectProvider(provider);
      log('isLogged: $isLogged');
    } finally {
      socialLoadingState.stopLoading();
    }
  }

  Future<bool?> _onSelectProvider(SocialProviderEnum provider) async {
    try {
      final code = await switch (provider) {
        SocialProviderEnum.APPLE => _socialAuthService.signInByApple(),
        SocialProviderEnum.GOOGLE => _socialAuthService.signInByGoogle(),
      };

      if (code == null) {
        return false;
      }
      socialLoadingState.startLoading();
      await _onSocialLogin(code, provider);

      return true;
    } catch (e) {
      log('Error on select provider: $e');
      return false;
    }
  }

  Future<void> _onSocialLogin(String code, SocialProviderEnum provider) async {
    try {
      // TODO: Implement social login
    } catch (e) {
      log('Error on social login: $e');
    }
  }

  void openExternalUrl(String url) {
    launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}
