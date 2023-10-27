import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:overlay_support/overlay_support.dart';

import 'providers/flavor_service.dart';
import 'providers/screen_service.dart';
import 'store/connectivity/connectivity_state.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';

class MyApp extends HookWidget {
  const MyApp({Key? key}) : super(key: key);

  ConnectivityState get _connectivityState => GetIt.I<ConnectivityState>();

  @override
  Widget build(BuildContext context) {
    final _onConnectivityChange = useCallback<void Function(bool)>(
      (hasConnection) {
        showSimpleNotification(
          Text(
            hasConnection ? 'connectionRestored' : 'connectionLost',
          ),
          slideDismissDirection: DismissDirection.up,
          duration: Duration(seconds: hasConnection ? 3 : 3600),
          elevation: 0,
          contentPadding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: kToolbarHeight,
          ),
          background: Colors.transparent,
          key: const ValueKey('Connection'),
        );
      },
    );

    useMemoized(
      () => reaction<bool>(
        (_) => _connectivityState.hasConnection,
        _onConnectivityChange,
        delay: 200,
      ),
    );

    return OverlaySupport.global(
      child: DefaultTextHeightBehavior(
        textHeightBehavior: const TextHeightBehavior(
          leadingDistribution: TextLeadingDistribution.even,
        ),
        child: MaterialApp.router(
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          debugShowCheckedModeBanner: GetIt.I<FlavorService>().isDevelopment,
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: router.config(),
        ),
      ),
    );
  }
}
