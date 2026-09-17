---
name: handle-errors
description: Write a try/catch the house way — which IssueTrackingService method to call (trackIssue / trackHandledError / trackSilentError), the golden rule that every catch tracks or rethrows, the five use-case error patterns, recovery (retry, fallback, state reset), and how to test it. Use when writing any catch block, a store action or use case that calls the API, background work, or platform-channel code.
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
// User action, nothing else on screen reports it — the service shows a notice.
try {
  await _dioService.todosProvider.deleteTodo(id: id);
} catch (e, stackTrace) {
  _issueTrackingService.trackIssue(e, stackTrace: stackTrace);
}

// The page renders `error` as its own error state.
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

`handlingContext` / `context` is a short snake_case operation name. It becomes the `error_context` tag in Sentry — make it greppable back to the call site.

Pass a `message:` to `trackIssue` only when you have something better than the generic text, and take it from `LocaleKeys` ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)). Never build the message from `e.toString()` yourself: the service already shows the raw error outside production and a translated one in production.

## What you do not handle at the call site

The service filters these, so do not special-case them:

- offline and timeouts — no report, no notice (the connection page covers it);
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

## Stores and states

- A store action that sets an `error` observable for the page to render uses `trackHandledError`.
- A state action with no error UI of its own uses `trackIssue` so the user sees *something*.
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
- **State reset**: put the store back into a state the page can render (error state, previous data), then track.

## Testing

Mock `IssueTrackingService` and verify the call — its filtering is already covered by `test/core/services/issue_tracking_service_test.dart`.

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

When the page shows its own error, also `verifyNever` on `trackIssue` — that is the double-message guard.

## Anti-patterns

- ❌ Empty `catch`, or `catch (_) { return null; }` without tracking.
- ❌ Tracking **and** rethrowing in the same `catch` → reported twice.
- ❌ `trackIssue` from a store whose page already renders the error → two messages.
- ❌ `Sentry.captureException` called directly outside the service.
- ❌ Attaching request headers or bodies to a report (tokens, user data).
- ❌ `throw Exception('Internal server error 500')` — throw a typed domain exception; user-facing text comes from `LocaleKeys`.

## Checklist

- [ ] Every `catch` tracks or rethrows — never both, never neither
- [ ] Method matches who shows the error (issue / handled / silent)
- [ ] `handlingContext` / `context` names the operation
- [ ] Loading flags reset in `finally`; init flags reset on failure
- [ ] No bare `unawaited` on a future that can fail
- [ ] No direct Sentry calls, no headers or bodies in reports
- [ ] Test verifies the tracking call on the failure path — [`write-tests`](../write-tests/SKILL.md)
