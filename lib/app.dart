import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:overlay_support/overlay_support.dart';

import 'core/navigation/app_navigator.dart';
import 'core/services/flavor_service.dart';
import 'injectable.dart';
import 'shared/features/connection_wrapper/view/connection_wrapper_page.dart';

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: context.theme.brightness,
      ),
      child: OverlaySupport.global(
        child: DefaultTextHeightBehavior(
          textHeightBehavior: const TextHeightBehavior(
            leadingDistribution: TextLeadingDistribution.even,
          ),
          child: MaterialApp.router(
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            debugShowCheckedModeBanner: GetIt.I<FlavorService>().isDev,
            theme: lightTheme,
            darkTheme: lightTheme,
            routerConfig: getIt<AppNavigator>().config,
            builder: (context, child) {
              return ConnectionWrapperPage(child: child!);
            },
          ),
        ),
      ),
    );
  }
}
