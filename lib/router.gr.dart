// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i4;
import 'package:flutter/material.dart' as _i5;

import 'pages/dashboard/dashboard_page.dart' as _i3;
import 'pages/login_page/login_page.dart' as _i2;
import 'pages/splash_screen/splash_screen.dart' as _i1;

class Router extends _i4.RootStackRouter {
  Router([_i5.GlobalKey<_i5.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    SplashScreenRoute.name: (routeData) {
      return _i4.AdaptivePage<dynamic>(
          routeData: routeData,
          child: const _i1.SplashScreenPage(),
          fullscreenDialog: true);
    },
    LoginRoute.name: (routeData) {
      return _i4.AdaptivePage<dynamic>(
          routeData: routeData,
          child: const _i2.LoginPage(),
          fullscreenDialog: true);
    },
    DashboardRoute.name: (routeData) {
      return _i4.AdaptivePage<dynamic>(
          routeData: routeData, child: const _i3.DashboardPage());
    }
  };

  @override
  List<_i4.RouteConfig> get routes => [
        _i4.RouteConfig(SplashScreenRoute.name, path: '/'),
        _i4.RouteConfig(LoginRoute.name, path: '/login-page'),
        _i4.RouteConfig(DashboardRoute.name, path: '/dashboard-page')
      ];
}

/// generated route for
/// [_i1.SplashScreenPage]
class SplashScreenRoute extends _i4.PageRouteInfo<void> {
  const SplashScreenRoute() : super(SplashScreenRoute.name, path: '/');

  static const String name = 'SplashScreenRoute';
}

/// generated route for
/// [_i2.LoginPage]
class LoginRoute extends _i4.PageRouteInfo<void> {
  const LoginRoute() : super(LoginRoute.name, path: '/login-page');

  static const String name = 'LoginRoute';
}

/// generated route for
/// [_i3.DashboardPage]
class DashboardRoute extends _i4.PageRouteInfo<void> {
  const DashboardRoute() : super(DashboardRoute.name, path: '/dashboard-page');

  static const String name = 'DashboardRoute';
}
