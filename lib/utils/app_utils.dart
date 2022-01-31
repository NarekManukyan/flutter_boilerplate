import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/device_type.dart';
import '../providers/screen_service.dart';

Future<void> openPrivacyPolicy(BuildContext context) async {
  const url = 'https://rexi.app/terms-of-service.html';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Could not open Terms of Service and Privacy Policy',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20),
              const Text('please copy link and open manually in browser'),
              TextFormField(
                initialValue: url,
                readOnly: true,
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}

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
