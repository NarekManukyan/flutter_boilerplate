---
name: create-use-case
description: Build a *_use_case.dart — the four use-case types, where to put it based on which layer consumes it, when to promote it, and the no-use-case-depends-on-a-use-case rule. Use when extracting an operation out of a store or state, or when deciding whether logic deserves its own class.
---

# Create a use case

Governed by [ADR-0003](../../../docs/adr/0003-no-use-case-to-use-case-dependencies.md) (no UC → UC), [ADR-0004](../../../docs/adr/0004-use-case-taxonomy-and-colocation.md) (taxonomy + colocation).

A use case encapsulates **one** business operation. `@injectable` class, single `call()` method, invoked with call syntax.

```dart
@injectable
class CreateTodoUseCase {
  final DioService _dioService;

  CreateTodoUseCase(this._dioService);

  Future<TodoDto?> call(String title) async {
    try {
      return await _dioService.todosProvider.createTodo(
        todoCreateDto: TodoCreateRequestDto(title: title),
      );
    } on DioException {
      return null;
    }
  }
}

// call site — no .call()
final todo = await _createTodoUseCase(title);
```

## The one hard rule: no use case depends on another use case

A UC may inject `DioService`, services, stores and `AppNavigator`. It may **not** inject another use case. When two use cases need the same logic, that logic becomes a **service** — never a peer UC dependency. This keeps the dependency graph one level deep and stops chains that are impossible to test in isolation.

## The four types

| Type | Injects | Does |
|---|---|---|
| **API** | `DioService` | one request + error translation |
| **Navigation** | `AppNavigator` | one navigation decision, possibly conditional |
| **Service coordination** | 2+ services | orchestrates a multi-service operation |
| **State delegation** | a store | delegates a mutation the caller should not own |

If a class is doing two of these, it is two use cases.

## Where it goes — by consumer, not by topic

| Consumed by | Path |
|---|---|
| One store only | `lib/features/{feature}/mobx/use_cases/` |
| One state / view only | `lib/features/{feature}/view/use_cases/` |
| One modal only | `lib/features/{feature}/modals/{modal}/use_cases/` |
| 2+ layers of the same feature | `lib/features/{feature}/core/use_cases/` |
| 2+ features | `lib/core/use_cases/` |

**Promote on the second consumer.** A UC used by one store stays in `mobx/use_cases/`; the day a modal state also needs it, move it to `{feature}/core/use_cases/`; the day another feature needs it, move it to `lib/core/use_cases/`. Do not pre-promote "because it feels shared" — placement follows actual consumers.

## Extract or keep inline?

**Extract** when it is reused in 2+ places, coordinates 2+ services, or is complex enough to deserve its own test.

**Keep inline** when it is a one-line delegation. `Future<void> logout() => _authStore.clearSession();` does not need a class.

## Error handling

Catch at the use-case boundary and return a value the caller can branch on — `null`, a sealed result, or a bool. Do not let `DioException` leak to a state class. If the app tracks issues, report inside the catch via an injected service.

Returning bare `null` for every failure loses the reason. When the caller must distinguish "not found" from "offline", return a sealed result type instead.

## Checklist

- [ ] One operation, one `call()` method
- [ ] `@injectable`, constructor injection only — never `getIt<>()` inside
- [ ] Injects no other use case
- [ ] Placed next to its consumer layer; promoted only when a second consumer appears
- [ ] Errors caught and translated at this boundary
- [ ] `melos run build` after adding the annotation
- [ ] Unit test covers success and failure — [`write-tests`](../write-tests/SKILL.md)
