import 'package:auto_route/auto_route.dart';

import 'pages/dashboard/dashboard_page.dart';
import 'pages/login_page/login_page.dart';
import 'pages/splash_screen/splash_screen.dart';

export 'router.gr.dart';

@AdaptiveAutoRouter(
  preferRelativeImports: true,
  replaceInRouteName: 'Page,Route',
  routes: [
    AdaptiveRoute(
      page: SplashScreenPage,
      initial: true,
      fullscreenDialog: true,
    ),
    AdaptiveRoute(
      page: LoginPage,
      fullscreenDialog: true,
    ),
    AdaptiveRoute(
      page: DashboardPage,
    ),
  ],
)
class $Router {}
