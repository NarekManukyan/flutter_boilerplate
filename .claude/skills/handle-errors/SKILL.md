---
name: handle-errors
description: Write a try/catch the house way — which IssueTrackingService method to call (trackIssue / trackHandledError / trackSilentError), the golden rule that every catch tracks or rethrows, what a catch should catch, the five use-case error patterns, restore-then-rethrow for stores, rollback notices for optimistic changes, recovery (retry, fallback, state reset), and how to test it. Use when writing any catch block, a store action or use case that calls the API, background work, or platform-channel code.
---

# Handle errors

Governed by [ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md). Service: `lib/core/services/issue_tracking_service.dart`.

**No service in this repo yet?** Create it before writing the first `catch`. Port the reference implementation and its test from the boilerplate — [`issue_tracking_service.dart`](https://github.com/NarekManukyan/flutter_boilerplate/blob/master/lib/core/services/issue_tracking_service.dart), [`error_notice.dart`](https://github.com/NarekManukyan/flutter_boilerplate/blob/master/lib/core/ui/error_notice.dart), [`issue_tracking_service_test.dart`](https://github.com/NarekManukyan/flutter_boilerplate/blob/master/test/core/services/issue_tracking_service_test.dart) — and adapt three things to the app: how it shows a notice (its navigator / overlay API), its design tokens, and `ignoredStatusCodes` (whatever its interceptors already handle globally). Keep the three method names and the filtering rules.

## The golden rule

**Every `catch` in `lib/` either rethrows or tracks through `IssueTrackingService` before it returns.** Track once, in the layer that swallows the error.

## Pick the method by who shows the error

```
Does anything on screen already tell the user this failed?
├─ No, and the user is waiting on it ────────────→ trackIssue          (service shows a notice)
├─ Yes: error state, inline message, or the caller
│  branches on the null / empty / exception ───────→ trackHandledError   (no notice)
└─ The user is not waiting on it (background) ────→ trackSilentError    (no notice)
```

```dart
// A state action. Nothing on screen reports a failed sign-out, so the service
// shows a notice.
try {
  await _homeStore.logout();
} catch (e, stackTrace) {
  _issueTrackingService.trackIssue(
    e,
    stackTrace: stackTrace,
    context: 'logout',
  );
}

// A store action. The page renders `error` as its own error state.
} on DioException catch (e, stackTrace) {
  _issueTrackingService.trackHandledError(
    e,
    stackTrace: stackTrace,
    handlingContext: 'load_todos',
  );
  _error = e.message;
}

// Background, best effort.
} catch (e, stackTrace) {
  _issueTrackingService.trackSilentError(
    e,
    stackTrace: stackTrace,
    context: 'warm_image_cache',
  );
}
```

Every method requires an operation name: `context:` on `trackIssue` and `trackSilentError`, `handlingContext:` on `trackHandledError`. It is a short snake_case name and becomes the `error_context` tag in Sentry, so make it greppable back to the call site.

| Method | Signature |
|---|---|
| `trackIssue` | `(Object error, {StackTrace? stackTrace, String? message, required String context, bool notifyOnConnectivityError = false})` |
| `trackHandledError` | `(Object error, {StackTrace? stackTrace, required String handlingContext})` |
| `trackSilentError` | `(Object error, {StackTrace? stackTrace, required String context})` |

Pass a `message:` to `trackIssue` only when you have something better than the generic text, and take it from `LocaleKeys` ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)). Never build the message from `e.toString()` yourself: the service already shows the raw error outside production and a translated one in production.

## What to catch

Catch what you can handle, and let the rest through.

- **A rollback or a state restore runs on any failure.** Use a `catch` with no `on` clause: `catch (e, stackTrace)` when this `catch` tracks, `catch (_)` when it only restores and rethrows. Between the optimistic change and the restore, more than the request can throw: a response that fails to parse, a `StateError`. If only `DioException` restores, anything else leaves the screen wrong.
- **`on DioException catch (e, stackTrace)`** is for a request whose only expected failure is the request itself, with nothing to undo: a load that sets `error`, a use case that returns `null`.

## What you do not handle at the call site

The service filters these, so do not special-case them:

