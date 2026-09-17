import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_boilerplate/features/app/mobx/connectivity_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  late _MockConnectivity connectivity;
  late _MockIssueTrackingService issueTracking;
  late StreamController<List<ConnectivityResult>> changes;

  setUp(() {
    connectivity = _MockConnectivity();
    issueTracking = _MockIssueTrackingService();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  group('ConnectivityStore', () {
    test('should follow the initial status and later changes', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final store = ConnectivityStore(connectivity, issueTracking);
      await pumpEventQueue();
      expect(store.hasConnection, isFalse);

      changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(store.hasConnection, isTrue);

      await store.dispose();
    });

    // Regression guard: the subscription was a `late` field assigned after an
    // await, so disposing before the first status arrived threw
    // LateInitializationError.
    test('should dispose safely before the first status arrives', () async {
      final initial = Completer<List<ConnectivityResult>>();
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) => initial.future);

      final store = ConnectivityStore(connectivity, issueTracking);
      await expectLater(store.dispose(), completes);

      initial.complete([ConnectivityResult.none]);
      await pumpEventQueue();
      // A disposed store neither applies the late status nor subscribes.
      expect(store.hasConnection, isTrue);
      verifyNever(() => connectivity.onConnectivityChanged);
    });

    test(
      'should stay online and report silently when the plugin fails',
      () async {
        final error = PlatformException(code: 'unavailable');
        when(() => connectivity.checkConnectivity()).thenThrow(error);

        final store = ConnectivityStore(connectivity, issueTracking);
        await pumpEventQueue();

        expect(store.hasConnection, isTrue);
        verify(
          () => issueTracking.trackSilentError(
            error,
            stackTrace: any(named: 'stackTrace'),
            context: 'connectivity_init',
          ),
        ).called(1);
        await store.dispose();
      },
    );
  });
}
