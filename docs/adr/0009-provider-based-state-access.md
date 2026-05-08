# 9. Provider-Based State Access in Widgets

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

A page's state class (`*_state.dart`) is consumed by many widgets in the page tree — content, header, dialogs, footers. Two ways to wire it: pass the state down as constructor arguments, or expose it through `Provider` once at the page root and let descendants read it via `context.read<T>()`.

Passing state down forces every intermediate widget to declare a parameter it does not use. It also tightly couples widgets to a specific state class — refactoring or reusing a section means rewriting its constructor signature.

## Decision Drivers

- Refactor cost — extracting or moving widgets should not ripple through constructor signatures.
- Reuse — `_Header`, `_Footer`, etc., should not need a state-class parameter to compile.
- DI seam — there should be one allowed `getIt<>()` site (the page root), not many.

## Considered Options

- **`Provider` at the page root, `context.read<T>()` in descendants**.
- **Constructor parameters all the way down**.
- **`InheritedWidget` hand-rolled per state class**.
- **MobX `Observer` rebuild + locator inside each widget**.

## Decision Outcome

Chosen option: **`Provider` at the page root**.

The page widget (a `StatelessWidget` or `HookWidget`) creates a `Provider<MyPageState>` whose `create:` resolves the state from `getIt`, calls `init()`, and disposes it on unmount. Descendant widgets read it with `context.read<MyPageState>()` (or `context.watch<...>()` for rebuilding consumers).

This is the single allowed `getIt<>()` site outside DI bootstrap (per [ADR-0007](0007-di-scopes-and-constructor-injection.md)).

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => getIt<MyPageState>()..init(),
      dispose: (_, value) => value.dispose(),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.read<MyPageState>();
    return Scaffold(/* ... */);
  }
}
```

### Consequences

- Good: descendant widgets are decoupled from the state class — refactor and extract freely.
- Good: one place that calls `getIt`, easy to audit.
- Good: state lifecycle (`init` / `dispose`) is bound to the `Provider` lifetime, not to a manually-managed `StatefulWidget`.
- Bad: a widget that forgets to wrap its subtree with the right `Provider` fails at runtime, not compile time.
- Bad: requires the `provider` package as a dependency.

## Pros and Cons of the Options

### `Provider` at the page root
- Good: one resolution site, free reuse of widgets.
- Bad: runtime failure on missing provider.

### Constructor parameters all the way down
- Good: compile-time safety.
- Bad: every intermediate widget grows a parameter; reuse impossible without renaming the parameter.

### Hand-rolled `InheritedWidget`
- Good: no extra dependency.
- Bad: boilerplate per state class (`updateShouldNotify`, `of(context)`); reinvents `provider`.

### `Observer` + locator per widget
- Good: no provider tree.
- Bad: every widget calls `getIt`, which spreads service-locator usage and breaks the rule from ADR-0007.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
- [ADR-0010 `HookWidget` default](0010-hookwidget-default.md)
