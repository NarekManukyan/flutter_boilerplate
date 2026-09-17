# 20. Error Handling: Every Caught Error Is Tracked Through `IssueTrackingService`

- Status: Accepted
- Date: 2026-09-17
- Deciders: Flutter team

## Context and Problem Statement

A `catch` block decides two things at once: what the user sees, and whether anyone ever finds out the failure happened. Without a rule, each author answers both differently. Some errors show a raw exception string, some show nothing, and some are handled well in the UI but never reported, so a failure that hits every user for a week looks like silence in Sentry.

This repo had exactly that. `CreateTodoUseCase` caught `DioException` and returned `null`. The add-todo sheet showed its own error message, which was right for the user, but the failure was never reported. `HomeStore.loadTodos` did the same with its error state.

Two other failure modes show up as soon as a central handler exists:

- **Double messages.** A caller shows an inline error, and a generic handler shows a notice on top of it.
- **Noise.** Every dropped connection and every expired session lands in Sentry, and real defects get buried.

## Decision Drivers

- A failure the UI recovers from must still be visible to the team.
- The user sees exactly one message per failure, from whoever owns that screen.
- Offline, timeouts, cancellations and auth expiry are not defects; something else already handles them.
- Crash reports must not carry tokens or user data.
- The rule has to be checkable in review: every `catch` either rethrows or calls the service.

## Considered Options

- **One `IssueTrackingService` with three methods chosen by who shows the error.**
- **Report inside each `catch` directly with `Sentry.captureException`.**
- **A global error handler only** (`FlutterError.onError`, `PlatformDispatcher.onError`), no reporting in `catch` blocks.

## Decision Outcome

Chosen option: **one `IssueTrackingService` (`lib/core/services/issue_tracking_service.dart`) with three methods, picked by who puts the error on screen, not by how severe it is.**

| Method | Who shows the error | Notice | Use for |
|---|---|---|---|
| `trackIssue(e, stackTrace:, context:, message:, notifyOnConnectivityError:)` | nobody else; the service shows an `ErrorNotice` | yes | an action failed and nothing on screen says so |
| `trackHandledError(e, stackTrace:, handlingContext:)` | the caller: an error state, an inline message, a failure value it branches on | no | stores and use cases whose contract hands failure to the caller |
| `trackSilentError(e, stackTrace:, context:)` | nobody should; the user is not waiting on it | no | background sync, analytics, cache warm-up, best-effort cleanup |

Every method requires an operation name: `context` on `trackIssue` and `trackSilentError`, `handlingContext` on `trackHandledError`. It is a short snake_case name (`load_todos`, `create_todo`, `delete_todo`) and becomes the `error_context` tag in Sentry, which is how a report is traced back to its call site.

`message` and `notifyOnConnectivityError` are optional and exist only on `trackIssue`. `message` is the notice text, from `LocaleKeys`. `notifyOnConnectivityError` is covered under the filters below.

### The golden rule

**Every `catch` in `lib/` either rethrows or calls one of the three methods, before it returns.** An empty `catch`, or one that returns a fallback without tracking, is a review blocker.

```dart
// ❌ the failure disappears
} catch (_) {
  return null;
}

// ✅ the caller shows the failure, so it is tracked as handled
} catch (e, stackTrace) {
  _issueTrackingService.trackHandledError(
    e,
    stackTrace: stackTrace,
    handlingContext: 'create_todo',
  );
  return null;
}
```

Track exactly once. The layer that catches and does not rethrow is the layer that tracks. A layer that rethrows does not also track, or the same failure is reported twice.

**An API boundary catches everything.** A store's request or an API use case uses `catch (e, stackTrace)` with no `on` clause: the generated Retrofit client rethrows a response that fails `fromJson` unchanged, and `on DioException` would let it skip the error UI. `on DioException` is only for branching on the Dio error type while letting everything else propagate.

### What the service filters

These rules live in the service, so call sites never repeat them:

- **Connectivity errors** (connection, send and receive timeouts, connection errors) are never reported. By default they show no notice either. That holds for a load: the connection page already tells the user the device is offline. It does not hold for an optimistic change the app undid. A deleted row that comes back after a timeout has no connection page to explain it, and a timeout can happen while the device is online. A rollback path passes `notifyOnConnectivityError: true`, so the notice shows for offline and timeout errors too. They are still not reported.
- **Cancellations** (`DioExceptionType.cancel`) are neither reported nor shown.
- **Status codes something else owns** (`IssueTrackingService.ignoredStatusCodes`, `401` by default, on which `AuthInterceptor` clears the session) are neither reported nor shown.
- **Thrown values that are not an `Error` or `Exception`** are logged in debug and not reported.
- **Notice text** is the caller's `message`, else the generic `LocaleKeys.errors_generic` in production, else the raw `error.toString()` in development. The stack trace is never shown.
- **No context, no notice.** An error before the navigator exists is still reported.
- **Report contents** are method, path and status code for a `DioException`. Headers carry the bearer token and bodies carry user data, so neither is attached.

### The five use-case patterns

A use case catches at its boundary and tracks before it returns ([ADR-0004](0004-use-case-taxonomy-and-colocation.md)). Pick by what the caller needs.

