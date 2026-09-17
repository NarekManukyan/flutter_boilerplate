---
name: write-tests
description: Write unit and widget tests — the testing pyramid, where each layer is tested, mocktail fakes at the right seam, MobX observable assertions, tracking verified on failure paths, JSON fixtures, widget tests for the loading/error/empty/content branches, keyed rows that survive a removal, overriding the page state (getIt for a whole page, Provider.value for a sub-widget), request-shape tests for API providers, and the "can this fail if the real code is broken?" check. Use whenever adding or changing a store, state, use case, service, platform channel or page.
---

# Write unit and widget tests

Governed by [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). Unit and widget tests are two of the three mandatory tiers; the third is [`write-maestro-flow`](../write-maestro-flow/SKILL.md).

## The pyramid

**Many unit tests, fewer widget tests, few E2E flows.**

| Tier | How many | What it proves | Cost |
|---|---|---|---|
| Unit | many — every branch of logic | a store, state, use case or service does the right thing on success, failure and empty | milliseconds, no device |
| Widget | fewer — the branches of each page | the page renders loading / error / empty / content and wires its callbacks | a second or so, no device |
| E2E (Maestro) | few — happy, failure, edge per feature | the journey works on a real device, through DI, routing and localization bootstrap | minutes, a booted device |

Push each check down to the cheapest tier that can catch the bug. An edge case in the paging logic is a unit test, not a Maestro flow. A widget test that re-checks business logic duplicates a unit test and runs ten times slower. If a bug can only be seen on a device, that is what the E2E tier is for.

## Where tests live

`test/` mirrors `lib/`.

```
test/
  features/{feature}/
    mobx/{feature}_store_test.dart
    view/{feature}_page_state_test.dart
    view/{feature}_page_test.dart          widget test
    use_cases/{name}_use_case_test.dart
  core/…                                    services, platform channels, utils
  helpers/                                  shared fakes + pump helpers (pump_app.dart, fixture.dart)
  fixtures/                                 JSON and other data files, grouped by feature
packages/api/test/
  providers/{resource}_provider/{resource}_api_provider_test.dart   request shape
```

## Test the seam below the unit

Each layer has exactly one collaborator type to fake ([ADR-0001](../../../docs/adr/0001-layered-architecture.md)):

| Testing | Fake | Never fake |
|---|---|---|
| Store | `DioService` (or the provider it exposes), `IssueTrackingService` | the store's own observables |
| Page state | the store, `AppNavigator`, use cases | the state under test |
| Use case | `DioService` / services / `AppNavigator` | — |
| Platform channel wrapper | the native side, via a mock method-call handler | the wrapper under test |
| Page (widget) | the page state | the widget tree |

**Prefer real objects > fake > mock.** A real `TodoDto` beats a mocked one. A hand-written fake store with a settable field beats a mocked store with five `when(...)` stubs.

## Conventions

- Always `group()`, named after the class under test.
- Test names begin with `should`: `test('should set error when the request fails', …)`.
- Arrange-Act-Assert, with a blank line between the three.
- One behaviour per test. A test asserting four unrelated things tells you nothing when it goes red.

## The check that matters

Before committing a test, ask: **"can this fail if the real code is broken?"**

```dart
// ❌ asserts that a collaborator was called, not what happened
when(() => store.loadTodos()).thenAnswer((_) async {});
await state.init();
verify(() => store.loadTodos()).called(1);
```

Assert the **observable outcome** — state after the act — not just that a collaborator was called. `verify` is right when the *only* effect is the call (navigation, analytics, error tracking); it is wrong as a substitute for asserting resulting state.

**Never assert a stub's own side effect.** When a stub changes something and the test reads that back, the test checks the stub. It stays green when the code under test is broken.

```dart
// ❌ the stub removes the todo, and the test reads the stub's list back.
//    Nothing here depends on how the page renders the removal.
when(() => state.onTodoDismissed('2')).thenAnswer((_) async {
  runInAction(() => todos.removeWhere((todo) => todo.id == '2'));
});
// ... swipe row '2' ...
expect(todos, hasLength(2));

// ✅ same stub, but assert what the page did: it called the state with the
//    right id, and the row left the tree
verify(() => state.onTodoDismissed('2')).called(1);
expect(find.byKey(const ValueKey('2')), findsNothing);
```

