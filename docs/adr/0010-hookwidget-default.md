# 10. `HookWidget` as the Default Stateful Widget

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Most "stateful" widgets in this app need lightweight local concerns: a `TextEditingController`, a `ScrollController`, a `useEffect` to subscribe/unsubscribe, an animation controller. `StatefulWidget` answers all of these but with a verbose `State<T>` class, manual `initState` / `dispose`, and lifecycle bugs (forgot to dispose, late init order).

`flutter_hooks` collapses all four into composable hooks (`useTextEditingController`, `useScrollController`, `useEffect`, `useAnimationController`) with automatic disposal. Domain state already lives in MobX; widget-local concerns rarely justify a full `State<T>` class.

## Decision Drivers

- Less ceremony for common patterns (controllers, effects).
- Automatic resource disposal — no leaked controllers.
- Composable extraction — custom hooks vs custom `State<T>` subclass.

## Considered Options

- **`HookWidget` as default for any non-pure widget; `StatelessWidget` for pure presentation**.
- **`StatefulWidget` always; ban hooks**.
- **Mix freely with no policy**.

## Decision Outcome

Chosen option: **`HookWidget` default; `StatelessWidget` for pure presentation**.

- Pure presentation (no controllers, no effects, no local mutable state) → `StatelessWidget`.
- Anything that needs a controller, an effect, a local `useState`, or animation → `HookWidget`.
- `StatefulWidget` is allowed only when interacting with APIs that genuinely need a `State<T>` lifecycle method not available as a hook (rare).

```dart
class _Content extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    useEffect(() {
      final sub = stream.listen(_handle);
      return sub.cancel;
    }, const []);
    return TextField(controller: controller);
  }
}
```

### Consequences

- Good: shorter widget files; no manual disposal bugs.
- Good: extractable hooks let multiple widgets share lifecycle logic without inheritance.
- Good: matches the codebase's existing widgets — see [Quick Navigation in CLAUDE.md](../../CLAUDE.md).
- Bad: `flutter_hooks` adds a dependency and a small learning curve for `useEffect` keys / dependencies.
- Bad: stack traces include hook-internal frames when a hook misuse triggers a runtime error.

## Pros and Cons of the Options

### `HookWidget` default
- Good: terse, automatic disposal, composable.
- Bad: extra dependency; one more concept to learn.

### `StatefulWidget` always
- Good: zero added dependencies.
- Bad: verbose; manual `dispose` is bug-prone; controller setup boilerplate everywhere.

### Mix freely with no policy
- Bad: two patterns for the same thing in adjacent files; reviewers can't tell which to use.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- External: [flutter_hooks](https://pub.dev/packages/flutter_hooks)