| Pattern | Returns on failure | Tracks with | When |
|---|---|---|---|
| 1. Return `null` | `null` | `trackHandledError` | the caller branches on success vs failure |
| 2. Return empty | `[]` / empty model | `trackHandledError` | a list the caller renders either way |
| 3. Throw a domain exception | throws `SomethingAlreadyExistsException` | `trackHandledError` first | the caller must react to a specific failure |
| 4. Guard with callbacks | calls `onError` | depends on the guard | an action gated behind a check (permission, entitlement) |
| 5. Rethrow | rethrows | nothing; the catching caller tracks | the use case only maps data and the caller owns the error |

When a caller must tell "not found" from "offline", return a sealed result instead of a bare `null`. `null` loses the reason.

### Stores: restore, then rethrow

A store action with no `error` observable for the failure, such as an optimistic delete, has nowhere to show it. A store shared across screens should not decide what the user sees anyway. So it puts its state back and rethrows. The state that called it owns the screen and tracks once.

Illustrative: the todos provider in this repo has no delete endpoint, and `homePage_deleteTodoFailed` is not a real key.

```dart
// HomeStore: @singleton, read by more than one screen.
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

// HomePageState: owns the screen, so it tracks.
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
      // The row came back. Say so even offline or after a timeout.
      notifyOnConnectivityError: true,
    );
  }
}
```

- The calling state uses `trackIssue` when nothing else on screen reports the failure, or `trackHandledError` when it shows its own error UI. Either way the failure is tracked once, and the shared store never decides UI.
- A store whose page already renders its `error` observable does not rethrow. It restores, sets `error` and tracks with `trackHandledError`.
- The restore sits in a `catch` with no `on` clause, so it runs whatever failed.

### Allowed without tracking

- `rethrow`, or throwing a domain exception after tracking (pattern 3).
- A `catch` whose only job is to translate a *known, expected* condition into a value, where the condition is not a failure (parsing a user's optional input, for example). Add a one-line comment saying why it is not tracked.

### Consequences

- Good: a failure the UI handles still shows up in Sentry, tagged with where it happened and how it was handled.
- Good: one message per failure; the service never stacks a notice on a caller's error state.
- Good: offline, cancellations and auth expiry stay out of the defect list.
- Good: the golden rule is mechanical, so review can enforce it.
- Bad: every `catch` has to name its operation, which is a little ceremony.
- Bad: choosing between `trackIssue` and `trackHandledError` needs a moment's thought about who owns the screen.
- Neutral: the filtering lists (`ignoredStatusCodes`) are app-specific and are expected to grow per project.

### Confirmation

- Review: search the diff for `catch` and check every hit against the golden rule.
- Tests: a store, state or use case test that fails a request verifies the tracking call with its `handlingContext` or `context`, and for `trackIssue` its `message` and `notifyOnConnectivityError` (`test/features/home/mobx/home_store_test.dart`, `create_todo_use_case_test.dart`).
- The service's filtering is unit-tested in `test/core/services/issue_tracking_service_test.dart`.

## Pros and Cons of the Options

### One `IssueTrackingService`, three methods
- Good: one place for filtering, tagging, privacy and the notice.
- Good: mockable, so tests verify reporting.
- Bad: one more injected dependency in stores and use cases.

### `Sentry.captureException` in each `catch`
- Good: no abstraction.
- Bad: filtering, tags and privacy rules get copied into every call site and drift. Nothing decides whether the user sees a message. Tests cannot verify a static call.

### Global error handler only
- Good: zero call-site code.
- Bad: a caught error never reaches it, and caught errors are exactly the ones the UI hides. Unhandled errors still go through it; it complements this decision and does not replace it.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0003 No use case → use case](0003-no-use-case-to-use-case-dependencies.md) — shared error logic becomes a service
- [ADR-0004 Use-case taxonomy](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0012 Mandatory localization](0012-mandatory-localization.md) — notice text comes from `LocaleKeys`
- Playbooks: [`handle-errors`](../../.claude/skills/handle-errors/SKILL.md), [`create-store`](../../.claude/skills/create-store/SKILL.md), [`create-use-case`](../../.claude/skills/create-use-case/SKILL.md)

## AI Implementation Guidelines

<ai_context_rules>
- **Autonomy level:** Full
- **Architecture constraints:** Every `catch` in `lib/` rethrows or calls `trackIssue` / `trackHandledError` / `trackSilentError` before returning, never both. Choose the method by who shows the error: the service (`trackIssue`), the caller (`trackHandledError`), nobody (`trackSilentError`). Every call passes its operation name (`context:` or `handlingContext:`). An API boundary catches everything, never only `on DioException`. A rollback of an optimistic change passes `notifyOnConnectivityError: true` to `trackIssue`. A shared store with no error observable restores its state and rethrows; the calling state tracks. Never call Sentry outside `IssueTrackingService`. Never attach request headers or bodies to a report.
- **File paths affected:** `lib/**/*_store.dart`, `lib/**/*_state.dart`, `lib/**/*_use_case.dart`, `lib/core/services/**`
- **Verification command:** `flutter test test/core/services/issue_tracking_service_test.dart`
</ai_context_rules>