- offline and timeouts — never reported, and by default no notice, because for a load the connection page covers it. A rollback is the exception: see [Optimistic changes](#optimistic-changes-notify-on-rollback);
- cancelled requests — nothing;
- `401` — nothing (`AuthInterceptor` logs the user out). Add other codes your app handles globally to `IssueTrackingService.ignoredStatusCodes`;
- no navigator context yet — reported, no notice.

Only branch on `DioExceptionType` / status code at the call site when **your UI** does something different for it (a "not found" empty state, a retry button for timeouts).

## Use cases: the five patterns

| # | Pattern | On failure | Track with |
|---|---|---|---|
| 1 | Return `null` | `return null;` | `trackHandledError` |
| 2 | Return empty | `return [];` | `trackHandledError` |
| 3 | Throw a domain exception | `throw TodoAlreadyExistsException();` | `trackHandledError`, then throw |
| 4 | Guard with callbacks | `await onError?.call();` | whatever the guard's failure is |
| 5 | Rethrow | `rethrow;` | nothing here — the caller that catches tracks |

```dart
// 1. Return null — the caller branches.
Future<TodoDto?> call(String title) async {
  try {
    return await _dioService.todosProvider.createTodo(
      todoCreateDto: TodoCreateRequestDto(title: title),
    );
  } on DioException catch (e, stackTrace) {
    _issueTrackingService.trackHandledError(
      e,
      stackTrace: stackTrace,
      handlingContext: 'create_todo',
    );
    return null;
  }
}

// 3. Domain exception — the caller must react to one specific failure.
} on DioException catch (e, stackTrace) {
  _issueTrackingService.trackHandledError(
    e,
    stackTrace: stackTrace,
    handlingContext: 'create_todo',
  );
  if (e.response?.statusCode == HttpStatus.conflict) {
    throw const TodoAlreadyExistsException();
  }
  return null;
}

// 4. Guard with callbacks.
Future<void> runIfAllowed({
  required Future<void> Function() onAllowed,
  Future<void> Function()? onDenied,
}) async {
  if (!await _permissionService.hasAccess()) {
    await onDenied?.call();
    return;
  }
  await onAllowed();
}
```

When the caller has to tell "not found" from "offline", return a sealed result, not `null`.

## Stores: restore, then rethrow

The pattern for a store action that changes state before or around a request and has no `error` observable for that failure: an optimistic delete, a toggle, a reorder.

1. Put the state back, whatever failed.
2. `rethrow`. Do not track here.
3. The state that called the store owns the screen and tracks once: `trackIssue`, or `trackHandledError` if it shows its own error UI.

A store shared across screens must not decide what the user sees, and this way the failure is still tracked exactly once.

Illustrative: the todos provider in this repo has no delete endpoint, and `homePage_deleteTodoFailed` is not a real key.

```dart
// HomeStore (@singleton).
@action
Future<void> deleteTodo(String id) async {
  final index = _todos.indexWhere((todo) => todo.id == id);
  if (index == -1) {
    return;
  }
  final removed = _todos.removeAt(index);
  try {
    await _dioService.todosProvider.deleteTodo(id);
  } catch (_) {
    // Any failure, not only DioException: the row has to come back. min():
    // the list may have shrunk while the request was out.
    _todos.insert(min(index, _todos.length), removed);
    rethrow;
  }
}

// HomePageState.
@action
Future<void> onTodoDismissed(String id) async {
  try {
    await _homeStore.deleteTodo(id);
  } catch (e, stackTrace) {
    _issueTrackingService.trackIssue(
      e,
      stackTrace: stackTrace,
      context: 'delete_todo',
      message: LocaleKeys.homePage_deleteTodoFailed.tr(),
      notifyOnConnectivityError: true,
    );
  }
}
```

A store whose page already renders its `error` observable is different: it restores, sets `error`, tracks with `trackHandledError`, and does not rethrow.

## Optimistic changes: notify on rollback

"Connectivity errors show no notice" is right for a load: the connection page says the device is offline. It is wrong for an optimistic change the app undid. The deleted row reappears, the connection page explains nothing, and a timeout can happen while the device is online. The user has to be told the change did not stick.

So the `catch` that tracks a rollback passes `notifyOnConnectivityError: true` to `trackIssue`, with a `LocaleKeys` `message` that says what was undone, as `onTodoDismissed` does above. The notice then shows for offline and timeout errors too. They are still not reported to Sentry. Cancellations and ignored status codes still show nothing.

## Stores and states

- A store action that sets an `error` observable the page renders uses `trackHandledError` and does not rethrow.
- A store action with no error observable for the failure restores its state and rethrows ([above](#stores-restore-then-rethrow)).
- A state action with no error UI of its own uses `trackIssue` so the user sees *something*. With its own error UI, `trackHandledError`.
- `LoadingState` / `isLoading` is reset in `finally`, never only on the success path — a failure must not leave a permanent spinner.
- Initialization that fails resets its flags, so a retry starts clean:

```dart
Future<void> init() async {
  try {
    await _performInitialization();
    _isInitialized = true;
  } catch (e, stackTrace) {
    _isInitialized = false;
    _issueTrackingService.trackHandledError(
      e,
      stackTrace: stackTrace,
      handlingContext: 'player_init',
    );
  }
}
```

If the caller must know it failed, reset the flag and `rethrow` **instead of** tracking, and let the caller track.

## Async work

- **No bare `unawaited(future)`** for anything that can fail. Either `await` it inside a `try`, or attach the handler:

```dart
unawaited(
  _syncService.sync().catchError((Object e, StackTrace stackTrace) {
    _issueTrackingService.trackSilentError(
      e,
      stackTrace: stackTrace,
      context: 'background_sync',
    );
  }),
);
```

- Platform channels throw `PlatformException`. Catch it at the service that owns the channel, track, and rethrow or return a failure value.

## Recovery

- **Retry** with backoff for idempotent requests; track only when the last attempt fails.
- **Fallback** to cached data: track with `trackHandledError`, return the cache.
- **State reset**: put the store back into a state the page can render (error state, previous data), then track, or rethrow and let the caller track ([restore, then rethrow](#stores-restore-then-rethrow)).

## Testing

Mock `IssueTrackingService` and verify the call with its exact arguments — its filtering is already covered by `test/core/services/issue_tracking_service_test.dart`.

```dart
class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

test('should return null and report the failure as handled', () async {
  final error = DioException(requestOptions: RequestOptions(path: '/todos'));
  when(
    () => todosProvider.createTodo(todoCreateDto: any(named: 'todoCreateDto')),
  ).thenThrow(error);

  expect(await createTodo('Milk'), isNull);
  verify(
    () => issueTracking.trackHandledError(
      error,
      stackTrace: any(named: 'stackTrace'),
      handlingContext: 'create_todo',
    ),
  ).called(1);
});
```

When the page shows its own error, also `verifyNever` on `trackIssue` — that is the double-message guard. List every named argument, `any(named: …)` for the ones you do not care about, so the guard matches every call:

```dart
verifyNever(
  () => issueTracking.trackIssue(
    any(),
    stackTrace: any(named: 'stackTrace'),
    message: any(named: 'message'),
    context: any(named: 'context'),
    notifyOnConnectivityError: any(named: 'notifyOnConnectivityError'),
  ),
);
```

For `trackIssue`, verify `context:` and `message:` as values. A rollback test uses a timeout, which is exactly the case the notice flag exists for. Initialise localization in `setUpAll(initLocalizationForTests)` (`test/helpers/pump_app.dart`) so `.tr()` returns the real text:

```dart
test('should notify, even on a timeout, when a delete rolls back', () async {
  final error = DioException(
    requestOptions: RequestOptions(path: '/todos/2'),
    type: DioExceptionType.receiveTimeout,
  );
  when(() => homeStore.deleteTodo('2')).thenThrow(error);

  await state.onTodoDismissed('2');

  verify(
    () => issueTracking.trackIssue(
      error,
      stackTrace: any(named: 'stackTrace'),
      context: 'delete_todo',
      message: LocaleKeys.homePage_deleteTodoFailed.tr(),
      notifyOnConnectivityError: true,
    ),
  ).called(1);
});
```

The store half is tested on its own: after a failed request the row is back at its index, and nothing was tracked (`verifyNever` on all three methods), because the store rethrows.

## Anti-patterns

- ❌ Empty `catch`, or `catch (_) { return null; }` without tracking.
- ❌ Tracking **and** rethrowing in the same `catch` → reported twice.
- ❌ `trackIssue` from a store whose page already renders the error → two messages.
- ❌ A rollback in `on DioException catch` → any other failure leaves the optimistic change in place.
- ❌ A rollback path without `notifyOnConnectivityError: true` → an offline or timed-out change silently reappears.
- ❌ A shared store calling `trackIssue` for a failure it rolled back → the store decides UI for every screen that uses it. Restore and rethrow.
- ❌ `Sentry.captureException` called directly outside the service.
- ❌ Attaching request headers or bodies to a report (tokens, user data).
- ❌ `throw Exception('Internal server error 500')` — throw a typed domain exception; user-facing text comes from `LocaleKeys`.

## Checklist

- [ ] Every `catch` tracks or rethrows — never both, never neither
- [ ] Method matches who shows the error (issue / handled / silent)
- [ ] Every call passes its operation name: `context:` on `trackIssue` / `trackSilentError`, `handlingContext:` on `trackHandledError`
- [ ] Rollbacks and restores catch everything (no `on` clause); `on DioException` only where there is nothing to undo
- [ ] A store with no error observable for the failure restores and rethrows; the calling state tracks
- [ ] A rollback's `trackIssue` passes a `LocaleKeys` `message` and `notifyOnConnectivityError: true`
- [ ] Loading flags reset in `finally`; init flags reset on failure
- [ ] No bare `unawaited` on a future that can fail
- [ ] No direct Sentry calls, no headers or bodies in reports
- [ ] Test verifies the tracking call on the failure path — [`write-tests`](../write-tests/SKILL.md)
