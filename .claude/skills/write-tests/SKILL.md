---
name: write-tests
description: Write unit and widget tests — where each layer is tested, mocktail fakes at the right seam, MobX observable assertions, widget tests for the loading/error/empty/content branches, and the "can this fail if the real code is broken?" check. Use whenever adding or changing a store, state, use case, service or page.
---

# Write unit and widget tests

Governed by [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). Unit and widget tests are two of the three mandatory tiers; the third is [`write-maestro-flow`](../write-maestro-flow/SKILL.md).

## Where tests live

`test/` mirrors `lib/`.

```
test/
  features/{feature}/
    mobx/{feature}_store_test.dart
    view/{feature}_page_state_test.dart
    view/{feature}_page_test.dart          widget test
    use_cases/{name}_use_case_test.dart
  core/…
  helpers/                                  shared fakes + pump helpers
```

## Test the seam below the unit

Each layer has exactly one collaborator type to fake ([ADR-0001](../../../docs/adr/0001-layered-architecture.md)):

| Testing | Fake | Never fake |
|---|---|---|
| Store | `DioService` (or the provider it exposes) | the store's own observables |
| Page state | the store, `AppNavigator`, use cases | the state under test |
| Use case | `DioService` / services / `AppNavigator` | — |
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
// ❌ tests the mock, not the code
when(() => store.loadTodos()).thenAnswer((_) async {});
await state.init();
verify(() => store.loadTodos()).called(1);   // passes even if init() is empty… no, but
                                             // it asserts a call, not an outcome
```

Assert the **observable outcome** — state after the act — not just that a collaborator was called. `verify` is right when the *only* effect is the call (navigation, analytics); it is wrong as a substitute for asserting resulting state.

## Store test

```dart
class _MockDioService extends Mock implements DioService {}
class _MockTodosProvider extends Mock implements TodosApiProvider {}

void main() {
  late _MockDioService dioService;
  late _MockTodosProvider todosProvider;
  late HomeStore store;

  setUp(() {
    dioService = _MockDioService();
    todosProvider = _MockTodosProvider();
    when(() => dioService.todosProvider).thenReturn(todosProvider);
    store = HomeStore(dioService, _FakeAuthStore());
  });

  group('HomeStore', () {
    test('should expose loaded todos and clear loading on success', () async {
      when(() => todosProvider.getTodos())
          .thenAnswer((_) async => [TodoDto(id: '1', title: 'a', completed: false)]);

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
      expect(store.isLoading, isFalse);   // the finally-block regression guard
      expect(store.todos, isEmpty);
    });
  });
}
```

Every store test covers at minimum: **success**, **API failure**, **empty result**. The failure case must assert that loading was cleared — a spinner that never stops is the most common production symptom.

## Reacting to observables

When the assertion is about a *change* rather than a final value, use MobX's own tools:

```dart
final values = <bool>[];
final dispose = autorun((_) => values.add(store.isLoading));

await store.loadTodos();

expect(values, [false, true, false]);
dispose();
```

Always dispose the reaction, or it leaks into the next test.

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

    expect(find.byKey(HomeKeys.emptyState), findsOneWidget);
    expect(find.byKey(HomeKeys.todoList), findsNothing);
  });
}
```

Working example: [`test/features/home/view/home_page_test.dart`](../../../test/features/home/view/home_page_test.dart).

- Find by the feature's `Key` constants, not by text — text is localized and will change.
- Test **wiring**, not logic: does the branch render, does the callback fire. Business logic belongs in the state/store unit test where it is cheap.
- Cover all four branches: loading, error, empty, content — plus one `dark: true` pump.

### Three gotchas the harness already solves

Use `test/helpers/pump_app.dart`. It exists because each of these costs an hour to rediscover:

1. **`mobx` and `mocktail` both export `when`.** A test importing both fails to compile with *"'when' is imported from both …"*. Import mobx narrowly: `import 'package:mobx/mobx.dart' show ObservableList;`
2. **Do not mount `EasyLocalization` per test.** Its asset load is asynchronous; on the *second* `testWidgets` in a file it never resolves under `pump()`, so the whole tree renders empty and every finder returns nothing — with no error. `initLocalizationForTests()` loads the translations once into the `Localization` singleton in `setUpAll` instead. Skipping localization entirely is not an option either: `.plural()` throws `LateInitializationError` on the uninitialised locale.
3. **Never `pumpAndSettle` these screens.** The skeleton loader and the FAB animation never reach a steady state, so it times out after 10 s instead of failing usefully. Use the harness's bounded `settleFrames()`.

### Overriding DI in a widget test

`Provider(create:)` resolves the state from `getIt`, so a widget test registers a mock and resets afterwards:

```dart
setUp(() {
  getIt.registerFactory<HomePageState>(() => mockState);
});
tearDown(getIt.reset);
```

## What not to test

- Generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`).
- Framework behaviour — that `Provider` provides, that `Observer` observes.
- Getters that return a field.

## Running

```bash
melos run test                              # all packages
flutter test test/features/home/            # one directory
flutter test --name 'should set error'      # one test
melos run test:coverage                     # lcov
```

## Checklist

- [ ] Path mirrors `lib/`
- [ ] `group()` named after the class; test names start with `should`
- [ ] Faked at the seam below, never at the layer under test
- [ ] Store/use-case tests cover success, failure, and empty
- [ ] Failure tests assert loading was cleared
- [ ] Widget tests find by `Key`, cover loading / error / empty / content
- [ ] Every test could fail if the real code broke
- [ ] Reactions disposed; no cross-test leakage
