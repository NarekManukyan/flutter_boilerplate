---
name: add-platform-channel
description: Add a platform channel between Dart and native iOS (Swift) / Android (Kotlin) — one channel per capability named {app_id}/{capability}, the contract written first and matched on all three sides, the Dart wrapper in lib/core/platform_channels/ that catches PlatformException, tracks it and returns a typed result, native registration and threading, and tests with a mock method-call handler. Use when Flutter needs a native API no maintained plugin covers, or when changing an existing MethodChannel / EventChannel.
---

# Add a platform channel

Governed by [ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md) (DI), [ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md) (errors), [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md) (tests).

**Check pub.dev first.** A maintained plugin is tested on both platforms and kept current with OS changes; a hand-written channel is yours to maintain forever. Write one when no plugin covers the capability, or when the native code is the app's own.

**Work that spans Dart, iOS and Android goes through the [`mobile-orchestrator`](../../agents/mobile-orchestrator.md) agent.** It fixes the contract below before anyone edits, runs the Flutter, iOS and Android agents in parallel against it, and checks afterwards that every name matches on all three sides.

## `ios/` and `android/` are per app

The boilerplate does not commit them ([README](../../../README.md#no-committed-ios-or-android)). In an app generated from it they are committed, and the native half of the channel lives there. In the boilerplate itself, write the contract and the Dart side with its tests, and leave the native files as a documented plan.

## One channel per capability

- One channel per native **capability** — `screen_awake`, `biometrics`, `share_sheet` — never one `app_channel` that grows a method for everything. A capability's methods, errors and tests stay together, and removing it removes one file per side.
- Name it `{app_id}/{capability}`: `com.example.flutterBoilerplate/screen_awake`.
- `{app_id}` is **one fixed spelling, used verbatim on all three sides.** `flutter create` gives iOS `com.example.flutterBoilerplate` and Android `com.example.flutter_boilerplate`; do not let each side derive the name from its own bundle id. A one-character mismatch is not an error anywhere — the call just throws `MissingPluginException`.
- A stream of native events (sensor readings, connectivity) is an `EventChannel` named `{app_id}/{capability}/events`, next to the capability's `MethodChannel`.

## 1. Write the contract first

Before any code, write the contract as the doc comment of the Dart wrapper. It is the single source; the Swift and Kotlin files point back to it.

| Field | Decide |
|---|---|
| Channel name | `{app_id}/{capability}`, one string |
| Methods | exact names, and the direction of each: Dart → native or native → Dart |
| Arguments | one map; each key's name, type and nullability. Never positional values |
| Return | type and nullability, and what `null` means |
| Errors | every `code` the native side may send, what `message` holds, the shape of `details` |
| Unknown method | iOS returns `FlutterMethodNotImplemented`, Android calls `notImplemented()`, Dart catches `MissingPluginException` |

The standard codec carries `null`, `bool`, `int`, `double`, `String`, `Uint8List`, `List` and `Map`. Dart `int` arrives on iOS as `NSNumber` and on Android as `Int`, or `Long` when it does not fit in 32 bits. Anything else — a `DateTime`, an enum, a DTO — is converted to one of those in the contract (an ISO-8601 string, the enum's `name`, a map).

**The contract changes on all three sides in one change, or not at all.**

## 2. The Dart side

`lib/core/platform_channels/{capability}_channel.dart`. It wraps the `MethodChannel`, so nothing else in `lib/` touches one.

```dart
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../services/issue_tracking_service.dart';

/// Keeps the screen from dimming and locking while it is on.
///
/// Contract, mirrored by `ScreenAwakeChannel.swift` and
/// `ScreenAwakeChannel.kt`. Change all three sides together.
///
/// | Method | Direction | Arguments | Returns | Error codes |
/// |---|---|---|---|---|
/// | `setKeepAwake` | Dart → native | `{'enabled': bool}` | `null` | `BAD_ARGS` |
/// | `isKeepAwake` | Dart → native | none | `bool` | none |
@injectable
class ScreenAwakeChannel {
  ScreenAwakeChannel(this._issueTrackingService);

  static const name = 'com.example.flutterBoilerplate/screen_awake';

  final IssueTrackingService _issueTrackingService;
  final _channel = const MethodChannel(name);

  /// Returns false when the platform could not apply it.
  Future<bool> setKeepAwake({required bool enabled}) async {
    try {
      await _channel.invokeMethod<void>('setKeepAwake', <String, Object?>{
        'enabled': enabled,
      });
      return true;
    } on PlatformException catch (e, stackTrace) {
      // A contract error code from the native side.
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'screen_awake_set',
      );
      return false;
    } on MissingPluginException catch (e, stackTrace) {
      // No native handler: the platform does not implement the channel, or
      // the native build is older than this method.
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'screen_awake_set',
      );
      return false;
    }
  }

  /// Null when the platform could not answer.
  Future<bool?> isKeepAwake() async {
    try {
      return await _channel.invokeMethod<bool>('isKeepAwake');
    } on PlatformException catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'screen_awake_get',
      );
      return null;
    } on MissingPluginException catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'screen_awake_get',
      );
      return null;
    }
  }
}
```

- **Typed in, typed out.** Callers pass named Dart parameters and get `bool`, a nullable value, a DTO or a sealed result — never a `Map`, a `dynamic` or a `PlatformException`.
- **Every failure is caught here and tracked** ([ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md)). `trackHandledError` when the caller branches on the failure value, as above; `trackSilentError` when nobody is waiting on the result; `trackIssue` only if nothing on screen will say it failed. When a caller must react to one specific error code, track and then throw a typed exception from `lib/core/exceptions/` (pattern 3).
- **Scope.** `@injectable` when the wrapper only calls native code, like this one. `@lazySingleton` when it registers a handler for native → Dart calls: a channel has **one** handler, so a second instance would silently replace the first.
- Stores, use cases and page states inject the wrapper through their constructor. Widgets never call it ([ADR-0001](../../../docs/adr/0001-layered-architecture.md)).

### Native → Dart calls

The wrapper is `@lazySingleton`. Register the handler once, catch inside each method, and remove the handler on dispose:

```dart
void init() => _channel.setMethodCallHandler(_onNativeCall);

void dispose() => _channel.setMethodCallHandler(null);

Future<Object?> _onNativeCall(MethodCall call) async {
  switch (call.method) {
    case 'onTimeout':
      try {
        await _handleTimeout(call.arguments as Map<Object?, Object?>);
      } catch (e, stackTrace) {
        // Native is not waiting on this, and nothing on screen reports it.
        _issueTrackingService.trackSilentError(
          e,
          stackTrace: stackTrace,
          context: 'screen_awake_on_timeout',
        );
      }
      return null;
    default:
      // Answers the native side with "not implemented".
      throw MissingPluginException('No Dart handler for ${call.method}');
  }
}
```

An exception that escapes the handler is sent back to native as an error, and native code rarely handles it. Catch per method.

## 3. The native sides

Handlers run on the **platform (main) thread**, and every result is sent **exactly once, on the main thread**. Work that would block the main thread moves to a background queue or thread and posts its result back to the main thread.

### iOS — Swift

`ios/Runner/ScreenAwakeChannel.swift`:

```swift
import Flutter
import UIKit

/// Contract: lib/core/platform_channels/screen_awake_channel.dart
enum ScreenAwakeChannel {
  static let name = "com.example.flutterBoilerplate/screen_awake"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "setKeepAwake":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "BAD_ARGS", message: "Expected {enabled: bool}", details: nil))
          return
        }
        UIApplication.shared.isIdleTimerDisabled = enabled
        result(nil)
      case "isKeepAwake":
        result(UIApplication.shared.isIdleTimerDisabled)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
```

Register it in `ios/Runner/AppDelegate.swift`. Current `flutter create` templates create the engine implicitly and hand you a bridge:

```swift
func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
  GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  ScreenAwakeChannel.register(with: engineBridge.applicationRegistrar.messenger())
}
```

An app generated from an older template has no `didInitializeImplicitFlutterEngine`; register in `application(_:didFinishLaunchingWithOptions:)` with the messenger its `AppDelegate` already uses. Add the new Swift file to the Runner target. Background work: `DispatchQueue.global().async { … DispatchQueue.main.async { result(value) } }`.

### Android — Kotlin

`android/app/src/main/kotlin/{org path}/ScreenAwakeChannel.kt`:

```kotlin
package com.example.flutter_boilerplate

import android.app.Activity
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Contract: lib/core/platform_channels/screen_awake_channel.dart */
class ScreenAwakeChannel(private val activity: Activity) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepAwake" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error("BAD_ARGS", "Expected {enabled: bool}", null)
                        return@setMethodCallHandler
                    }
                    val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    if (enabled) activity.window.addFlags(flag) else activity.window.clearFlags(flag)
                    result.success(null)
                }
                "isKeepAwake" -> {
                    val flags = activity.window.attributes.flags
                    result.success((flags and WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) != 0)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        const val NAME = "com.example.flutterBoilerplate/screen_awake"
    }
}
```

Register it in `MainActivity.kt`:

```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ScreenAwakeChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
```

Note the package is `flutter_boilerplate` (the Android spelling) while `NAME` keeps the shared channel spelling. Background work: run it on an executor or coroutine, then `Handler(Looper.getMainLooper()).post { result.success(value) }` — calling `result` off the main thread crashes.

Permissions, `Info.plist` usage strings and `AndroidManifest.xml` entries the capability needs are part of the same change.

## Tests

Test the Dart wrapper against a fake native side: `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`. `test/core/platform_channels/screen_awake_channel_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_boilerplate/core/platform_channels/screen_awake_channel.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ScreenAwakeChannel.name);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late _MockIssueTrackingService issueTracking;
  late ScreenAwakeChannel screenAwake;

  setUp(() {
    issueTracking = _MockIssueTrackingService();
    screenAwake = ScreenAwakeChannel(issueTracking);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('ScreenAwakeChannel', () {
    test('should send the contract method and arguments', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

      final applied = await screenAwake.setKeepAwake(enabled: true);

      expect(applied, isTrue);
      expect(calls.single.method, 'setKeepAwake');
      expect(calls.single.arguments, {'enabled': true});
    });

    test('should return false and track when the platform fails', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'BAD_ARGS');
      });

      final applied = await screenAwake.setKeepAwake(enabled: true);

      expect(applied, isFalse);
      verify(
        () => issueTracking.trackHandledError(
          any(that: isA<PlatformException>()),
          stackTrace: any(named: 'stackTrace'),
          handlingContext: 'screen_awake_set',
        ),
      ).called(1);
    });

    test('should return null when no native handler is registered', () async {
      final result = await screenAwake.isKeepAwake();

      expect(result, isNull);
      verify(
        () => issueTracking.trackHandledError(
          any(that: isA<MissingPluginException>()),
          stackTrace: any(named: 'stackTrace'),
          handlingContext: 'screen_awake_get',
        ),
      ).called(1);
    });
  });
}
```

- A `PlatformException` thrown inside the mock handler reaches the wrapper exactly as a native `FlutterError` / `result.error` would. No handler at all behaves like a platform without the channel.
- Clear the handler in `tearDown`, or it answers for the next test.
- Assert the method name and arguments **against the contract table** — this test is what catches a renamed key on the Dart side.
- Code that uses the wrapper (a store, a use case) mocks the wrapper class instead; only the wrapper's own test fakes the channel.
- The native handlers are verified on a device: a Maestro flow that drives the feature, or the native platform's own tests.

## Checklist

- [ ] No maintained plugin covers it
- [ ] One channel per capability, named `{app_id}/{capability}`, one spelling on all three sides
- [ ] Contract written first as the wrapper's doc comment: methods, direction, arguments, returns, error codes
- [ ] Dart wrapper in `lib/core/platform_channels/{capability}_channel.dart`; nothing else touches `MethodChannel`
- [ ] `PlatformException` and `MissingPluginException` caught, tracked, and turned into a typed result
- [ ] `@injectable` for call-only wrappers, `@lazySingleton` when a native → Dart handler is registered
- [ ] Swift handler registered in `AppDelegate`, Kotlin handler in `MainActivity`; unknown methods answer not-implemented
- [ ] Results sent exactly once, on the main thread
- [ ] Permissions / `Info.plist` / manifest entries included
- [ ] Unit test with `setMockMethodCallHandler`: contract method and arguments, success value, `PlatformException`, missing handler
- [ ] Cross-platform change run through the `mobile-orchestrator` agent, with the names checked on all three sides afterwards
