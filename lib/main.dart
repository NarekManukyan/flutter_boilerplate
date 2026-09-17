import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_logging/sentry_logging.dart';

import 'app.dart';
import 'core/constants/flavor_type.dart';
import 'core/constants/supported_locals.dart';
import 'core/services/flavor_service.dart';
import 'core/services/get_it.dart';
import 'injectable.dart';

Future<void> run({FlavorType env = FlavorType.DEVELOPMENT}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();

  registerGetIt(env);

  if (kDebugMode) {
    _runApp();
    return;
  }

  await SentryFlutter.init((options) {
    options
      ..environment = env.toString()
      ..dsn = getIt<FlavorService>().config.sentryDsn
      // Every transaction in development; a sample in production, where 100%
      // costs quota and battery for no extra signal.
      ..tracesSampleRate = env == FlavorType.PROD ? 0.2 : 1.0
      // No attachScreenshot: it did nothing without a SentryWidget, and a
      // screenshot of an error screen can carry user data.
      ..addIntegration(LoggingIntegration());
  }, appRunner: _runApp);
}

void _runApp() {
  runApp(
    EasyLocalization(
      supportedLocales: SupportedLocals.values.map((e) => e.getLocal).toList(),
      startLocale: SupportedLocals.EN.getLocal,
      fallbackLocale: SupportedLocals.EN.getLocal,
      path: 'assets/translations',
      child: const MyApp(),
    ),
  );
}

Future<void> main() async {
  await run();
}
