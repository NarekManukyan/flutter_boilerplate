// Keep this file, and keep it at this path.
//
// Every app made from this template runs `flutter create .` to generate ios/
// and android/. flutter create only writes files that are missing, and when
// test/widget_test.dart is missing it writes the counter-app smoke test, which
// references a `MyApp` counter that does not exist here. `melos run verify`
// then fails on a fresh project before anyone has written a line.
//
// So the path is taken by a real test instead.

import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/ui/error_notice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  setUpAll(initLocalizationForTests);

  group('ErrorNotice', () {
    testWidgets('should show the message it is given', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: ErrorNotice(message: 'Could not save')),
      );

      expect(find.text('Could not save'), findsOneWidget);
    });

    testWidgets('should render in dark mode', (tester) async {
      await tester.pumpApp(
        const Scaffold(body: ErrorNotice(message: 'Could not save')),
        dark: true,
      );

      expect(find.text('Could not save'), findsOneWidget);
    });
  });
}
