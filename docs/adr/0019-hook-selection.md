# 19. Hook Selection: `useValueNotifier` Over `useState`, `useMemoized` Whenever It Applies

- Status: Accepted
- Date: 2026-09-17
- Deciders: Flutter team

## Context and Problem Statement

`HookWidget` is the default for widget-local state ([ADR-0010](0010-hookwidget-default.md)). `flutter_hooks` offers several hooks that look interchangeable but rebuild very differently:

- `useState<T>(initial)` subscribes the whole widget. Every assignment rebuilds the entire `HookWidget`.
- `useValueNotifier<T>(initial)` returns a `ValueNotifier` **without** subscribing the widget. A subtree opts in with `ValueListenableBuilder` or `useValueListenable`, so only that subtree rebuilds.
- `useMemoized<T>(() => build(), [keys])` caches a value across rebuilds and recomputes it only when a key changes.

Reaching for `useState` by default rebuilds far more than necessary whenever only part of the widget cares about the value. This repo had exactly that: on the Home page a `useState` flag controlled whether the floating action button was shown, and it was set from a scroll listener. Every change of scroll direction rebuilt the whole page (the app bar, the filter bar and the list `Observer`) to move one button.

Skipping `useMemoized` has a quieter cost: controllers, parsed values and derived collections get reallocated on every rebuild, and because each rebuild produces a new instance, `==` checks further down fail and cause more rebuilds.

MobX owns feature and app state ([ADR-0002](0002-state-vs-store-separation.md)). Hooks cover what MobX is too heavy for: design-system components, small widgets, isolated UI state. That is where they need to be precise.

## Decision Drivers

- The rebuild scope should match the data dependency of each subtree.
- Values allocated during `build()` should be cached unless their inputs changed.
- A simple widget should not need MobX just to scope a rebuild.
- The rule should be mechanical enough for review.

## Considered Options

- **`useValueNotifier` by default for observable local state; `useMemoized` whenever a value can be cached.**
- **`useState` everywhere**, and let widgets rebuild.
- **MobX for all observable state**, including widget-local state.

## Decision Outcome

Chosen option: **Prefer `useValueNotifier` over `useState` whenever the state should be observable but does not warrant MobX, and use `useMemoized` whenever it applies.**

The main reason is rebuild scope. When only part of the widget depends on the value, `useValueNotifier` rebuilds that part and nothing else, which is exactly what the Home FAB above needed.

`useState` is **not** banned. It is correct when the value genuinely should rebuild the whole widget, for example a filter that changes everything a small widget renders. A filter that a derived list depends on belongs in MobX instead: the Home filter is `@readonly` on `HomePageState`, next to the `@computed visibleTodos` it drives.

### Which tool

