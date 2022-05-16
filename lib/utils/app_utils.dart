import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../constants/device_type.dart';
import '../providers/screen_service.dart';

Future<Route> getCurrentRoute() {
  final completer = Completer<Route>();
  router.popUntil((currentRoute) {
    completer.complete(currentRoute);
    return true;
  });

  return completer.future;
}

RouteConfig getRouteConfigs(String name) {
  return router.routes.firstWhere((element) => element.name == name);
}

Future<bool> isCurrentRoute(String routeName) async {
  final currentRoute = await getCurrentRoute();

  return currentRoute.settings.name == routeName;
}

DeviceType getDeviceType() {
  final mediaQueryData = MediaQuery.of(router.navigatorKey.currentContext!);
  return mediaQueryData.size.shortestSide < 600
      ? DeviceType.PHONE
      : DeviceType.TABLET;
}

bool isPhone() {
  return getDeviceType() == DeviceType.PHONE;
}

bool isTablet() {
  return getDeviceType() == DeviceType.TABLET;
}
