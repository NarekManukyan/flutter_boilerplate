---
name: create-ds-component
description: Build a reusable component inside packages/design_system — directory layout, barrel exports, named-constructor variants, shared base widgets, token-only styling, and the app-vs-design-system placement decision. Use when adding or changing a widget in the design system package, or deciding whether a widget belongs there at all.
---

# Create a design-system component

Governed by [ADR-0014](../../../docs/adr/0014-melos-package-split.md) (package boundary) and [ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md) (tokens only). Visual spec: [`DESIGN.md`](../../../DESIGN.md).

Concepts behind this playbook: [`performance-guide`](../../../docs/performance-guide.md).

## Does it belong here?

| Widget | Home |
|---|---|
| Generic, app-agnostic, no feature knowledge — button, input, avatar, modal chrome | `packages/design_system/lib/src/components/` |
| Reused across features but app-specific — knows a store, a route, a `LocaleKey` | `lib/core/ui/` |
| Used by one feature only | `lib/features/{feature}/components/` |

The test: **could another app use this unchanged?** If it imports anything from `lib/`, the answer is no and it does not go in the package.

## Layout

```
packages/design_system/lib/
  design_system.dart              the only public entry — everything is exported here
  src/
    components/
      components.dart             barrel
      src/
        {component}/              one directory per non-trivial component
          {component}.dart        barrel
          src/                    implementation parts + shared base widgets
    core/src/constants/           kSpacingNpx, kBorderRadiusNpx …
    theme/src/                    GeistTheme, GeistTextStyles, GeistRadius, GeistDuration
  gen/                            GENERATED assets/colors/fonts — never edit
```

Naming: `*_widget.dart` or the descriptive name (`primary_button.dart`), `*_theme.dart`, `*_constants.dart`, `*_utils.dart`.

A component is exported from its own barrel → `components.dart` → `design_system.dart`. A component not reachable from `design_system.dart` does not exist as far as `lib/` is concerned.

## Variants are named constructors, not booleans

```dart
enum _ButtonType { filled, text }

class PrimaryButton extends HookWidget {
  const PrimaryButton.largeFilled({
    super.key,
    required this.onPressed,
    required this.child,
    this.leftIcon,
    this.rightIcon,
    this.isLoading = false,
    this.isDisabled = false,
  })  : _size = ButtonSize.large,
        _type = _ButtonType.filled;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final bool isLoading;
  final bool isDisabled;
  final ButtonSize _size;
  final _ButtonType _type;

  @override
  Widget build(BuildContext context) => switch (_type) {
        _ButtonType.filled => MyFilledButton(/* … */),
        _ButtonType.text => MyTextButton(/* … */),
      };
}
```

- **Named constructors per variant** — `PrimaryButton.largeFilled()`, not `PrimaryButton(size: …, type: …)`. The call site reads as the design, and an invalid combination becomes unrepresentable.
- **Private enums** for type and size; the variant is fixed by the constructor, not passed in.
- Shared behaviour lives in a base widget (`MyFilledButton`) under `src/`; the public component only picks one.
- `const` constructors wherever the widget allows it.
- Optional parameters get sensible defaults so the common case is one line.

## Styling

Tokens only. A component inside the package reads the same tokens app code does, and it reads colours through the theme, so an app that overrides `GeistTheme` restyles the component too:

- Colours → `context.geist.*`, read once at the top of `build`
- Text → `GeistTextStyles.*`, colour applied with `.copyWith(color: …)` at the use site
- Radii → `GeistRadius.*` · Durations → `GeistDuration.*`
- Spacing → `kSpacingNpx` for padding; `Gap(kSpacingNpx)` between siblings in a `Row` or `Column`, never `SizedBox`
- Shadows → the composed stacks on `GeistTheme` (`cardShadow`, `ringShadow`)

No raw `Color(0x…)`, no `TextStyle(…)` composite, no hand-assembled `BoxShadow` list — in the package either.

When a token is missing, decide its kind before adding it: **does it need a different value in dark mode?** If yes, it is a theme-aware field on `GeistTheme` with a light **and** a dark value — never a constant, because a constant renders the light value in dark mode. If no, it is a static constant (`GeistRadius`, `GeistDuration`, `GeistTextStyles`, spacing). The dark value of a theme-aware token is not optional, and forgetting it is not always a compile error: if the extension is missing from one theme, `context.geist` silently falls back to the light values at runtime. Full steps: [`add-design-token`](../add-design-token/SKILL.md).

## Local state inside a component

Components in the package default to `useValueNotifier`, not `useState` ([ADR-0019](../../../docs/adr/0019-hook-selection.md)). A design-system widget is used everywhere, so a whole-widget rebuild on every toggle multiplies across the app. Scope the rebuild with a `ValueListenableBuilder` around the part that changes, cache anything built in `build()` with `useMemoized`, and never write a `Widget _buildX()` method: extract a private widget class instead ([ADR-0018](../../../docs/adr/0018-widget-construction-discipline.md)).

## The six states

A component is unfinished until default, pressed, hover, focus, disabled and loading are all defined — see `DESIGN.md` §12. Loading keeps the control the same size; disabled stays readable (≥ 3:1) rather than washing out.

## Accessibility and testability

- Interactive components take an optional `semanticsLabel` and wrap in `Semantics`. The *label text* comes from the caller — `LocaleKeys` lives in `lib/`, so the package never hardcodes copy.
- Touch targets ≥ 44×44 pt, expanded with padding rather than by growing the glyph.
- The component passes `key` through (`super.key`) so callers can tag it with `TestId` for E2E ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

## Codegen

Assets, brand colours (`assets/colors/colors.xml` → `AppColors`) and fonts under `packages/design_system/lib/gen/` are generated, and so is the Tailor `CustomTheme` mixin. After adding or changing any of them, re-run the design-system codegen:

```bash
melos run build:design_system
```

Then `melos run build:app` if the app uses the changed type, or `melos run build` to run everything in order ([ADR-0014](../../../docs/adr/0014-melos-package-split.md)). Never edit `gen/` or `*.tailor.dart` by hand. `GeistTheme` and the static token classes are hand-written and need no codegen.

## Checklist

- [ ] Belongs in the package — imports nothing from `lib/`
- [ ] Own directory with a barrel, exported through `design_system.dart`
- [ ] Variants are named constructors; type and size are private
- [ ] Local state uses `useValueNotifier`; no `Widget _buildX()` methods
- [ ] Shared behaviour extracted to a base widget under `src/`
- [ ] Tokens only — no raw colour, text style, radius, duration or shadow stack
- [ ] New token: theme-aware (light **and** dark on `GeistTheme`) if it differs in dark mode, static constant otherwise
- [ ] Sibling spacing is `Gap(kSpacingNpx)`
- [ ] `melos run build:design_system` run after an asset, font or brand-colour change
- [ ] All six states defined; light and dark both correct at WCAG AA
- [ ] `super.key` passed through; `semanticsLabel` accepted for interactive components
- [ ] `DESIGN.md` updated if this introduces a new visual pattern
