# 18. Widget Construction Discipline: No Widget-Returning Methods, No `BuildContext` Parameters

- Status: Accepted
- Date: 2026-09-17
- Deciders: Flutter team

## Context and Problem Statement

When a `build()` grows, two shortcuts are tempting, and both look like clean refactors:

1. Extract a chunk into a private method that returns a widget: `Widget _buildHeader() { ... }`.
2. Pass `BuildContext` into a helper: `Widget buildSection(BuildContext context, ...)` or `void showError(BuildContext context, ...)`.

Both are traps. A method-returned widget is not its own element in the tree: it rebuilds every time its parent does, even when its inputs are unchanged. It cannot be `const`, it has no equality short-circuit, it cannot hold its own `Observer` boundary, and it has no surface a widget test can pump on its own. A helper that takes `BuildContext` hides what it depends on, lets provider and theme lookups leak into code that should be plain, and breaks when that helper is called from outside a build phase, such as from an action or a callback after the widget is gone.

This codebase already avoids both, but nothing wrote the rule down, so nothing stops the next change from introducing them. The rule needs to be mechanical enough that review, human or agent, can apply it without judgement.

## Decision Drivers

- Rebuilds must be scoped to the smallest widget that depends on the changing data ([ADR-0001](0001-layered-architecture.md), MobX `Observer` placement).
- Visual pieces should be testable as units; methods are not.
- `const` constructors and `Observer` boundaries need real widget classes, not inlined fragments.
- `BuildContext` is a pointer into the tree with a lifetime; it must not leak into business logic, use cases, or callbacks that outlive it.

## Considered Options

- **Forbid both**: extract every reusable fragment into a `StatelessWidget` / `HookWidget` class, and never pass `BuildContext` to methods.
- **Allow widget-returning methods; forbid `BuildContext` parameters.**
- **Allow both**: leave it to the engineer.

## Decision Outcome

Chosen option: **Forbid both.**

### No widget-returning methods

```dart
// ❌ FORBIDDEN — methods that return widgets
class _Page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [_buildHeader(), _buildBody()]);
  }

  Widget _buildHeader() => Text(LocaleKeys.page_title.tr());
  Widget _buildBody() => const _Content();
}

// ✅ CORRECT — real widget classes; file-private is fine
class _Page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(children: [_Header(), _Body()]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Text(LocaleKeys.page_title.tr());
}
```

### No `BuildContext` parameters

```dart
// ❌ FORBIDDEN — context passed into a helper
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ✅ CORRECT — the widget that owns the context uses it directly,
// and anything that must act from non-build code goes through a service
// that already holds the navigator key, such as AppNavigator (ADR-0008).
```

Helpers receive plain data. If a helper needs the navigator, scaffold, or overlay from outside a build phase, it goes through `AppNavigator` ([ADR-0008](0008-appnavigator-routing-abstraction.md)) rather than taking a context.

### Allowed exceptions

- **Framework builder callbacks** whose signature the framework fixes: `ListView.builder`, `GridView.builder`, `PageView.builder`, `Builder`, `LayoutBuilder`, `OrientationBuilder`, `FutureBuilder`, `StreamBuilder`, `ValueListenableBuilder`, the `builder:` of `showDialog` / `showModalBottomSheet` / `showMenu`, `PageRouteBuilder`, and AutoRoute page builders.
- **Extension methods on `BuildContext`** such as `context.geist`, `context.read<T>()` and `context.tr`. These extend the context type rather than propagating it.
- **Hooks** that read context internally, since hooks only run during build.

### Consequences

- Good: every visual chunk is a real widget, so it can be `const` when its inputs are constant, pumped alone in a widget test, and used as a natural `Observer` boundary.
- Good: extraction forces cleaner data flow; a child widget declares exactly the data it needs instead of reaching through the context.
- Good: context-free helpers are plain functions, safe to call from actions, callbacks and use cases.
- Bad: more class declarations per file. File-private classes (`_Header`) keep the cost local.
- Bad: engineers coming from other Flutter codebases have to unlearn the `Widget _buildX()` habit.

## Pros and Cons of the Options

### Forbid both
- Good: real elements, `const`, a test surface, scoped rebuilds, and an explicit dependency surface.
- Bad: somewhat more code.

### Allow widget-returning methods, forbid `BuildContext` parameters
- Good: less ceremony for trivial extractions.
- Bad: keeps the hidden rebuild cost and loses `const` and the test boundary. Large `build()` methods get split into long `_buildX` procedures that read top to bottom but still rebuild as one unit.

### Allow both
- Good: no friction.
- Bad: hides provider and theme dependencies, and produces lifetime bugs when helpers run outside build.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0008 `AppNavigator` routing abstraction](0008-appnavigator-routing-abstraction.md) — context-free navigation
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- [ADR-0010 `HookWidget` default](0010-hookwidget-default.md)
- [ADR-0019 Hook selection](0019-hook-selection.md)
- Playbook: [`create-page`](../../.claude/skills/create-page/SKILL.md)
- Adopted from `krisp-mobile` ADR-0014.
