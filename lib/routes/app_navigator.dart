import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Router;
import 'app_router.dart';
export 'app_router.dart';

class AppNavigator {
  final router = AppRouter();

  Future<bool> pop<T extends Object?>({T? result}) {
    return router.maybePop(result);
  }

  Future<void> popUntilRouteWithName(String routeName) async {
    router.popUntilRouteWithName(routeName);
  }

  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.push(route, onFailure: onFailure);
  }

  Future<void> pushAndPopAll(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.replaceAll([route], onFailure: onFailure);
  }

  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    return router.replace(route, onFailure: onFailure);
  }

  Future<T?> showModal<T>(
    WidgetBuilder builder, {
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useRootNavigator = true,
    bool useSafeArea = true,
  }) {
    final context = router.navigatorKey.currentContext;
    if (context == null) {
      return Future.error(Exception('Context is null'));
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: builder,
    );
  }
}