## Store test

```dart
class _MockDioService extends Mock implements DioService {}

class _MockTodosApiProvider extends Mock implements TodosApiProvider {}

class _MockAuthStore extends Mock implements AuthStore {}

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  late _MockDioService dioService;
  late _MockTodosApiProvider todosProvider;
  late _MockIssueTrackingService issueTracking;
  late HomeStore store;

  setUp(() {
    dioService = _MockDioService();
    todosProvider = _MockTodosApiProvider();
    issueTracking = _MockIssueTrackingService();
    when(() => dioService.todosProvider).thenReturn(todosProvider);
    store = HomeStore(dioService, _MockAuthStore(), issueTracking);
  });

  group('HomeStore', () {
    test('should expose loaded todos and clear loading on success', () async {
      when(() => todosProvider.getTodos()).thenAnswer(
        (_) async => [TodoDto(id: '1', title: 'a', completed: false)],
      );

      await store.loadTodos();

      expect(store.todos, hasLength(1));
      expect(store.isLoading, isFalse);
      expect(store.error, isNull);
    });

    test('should set error and clear loading when the request fails', () async {
      when(() => todosProvider.getTodos()).thenThrow(
        DioException(requestOptions: RequestOptions(), message: 'boom'),
      );

      await store.loadTodos();

      expect(store.error, 'boom');
      expect(store.isLoading, isFalse); // the finally-block regression guard
      expect(store.todos, isEmpty);
    });
  });
}
```

Every store test covers at minimum: **success**, **API failure**, **empty result**. The failure case must assert that loading was cleared — a spinner that never stops is the most common production symptom.

Working example: [`test/features/home/mobx/home_store_test.dart`](../../../test/features/home/mobx/home_store_test.dart).

## Verify tracking on every failure path

A `catch` that swallows an error must track it ([ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md)), and the failure-path test proves it. Mock `IssueTrackingService` and verify the exact method and `handlingContext` / `context`. When the caller shows its own error, also `verifyNever` on `trackIssue` — that is the guard against two messages for one failure.

```dart
test('should report a failed load as handled, not as a notice', () async {
  final error = DioException(
    requestOptions: RequestOptions(path: '/todos'),
    message: 'boom',
  );
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

`verifyNever` lists every named argument with `any(named: …)`. Leave one out and mocktail only matches calls that used its default, so the guard misses the rest.

For `trackIssue`, verify `context:` and `message:` as values, and `notifyOnConnectivityError:` on a rollback path. A timeout is the case that flag exists for, so use one. `.tr()` needs `setUpAll(initLocalizationForTests)` from `test/helpers/pump_app.dart`. Illustrative: `onTodoDismissed` and `homePage_deleteTodoFailed` do not exist in this repo.

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

- A layer that **rethrows** must not track: verify `verifyNever` on all three methods there, and the tracking in the caller's test. For a store that restores then rethrows, also assert the state came back: the removed item is at its old index.
- The service's own filtering (offline, cancellation, `401`) is tested once, in `test/core/services/issue_tracking_service_test.dart`. Do not re-test it per store.

## Reacting to observables

When the assertion is about a *change* rather than a final value, use MobX's own tools:

```dart
final values = <bool>[];
final dispose = autorun((_) => values.add(store.isLoading));

await store.loadTodos();

expect(values, [false, true, false]);
dispose();
```

Always dispose the reaction, or it leaks into the next test. (A test file that imports all of `package:mobx` cannot also use mocktail's `when` — see the gotchas below.)

## Fixtures

Realistic API payloads live as files under `test/fixtures/`, grouped by feature (`test/fixtures/todos/todo.json`), not as long string literals inside tests. Load them with a small helper, added once at `test/helpers/fixture.dart`:

```dart
import 'dart:convert';
import 'dart:io';

/// Reads `test/fixtures/{path}` as a string.
String fixture(String path) => File('test/fixtures/$path').readAsStringSync();

