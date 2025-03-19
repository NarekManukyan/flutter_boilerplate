import 'dart:async';

import 'package:auto_route/auto_route.dart';

import '../../injectable.dart';
import '../../shared/stores/auth_store/auth_store.dart';
import '../navigation/app_router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  const AuthGuard();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await getIt<AuthStore>().getAccessToken();
    final isLoggedIn = getIt<AuthStore>().isLoggedIn;

    if (!isLoggedIn) {
      return resolver.redirect<void>(const LoginRoute());
    }

    return resolver.next();
  }
}
