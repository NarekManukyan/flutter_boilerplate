import 'package:auto_route/auto_route.dart';

import '../guards/auth_guard.dart';
import 'app_router.gr.dart';

export 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required AuthGuard authGuard}) : _authGuard = authGuard;

  final AuthGuard _authGuard;

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      initial: true,
      path: '/',
      page: SplashRoute.page,
      guards: [_authGuard],
    ),
    AutoRoute(path: '/login', page: LoginRoute.page),
    AutoRoute(path: '/home', page: HomeRoute.page, guards: [_authGuard]),
    AutoRoute(
      path: '/todos/:id',
      page: TodoDetailsRoute.page,
      guards: [_authGuard],
    ),
    AutoRoute(
      path: '/challenges/joined',
      page: ChallengeJoinedRoute.page,
      fullscreenDialog: true,
      guards: [_authGuard],
    ),
  ];
}
