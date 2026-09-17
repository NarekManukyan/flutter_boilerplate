import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_boilerplate/features/app/mobx/connection_wrapper_state.dart';
import 'package:flutter_boilerplate/features/app/mobx/connectivity_store.dart';
import 'package:flutter_boilerplate/features/app/view/connection_wrapper_page.dart';
import 'package:flutter_boilerplate/gen/locale_keys.g.dart';
import 'package:flutter_boilerplate/injectable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockConnectivity extends Mock implements Connectivity {}

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  setUpAll(initLocalizationForTests);

  late StreamController<List<ConnectivityResult>> changes;
  late ConnectivityStore store;

  setUp(() {
    final connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      connectivity.checkConnectivity,
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => changes.stream);
    // The store itself is built inside the test body: its stream subscription
    // must live in the test's fake-async zone, or stream events never flush.
    getIt.registerFactory<ConnectionWrapperState>(
      () => ConnectionWrapperState(
        store = ConnectivityStore(connectivity, _MockIssueTrackingService()),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await store.dispose();
    await changes.close();
  });

  const appKey = Key('app_below_the_wrapper');

  testWidgets('should cover the app while offline without unmounting it', (
    tester,
  ) async {
    // Built inside the test: translations load in setUpAll, after main().
    final offlineTitle = find.text(LocaleKeys.connectionPage_title.tr());
    await tester.pumpApp(
      const ConnectionWrapperPage(
        child: Scaffold(body: Text('app', key: appKey)),
      ),
    );
    // Past the connectivity debounce.
    await tester.pump(const Duration(milliseconds: 300));

    expect(offlineTitle, findsOneWidget);
    // Regression guard: the wrapper used to swap the router child out, so
    // every route was unmounted while offline and rebuilt on reconnect.
    expect(find.byKey(appKey), findsOneWidget);
    final appElement = tester.element(find.byKey(appKey));

    changes.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(offlineTitle, findsNothing);
    expect(tester.element(find.byKey(appKey)), same(appElement));
  });
}
