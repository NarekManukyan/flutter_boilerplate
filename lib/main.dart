import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'constants/flavor_type.dart';
import 'constants/supported_locals.dart';
import 'providers/get_it.dart';

Future<void> run({Flavor env = Flavor.DEV}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();

  registerGetIt(env);

  runApp(
    EasyLocalization(
      supportedLocales: SupportedLocals.values
          .map(
            (e) => e.getLocal,
      )
          .toList(),
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
