import 'package:auto_route/auto_route.dart';

import '../pages/dashboard/dashboard_page.dart';
import '../pages/login_page/login_page.dart';
import '../pages/splash_screen/splash_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(
      initial: true,
      path: '/',
      page: SplashRoute.page,
    ),
    AutoRoute(
      page: LoginRoute.page,
    ),

    AutoRoute(
      page: DashboardRoute.page,
    ),
  ];
}
