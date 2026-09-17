import 'dart:async';

import 'package:auto_route/auto_route.dart';

import '../../features/auth/mobx/auth_store.dart';
import '../navigation/app_router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authStore);

  final AuthStore _authStore;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await _authStore.getAccessToken();

    if (!_authStore.isAuthed) {
      resolver.redirectUntil(const LoginRoute());
      return;
    }

    resolver.next();
  }
}