/// Reads `test/fixtures/{path}` as a JSON object.
Map<String, dynamic> jsonFixture(String path) =>
    jsonDecode(fixture(path)) as Map<String, dynamic>;
```

```dart
final todo = TodoDto.fromJson(jsonFixture('todos/todo.json'));
```

- Paths are relative to the package root, which is where `flutter test` and `melos run test` run.
- The helper reads synchronously on purpose: async file IO inside `testWidgets` runs in a fake-async zone and never completes unless wrapped in `tester.runAsync`.
- A fixture is a copy of a real response. Parsing it through the DTO's `fromJson` also tests the DTO against what the server sends.
- Small, hand-built values (`TodoDto(id: '1', …)`) stay inline. Use a fixture when the payload is large, nested, or pasted from the API.

## Widget test

Register a mock state in `getIt`, pump the page through the shared harness, and assert each branch renders.

```dart
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(initLocalizationForTests);

  late _MockHomeStore store;
  late _MockHomePageState state;

  setUp(() {
    store = _MockHomeStore();
    state = _MockHomePageState();
    when(() => state.store).thenReturn(store);
    when(state.init).thenAnswer((_) async {});
    getIt.registerFactory<HomePageState>(() => state);
  });

  tearDown(getIt.reset);

  testWidgets('should show the empty state when there are no todos', (tester) async {
    when(() => store.todos).thenReturn(ObservableList.of([]));
    when(() => store.isLoading).thenReturn(false);
    when(() => store.error).thenReturn(null);

    await tester.pumpApp(const HomePage());

    expect(find.byKey(const Key(HomeKeys.emptyState)), findsOneWidget);
    expect(find.byKey(const Key(HomeKeys.todoList)), findsNothing);
  });
}
```

Working example: [`test/features/home/view/home_page_test.dart`](../../../test/features/home/view/home_page_test.dart).

- **Find by key, never by displayed text.** Text is localized and will change. Ids are Strings (so Maestro can use the same value), so wrap them: `find.byKey(const Key(HomeKeys.emptyState))`. A list row is found by the `ValueKey(item.id)` it is keyed with.
- Test **wiring**, not logic: does the branch render, does the callback fire. Business logic belongs in the state/store unit test where it is cheap.
- Cover all four branches: loading, error, empty, content — plus one `dark: true` pump.

### Rows keep their element when a row is removed

A list whose rows can be removed or inserted gets this test ([`create-page`](../create-page/SKILL.md#lists-whose-rows-are-removed-or-inserted)). Capture the `Element` of a row that survives, remove a row above it, and check the survivor is the same `Element`, not a rebuilt one:

```dart
// import 'package:mobx/mobx.dart' show ObservableList, runInAction;

