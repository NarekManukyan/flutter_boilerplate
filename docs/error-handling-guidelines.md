# Error Handling Guidelines

How this boilerplate catches, reports and recovers from errors. The rule is [ADR-0020](adr/0020-error-handling-and-issue-tracking.md), the step-by-step is the [`handle-errors`](../.claude/skills/handle-errors/SKILL.md) playbook, and the sink is [`IssueTrackingService`](../lib/core/services/issue_tracking_service.dart).

## Overview

A `catch` block decides two things: what the user sees, and whether the team ever finds out the failure happened. This guide is mostly about the quiet failure: an error the UI handles well but nobody reports, so a bug that hits every user looks like silence in Sentry.

**Rule:** every `catch` in `lib/` either rethrows or tracks through `IssueTrackingService` before it returns. Never both, never neither.

## The tracking sink: `IssueTrackingService`

The service is `@injectable`. Stores, states, use cases and services receive it through the constructor and never call `Sentry` directly. It has three methods, all returning `void`, picked by **who shows the error**, not by how severe it is:

| Method | Signature |
|---|---|
| `trackIssue` | `(Object error, {StackTrace? stackTrace, String? message, required String context, bool notifyOnConnectivityError = false})` |
| `trackHandledError` | `(Object error, {StackTrace? stackTrace, required String handlingContext})` |
| `trackSilentError` | `(Object error, {StackTrace? stackTrace, required String context})` |

- `context` / `handlingContext` is a short snake_case operation name (`load_todos`, `create_todo`). It becomes the `error_context` tag in Sentry, next to `error_type` (`standard`, `handled` or `silent`), so a report leads back to its call site.
- `message` is the notice text, taken from `LocaleKeys` ([ADR-0012](adr/0012-mandatory-localization.md)). Without it, the notice says `LocaleKeys.errors_generic` in production and `error.toString()` in other flavors.
- In debug builds `lib/main.dart` does not initialise Sentry. The service logs each tracked error with `developer.log` under the name `IssueTrackingService` instead.

## Error categories

| Category | Method | Who tells the user | In this repo |
|---|---|---|---|
| Unhandled by the caller | `trackIssue` | the service, with an `ErrorNotice` | no call yet; the playbook's illustrative sign-out example is the shape |
| Handled | `trackHandledError` | the caller: an error state, inline text, a `null` it branches on | `HomeStore.loadTodos`, `CreateTodoUseCase`, `FetchTodoUseCase` |
| Silent | `trackSilentError` | nobody; the user is not waiting on it | `ConnectivityStore._init`, `AppUpdateService.checkAppVersion` |

These methods cover errors a `catch` has already caught. An error nothing catches goes to the handlers that `SentryFlutter.init` installs in profile and release builds.

### What the service filters

