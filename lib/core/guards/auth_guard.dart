import 'dart:async';

import 'package:auto_route/auto_route.dart';

import '../../features/auth/mobx/auth_store.dart';
import '../../injectable.dart';
import '../navigation/app_router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  const AuthGuard();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await getIt<AuthStore>().getAccessToken();
    final isAuthed = getIt<AuthStore>().isAuthed;

    if (!isAuthed) {
      resolver.redirectUntil(const LoginRoute());
      return;
    }

    resolver.next();
  }
}