testWidgets('should keep the rows below a removed todo mounted', (tester) async {
  final todos = ObservableList.of([_todo('1'), _todo('2'), _todo('3')]);
  when(() => store.todos).thenReturn(todos);
  when(() => store.isLoading).thenReturn(false);
  when(() => store.error).thenReturn(null);
  await tester.pumpApp(const HomePage());

  final survivor = tester.element(find.byKey(const ValueKey('3')));

  runInAction(() => todos.removeAt(0));
  await tester.settleFrames();

  expect(tester.element(find.byKey(const ValueKey('3'))), same(survivor));
});
```

- Without `findItemIndexCallback` / `findChildIndexCallback`, row `'3'` is rebuilt from scratch and `same` fails. That is the defect this catches: rows below a removed one lose their state and replay their entry animation.
- The test changes the data the way the store would, then asserts what the page did with it. Mutate the `ObservableList` inside `runInAction`: the page observes it, and MobX rejects a write outside an action.

### Overriding the page state

Which override a test uses depends on what it pumps ([ADR-0009](../../../docs/adr/0009-provider-based-state-access.md)):

| The test pumps | The state comes from | So the test |
|---|---|---|
| **The whole page** (`HomePage`) | the page root's `Provider(create: (_) => getIt<HomePageState>())` | registers the mock in `getIt` and resets it afterwards |
| **A widget below the root** that calls `context.read<HomePageState>()` | the nearest `Provider` above it | wraps the widget in `Provider<HomePageState>.value` — no DI swap |

Whole page:

```dart
setUp(() {
  getIt.registerFactory<HomePageState>(() => mockState);
});
tearDown(getIt.reset);
```

Sub-widget (any public widget under `view/widgets/` that reads the state):

```dart
await tester.pumpApp(
  Provider<HomePageState>.value(
    value: mockState,
    child: const TodoListSection(),
  ),
);
```

`Provider.value` never calls `init()` or `dispose()` on the mock, so stub only what the widget reads. Private widgets (`_TodoCard`) cannot be imported; test them through the page, or make the widget public in `widgets/` when it deserves its own test.

### Three gotchas the harness already solves

Use `test/helpers/pump_app.dart`. It exists because each of these costs an hour to rediscover:

1. **`mobx` and `mocktail` both export `when`.** A test importing both fails to compile with *"'when' is imported from both …"*. Import mobx narrowly: `import 'package:mobx/mobx.dart' show ObservableList;`
2. **Do not mount `EasyLocalization` per test.** Its asset load is asynchronous; on the *second* `testWidgets` in a file it never resolves under `pump()`, so the whole tree renders empty and every finder returns nothing — with no error. `initLocalizationForTests()` loads the translations once into the `Localization` singleton in `setUpAll` instead. Skipping localization entirely is not an option either: `.plural()` throws `LateInitializationError` on the uninitialised locale.
3. **Never `pumpAndSettle` these screens.** The skeleton loader and the FAB animation never reach a steady state, so it times out after 10 s instead of failing usefully. Use the harness's bounded `settleFrames()`.

## Platform channel test

Fake the native side with a mock method-call handler on the test binary messenger, and clear it in `tearDown`. Assert the method name and arguments against the contract, the typed result, and the tracking call on a `PlatformException`. Full example: [`add-platform-channel`](../add-platform-channel/SKILL.md#tests).

## API provider test

A Retrofit provider's interface is not generated code: its annotations are hand-written, and a store test that mocks the provider cannot see a wrong method or path. Each endpoint gets a request-shape test that builds the real provider over a `Dio` whose `httpClientAdapter` is a fake recording the `RequestOptions`, then asserts method and path (`DELETE /todos/2`). Full example: [`create-api-provider`](../create-api-provider/SKILL.md#test-the-request-shape).

## What not to test

- The contents of generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`) line by line. Test the behaviour they produce instead: a DTO parsing a fixture, a provider sending the right request.
- Framework behaviour — that `Provider` provides, that `Observer` observes.
- Getters that return a field.

## Running

```bash
melos run test                                   # app + packages
flutter test test/features/home/                 # one directory
flutter test test/features/home/mobx/home_store_test.dart   # one file
flutter test --name 'should set error'           # one test, by name
flutter test --reporter expanded                 # one line per test, for a failing run
melos run test:coverage                          # lcov
```

## Checklist

- [ ] Right tier: logic in unit tests, branches in widget tests, journeys in Maestro
- [ ] Path mirrors `lib/`
- [ ] `group()` named after the class; test names start with `should`
- [ ] Faked at the seam below, never at the layer under test
- [ ] Store/use-case tests cover success, failure, and empty
- [ ] Failure tests assert loading was cleared **and** verify the tracking method and `context` / `handlingContext` (plus `message` for `trackIssue`)
- [ ] `verifyNever` on `trackIssue` lists every named argument
- [ ] Large payloads come from `test/fixtures/`, loaded with the fixture helper
- [ ] Widget tests find by key, never by displayed text; cover loading / error / empty / content
- [ ] Removable or insertable rows: the survivor's `Element` is `same` before and after a removal
- [ ] New API endpoint: request-shape test over a fake `HttpClientAdapter`
- [ ] Whole page → mock registered in `getIt`; sub-widget → `Provider.value`
- [ ] Every test could fail if the real code broke; no assertion reads back a stub's own side effect
- [ ] Reactions disposed, mock handlers cleared, `getIt` reset; no cross-test leakage