Call sites never repeat these rules ([ADR-0020](adr/0020-error-handling-and-issue-tracking.md#what-the-service-filters)):

| Error | Sent to Sentry | Notice from `trackIssue` |
|---|---|---|
| Connection, send or receive timeout; connection error | no | only with `notifyOnConnectivityError: true` |
| Cancelled request (`DioExceptionType.cancel`) | no | no |
| Status in `IssueTrackingService.ignoredStatusCodes` (`401`, on which `AuthInterceptor` clears the session) | no | no |
| A thrown value that is not an `Error` or `Exception` | no | yes |

With no navigator context yet, the error is still reported but no notice is shown. A report on a `DioException` carries its type, method, path and status code, never headers (the bearer token) or bodies (user data). Branch on `DioExceptionType` or a status code at the call site only when your UI does something different for it.

## Best practices

### 1. Track once

The layer that catches and does not rethrow is the layer that tracks. A `catch` that tracks and then rethrows reports the failure again wherever it is caught next.

### 2. Reset loading state in `finally`

A failure must never leave a spinner on screen. `AddTodoModalState.onSubmit` stops loading in `finally`, whatever the use case returned, and returns early while a submit is already running:

```dart
if (loadingState.isLoading) {
  return;
}
loadingState.startLoading();
_hasError = false;
try {
  final todo = await _createTodoUseCase(titleController.text.trim());
  if (todo == null) {
    _hasError = true;
    return;
  }
  await _homeStore.addTodo(todo);
  await _appNavigator.pop();
} finally {
  loadingState.stopLoading();
}
```

There is no `catch` here: `CreateTodoUseCase` has already tracked the failure and returned `null`. An initialisation flag works the same way and is reset on failure, so a retry starts clean.

### 3. Handle async errors

A future nobody awaits has nobody to catch its error. `unawaited(future)` is only safe when the future cannot throw: `ConnectivityStore` calls `unawaited(_init())` from its constructor, and `_init` catches everything itself (see below). Otherwise `await` it inside a `try`, or attach a `.catchError` that calls `trackSilentError` ([`handle-errors`](../.claude/skills/handle-errors/SKILL.md#async-work)).

### 4. Shared stores restore, then rethrow

A store that several screens read should not decide what the user sees. When one of its actions has no `error` observable for a failure (an optimistic delete, a toggle), it puts its state back in a `catch` with no `on` clause and rethrows. The state that called it owns the screen and tracks once. A store whose page renders its `error` observable does not rethrow: it sets `error` and tracks with `trackHandledError`, as `HomeStore.loadTodos` does. The todos provider has no delete endpoint, so the worked example in [`handle-errors`](../.claude/skills/handle-errors/SKILL.md#stores-restore-then-rethrow) is illustrative.

### 5. Say so when a change is rolled back

Connectivity errors show no notice, because `ConnectionWrapperPage` already tells the user the device is offline. That is right for a failed load. It is wrong for an optimistic change the app undid: the row comes back with no explanation, and a timeout can happen while the device is online. The state that tracks a rollback calls `trackIssue` with a `LocaleKeys` `message` and `notifyOnConnectivityError: true`. The notice then shows, and the connectivity error is still not reported ([`handle-errors`](../.claude/skills/handle-errors/SKILL.md#optimistic-changes-notify-on-rollback)).

### 6. Catch what you can handle

An API boundary, such as a store's load or an API use case, catches everything with `catch (e, stackTrace)`. The generated Retrofit client rethrows a response that fails `fromJson` unchanged, so `on DioException` would let a bad payload skip the error UI. A rollback or a restore catches everything too, because more than the request can throw between the change and the restore. `on DioException` is only for branching on the Dio error type while letting everything else propagate.

## Common patterns

### Store load with an error state

`HomeStore.loadTodos`. The page renders `error` with a retry button, so the failure is handled:

```dart
_isLoading = true;
_error = null;
try {
  final result = await _dioService.todosProvider.getTodos();
  _todos = ObservableList.of(result);
} catch (e, stackTrace) {
  // Everything, not only DioException: a bad payload must reach the error
  // state too. The page renders [error], so this is handled.
  _issueTrackingService.trackHandledError(
    e,
    stackTrace: stackTrace,
    handlingContext: 'load_todos',
  );
  _error = e is DioException ? e.message : e.toString();
} finally {
  _isLoading = false;
}
```

### API use case that returns `null`

`CreateTodoUseCase` tracks with `trackHandledError` and returns `null` ([use_cases_guide.md](use_cases_guide.md#type-1-api)). `AddTodoModalState` turns the `null` into `hasError`, and the sheet shows `LocaleKeys.addTodoModal_error`. `FetchTodoUseCase` works the same way for the details page. The other use-case patterns (return empty, domain exception, guard, rethrow) are in [`handle-errors`](../.claude/skills/handle-errors/SKILL.md#use-cases-the-five-patterns).

### Background work

`AppUpdateService.checkAppVersion` looks up the store version. Nobody is waiting on it, so a failure is silent, and `finally` disposes the `Upgrader` either way:

```dart
} on Exception catch (error, stackTrace) {
  _issueTrackingService.trackSilentError(
    error,
    stackTrace: stackTrace,
    context: 'check_app_version',
  );
} finally {
  upgrader.dispose();
}
```

### Initialisation that must not lock the user out

`ConnectivityStore._init` reads the first status from the `connectivity_plus` plugin. If the plugin throws, the store stays online and reports silently. Showing the offline page over a plugin failure would block an app that may well be online:

```dart
try {
  final initialStatus = await _connectivity.checkConnectivity();
  if (_disposed) {
    return;
  }
  _addStatus(initialStatus);
  _subscription = _connectivity.onConnectivityChanged.listen(_addStatus);
} catch (e, stackTrace) {
  _issueTrackingService.trackSilentError(
    e,
    stackTrace: stackTrace,
    context: 'connectivity_init',
  );
}
```

## Error recovery strategies

- **Retry.** `HomePage` shows an error state whose retry button calls `HomePageState.init`, which runs `HomeStore.loadTodos` again; the load clears the old `error` first. A paged list advances its page only after a success, so a retry asks for the same page ([`create-store`](../.claude/skills/create-store/SKILL.md#pagination)). Retry automatically only idempotent requests, and track only the last failed attempt.
- **Fallback.** Show what you have: return cached data after `trackHandledError` and let the caller render it.
- **Safe default.** When a failure should not block the user, choose the state that keeps the app usable. `ConnectivityStore` stays online; `AppUpdateService` skips the update prompt.
- **Restore.** Put the store back into a state the page can render (the previous data, an error state), then track or rethrow.

## Testing error handling

Mock `IssueTrackingService` with mocktail and verify the tracking call, with its operation name, on the failure path. From [`home_store_test.dart`](../test/features/home/mobx/home_store_test.dart):

```dart
test('should report a failed load as handled, not as a notice', () async {
  final error = _dioError('boom');
  when(() => todosProvider.getTodos()).thenThrow(error);

  await store.loadTodos();

  verify(
    () => issueTracking.trackHandledError(
      error,
      stackTrace: any(named: 'stackTrace'),
      handlingContext: 'load_todos',
    ),
  ).called(1);
  verifyNever(
    () => issueTracking.trackIssue(
      any(),
      stackTrace: any(named: 'stackTrace'),
      message: any(named: 'message'),
      context: any(named: 'context'),
      notifyOnConnectivityError: any(named: 'notifyOnConnectivityError'),
    ),
  );
});
```

- `verifyNever` on `trackIssue` is the guard against two messages for one failure. List every named argument, or it does not match every call.
- Assert what the user sees as well: `error` is set and `isLoading` is false again.
- For `trackIssue`, verify `context:` and `message:` as values. Load translations with `setUpAll(initLocalizationForTests)` from `test/helpers/pump_app.dart` so `.tr()` returns real text.
- A store that restores and rethrows gets `verifyNever` on all three methods.
- The filtering rules are tested once, in `test/core/services/issue_tracking_service_test.dart`. Feature tests do not repeat them.
- On a device, `.maestro/flows/home/home_todos_failure.yaml` switches the dev mock to `serverError` through `common/set_mock.yaml`, then checks the error state and the retry.

## More information

- [ADR-0020 Error handling and issue tracking](adr/0020-error-handling-and-issue-tracking.md)
- Playbooks: [`handle-errors`](../.claude/skills/handle-errors/SKILL.md), [`create-store`](../.claude/skills/create-store/SKILL.md), [`create-use-case`](../.claude/skills/create-use-case/SKILL.md), [`write-tests`](../.claude/skills/write-tests/SKILL.md#verify-tracking-on-every-failure-path)
- Guides: [use_cases_guide.md](use_cases_guide.md), [state-management-guide.md](state-management-guide.md), [security-guidelines.md](security-guidelines.md), [troubleshooting.md](troubleshooting.md#api-calls-fail)
