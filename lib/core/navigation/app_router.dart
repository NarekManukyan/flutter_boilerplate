import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../guards/auth_guard.dart';
import 'app_router.gr.dart';

export 'app_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Page,Route',
)
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      initial: true,
      path: '/',
      page: SplashRoute.page,
      guards: const [AuthGuard()],
    ),
    AutoRoute(page: LoginRoute.page),
  ];
}

@RoutePage()
class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.backgroundSurface,
    );
  }
}
