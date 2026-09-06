---
name: create-ds-component
description: Build a reusable component inside packages/design_system — directory layout, barrel exports, named-constructor variants, shared base widgets, token-only styling, and the app-vs-design-system placement decision. Use when adding or changing a widget in the design system package, or deciding whether a widget belongs there at all.
---

# Create a design-system component

Governed by [ADR-0014](../../../docs/adr/0014-melos-package-split.md) (package boundary) and [ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md) (tokens only). Visual spec: [`DESIGN.md`](../../../DESIGN.md).

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

Tokens only — the component is *inside* the design system, so it reads them directly rather than through `context.geist` where a `ThemeExtension` lookup would be circular:

- Colours → `context.geist.*` (components still resolve through the theme, so an app override works)
- Text → `GeistTextStyles.*`, colour applied with `.copyWith(color: …)` at the use site
- Radii → `GeistRadius.*` · Durations → `GeistDuration.*` · Spacing → `kSpacingNpx`
- Shadows → the composed stacks on `GeistTheme` (`cardShadow`, `ringShadow`)

No raw `Color(0x…)`, no `TextStyle(…)` composite, no hand-assembled `BoxShadow` list — in the package either. A new token goes through [`add-design-token`](../add-design-token/SKILL.md), with a light **and** a dark value.

## The six states

A component is unfinished until default, pressed, hover, focus, disabled and loading are all defined — see `DESIGN.md` §12. Loading keeps the control the same size; disabled stays readable (≥ 3:1) rather than washing out.

## Accessibility and testability

- Interactive components take an optional `semanticsLabel` and wrap in `Semantics`. The *label text* comes from the caller — `LocaleKeys` lives in `lib/`, so the package never hardcodes copy.
- Touch targets ≥ 44×44 pt, expanded with padding rather than by growing the glyph.
- The component passes `key` through (`super.key`) so callers can tag it with `TestId` for E2E ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

## Codegen

Assets, colours and fonts under `packages/design_system/lib/gen/` are generated. After adding an asset or font, run:

```bash
melos exec --scope design_system -- "dart run build_runner build -d"
```

Never edit `gen/`.

## Checklist

- [ ] Belongs in the package — imports nothing from `lib/`
- [ ] Own directory with a barrel, exported through `design_system.dart`
- [ ] Variants are named constructors; type and size are private
- [ ] Shared behaviour extracted to a base widget under `src/`
- [ ] Tokens only — no raw colour, text style, radius, duration or shadow stack
- [ ] All six states defined; light and dark both correct at WCAG AA
- [ ] `super.key` passed through; `semanticsLabel` accepted for interactive components
- [ ] `DESIGN.md` updated if this introduces a new visual pattern
