import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/easy_localization_controller.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared widget-test harness. See ADR-0015 and the `write-tests` playbook.
///
/// Widget tests need localization loaded, or `LocaleKeys.x.tr()` renders the raw
/// key path and `.plural()` throws a `LateInitializationError` on the
/// uninitialised locale.
///
/// Translations are loaded **once** into the `Localization` singleton rather
/// than by mounting `EasyLocalization` per test: remounting that widget in a
/// second `testWidgets` leaves its async bundle load unresolved under `pump()`,
/// so every screen renders empty and every `find` returns nothing.
Future<void> initLocalizationForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // EasyLocalization persists the chosen locale through shared_preferences,
  // whose platform channel does not exist under `flutter test`.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();

  const locale = Locale('en', 'US');
  final controller = EasyLocalizationController(
    supportedLocales: const [locale],
    fallbackLocale: locale,
    forceLocale: locale,
    path: 'assets/translations',
    useOnlyLangCode: false,
    useFallbackTranslations: true,
    saveLocale: false,
    assetLoader: const RootBundleAssetLoader(),
    onLoadError: (e) => throw e,
  );
  await controller.loadTranslations();

  Localization.load(
    locale,
    translations: controller.translations,
    fallbackTranslations: controller.fallbackTranslations,
  );
}

extension PumpApp on WidgetTester {
  /// Pumps [child] inside the app's real theme.
  ///
  /// Pass [dark] to assert dark-mode rendering — every feature must be correct
  /// in both themes (ADR-0013).
  Future<void> pumpApp(Widget child, {bool dark = false}) async {
    await pumpWidget(
      MaterialApp(theme: dark ? darkTheme : lightTheme, home: child),
    );
    await settleFrames();
  }

  /// Advances a bounded number of frames.
  ///
  /// `pumpAndSettle` cannot be used on these screens: the skeleton loader and
  /// the FAB animation never reach a steady state, so it times out after 10 s
  /// instead of failing usefully. A bounded pump lets the entry animations
  /// finish without hanging on a perpetual one.
  Future<void> settleFrames({int frames = 6}) async {
    for (var i = 0; i < frames; i++) {
      await pump(const Duration(milliseconds: 60));
    }
  }
}