| Need | Use |
|---|---|
| Feature state, business logic, app-wide data | MobX store or page state ([ADR-0002](0002-state-vs-store-separation.md)) |
| Local state that only a part of the widget depends on | `useValueNotifier` + `ValueListenableBuilder`, or `useValueListenable` |
| Subscribe to an existing `ValueNotifier` / `Listenable` | `useValueListenable` / `useListenable` |
| Local state that legitimately rebuilds the whole widget | `useState` |
| A controller per widget instance | the dedicated hook: `useTextEditingController`, `useScrollController`, `useFocusNode`, `useAnimationController`, `useTabController` (each disposes for you) |
| A controller with no dedicated hook | `useMemoized` to create it, `useEffect` to dispose it |
| A value created once per instance, or recomputed on key change | `useMemoized` |
| A side effect with cleanup | `useEffect` |
| Behaviour several widgets repeat — input formatting, debounced search, mention detection | a custom `useX` hook built from the hooks above (see [Custom hooks](#custom-hooks-for-reusable-behaviour)) |

Default to `useValueNotifier` for observable local state that does not warrant MobX. That covers these cases:

- only part of the tree reads the value (the main reason);
- the widget lives in `packages/design_system/`;
- it is a small component where MobX would be overkill, such as a search field's query, an expanded flag or a counter.

### Controllers and `useMemoized`

For a value that has to survive rebuilds, go in this order:

1. **A dedicated controller hook**, when `flutter_hooks` has one: `useTextEditingController`, `useScrollController`, `useFocusNode`, `useAnimationController`, `useTabController`, `usePageController` and the rest. It creates the controller once per widget instance and disposes it. Do not rebuild one of these by hand with `useMemoized` and a disposing `useEffect`.
2. **`useMemoized` as the fallback** for values without a dedicated hook, whose lifecycle you manage yourself. The key list decides when the value is recreated. If the value holds resources, a `useEffect` keyed on it disposes it.

`useMemoized` applies to:

- controllers without a dedicated hook, such as a third-party player or map controller, paired with a `useEffect` that disposes them;
- derived collections: filtered, sorted or grouped lists;
- parsed strings and decoded payloads;
- `RegExp` instances;
- formatted dates, and the `DateFormat` that produces them;
- anything else whose construction is non-trivial, or whose identity matters for `==` further down the tree.

### Examples

```dart
// ✅ useValueNotifier — only the subtree that reads the value rebuilds
class ExpandableCard extends HookWidget {
  const ExpandableCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isExpanded = useValueNotifier(false);

    return Column(
      children: [
        IconButton(
          onPressed: () => isExpanded.value = !isExpanded.value,
          icon: const Icon(Icons.expand_more),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isExpanded,
          builder: (_, expanded, _) =>
              expanded ? const _Body() : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ✅ Controllers — the dedicated hook, never a controller built in build()
final controller = useTextEditingController();

// ✅ No dedicated hook — useMemoized creates it, useEffect disposes it
final player = useMemoized(() => PlayerController(source), [source]);
useEffect(() => player.dispose, [player]);

// ✅ useMemoized — a parsed value, recomputed only when the input changes
final config = useMemoized(() => parseConfig(raw), [raw]);

// ✅ useMemoized — a derived collection, recomputed only when an input changes
final filtered = useMemoized(
  () => items.where((i) => i.matches(query)).toList(),
  [items, query],
);
```

### Custom hooks for reusable behaviour

When the same widget behaviour shows up in a second widget — formatting input as it is typed, debouncing a search field, detecting `@mentions` in a text field — extract it into a custom hook rather than copying the `useEffect` and controller wiring. A custom hook is a plain function whose name starts with `use`, built only from other hooks.

- **Check `flutter_hooks` first.** It already ships many hooks, including `useDebounced(value, timeout)` for a debounced *value*. Write a custom hook only for behaviour it does not cover.
- **Build it from primitives**: `useEffect` for anything with a cleanup, `useRef` for mutable values that must not rebuild, `useMemoized` / `useCallback` for stable instances, `useValueNotifier` for observable local state. The same rules apply inside the hook as in a widget: call hooks unconditionally, keep key lists complete, dispose what you create.
- **UI behaviour only.** A hook that calls an API, owns data another widget reads, or outlives the screen belongs in a MobX store or page state ([ADR-0002](0002-state-vs-store-separation.md)). The hook takes a callback, and the state does the work.
- **Location.** A hook used by one widget stays in that widget's file. A second consumer in the app moves it to `lib/core/hooks/use_{name}.dart`. A hook a design-system component needs lives in `packages/design_system`.

Example: a debounced callback, for a search field that should query only once typing pauses. `useEffect` owns the `Timer`'s cleanup, so a pending call never fires after the widget is gone.

```dart
// lib/core/hooks/use_debounced_callback.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Returns a function that passes its latest argument to [callback] once
/// [delay] has gone by without another call.
ValueChanged<T> useDebouncedCallback<T>(
  ValueChanged<T> callback, {
  required Duration delay,
}) {
  // Always call the newest closure the widget was built with.
  final latest = useRef(callback)..value = callback;
  final timer = useRef<Timer?>(null);

  // Cleanup: a call still pending when the widget unmounts must not fire.
  useEffect(() {
    return () => timer.value?.cancel();
  }, const []);

  return useCallback<ValueChanged<T>>((value) {
    timer.value?.cancel();
    timer.value = Timer(delay, () => latest.value(value));
  }, [delay]);
}
```

```dart
// lib/core/constants/timing_constants.dart — behaviour timing, not a GeistDuration
// motion token. Illustrative: TimingConstants exists, searchDebounce does not.
abstract final class TimingConstants {
  /// How long typing must pause before a search runs.
  static const searchDebounce = Duration(milliseconds: 300);
}
```

```dart
class TodoSearchField extends HookWidget {
  const TodoSearchField({super.key, required this.onQueryChanged});

  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = useDebouncedCallback(
      onQueryChanged,
      delay: TimingConstants.searchDebounce,
    );
    return TextField(onChanged: onChanged);
  }
}
```

- `useRef` holds the latest callback and the pending timer without causing rebuilds, and `useCallback` keeps the returned function identical across rebuilds, so the `TextField` does not see a new `onChanged` every frame.
- The widget stays a thin caller. The page state's `onQueryChanged` sets the store's query ([`create-store`](../../.claude/skills/create-store/SKILL.md#search-and-filtering)).
- Test a custom hook with `HookBuilder` in a widget test: pump it, call the returned function, advance time with `tester.pump(duration)`, and assert. Include the unmount case.

### Consequences

- Good: rebuilds stay inside the subtrees that depend on the value.
- Good: one controller per widget instance rather than one per rebuild, so controllers keep their text, selection and scroll position.
- Good: derived collections are allocated when their inputs change, not on every frame.
- Good: MobX stays reserved for state that is genuinely shared.
- Good: repeated widget behaviour (debouncing, formatting, mention detection) lives in one tested custom hook instead of copies of the same effect wiring.
- Bad: a little more wiring than `useState` (a `ValueListenableBuilder` or an explicit `useValueListenable`).
- Bad: engineers have to decide whether a value should rebuild the whole widget, which is not always obvious.
- Bad: a `useMemoized` with a missing key returns a stale value. The key list needs the same discipline as a `useEffect` dependency list.
- Bad: a controller created with `useMemoized` leaks if its disposing `useEffect` is forgotten, which is why the dedicated hooks come first.
- Bad: a custom hook hides its effects behind a function call, so a reviewer has to open it to see what it allocates and cleans up. Keep custom hooks small and tested.

## Pros and Cons of the Options

### `useValueNotifier` by default, `useMemoized` when it applies
- Good: scoped rebuilds without MobX; stable references.
- Bad: more wiring; dependency-list discipline.

### `useState` everywhere
- Good: simplest to write.
- Bad: each assignment rebuilds the whole widget even when only one child cares, and controllers created in `build()` lose their state.

### MobX for all observable state
- Good: one observability story everywhere.
- Bad: code generation and a store for a single boolean inside a design-system card.

## Links

- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0010 `HookWidget` default](0010-hookwidget-default.md)
- [ADR-0018 Widget construction discipline](0018-widget-construction-discipline.md)
- Playbooks: [`create-page`](../../.claude/skills/create-page/SKILL.md), [`create-ds-component`](../../.claude/skills/create-ds-component/SKILL.md)
- `flutter_hooks`: https://pub.dev/packages/flutter_hooks
