# 13. Design-System Tokens Only in `lib/`

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Once a `Color(0xFF...)` literal slips into a feature widget, it spreads. Each new feature copies the nearest neighbor; visual inconsistency compounds; dark-mode support requires hunting every literal across `lib/`. The same applies to ad-hoc `TextStyle(...)` composites, hand-rolled `BoxShadow` stacks, and arbitrary `Duration` values.

The remedy is a hard rule: every visual token comes from the design-system package — no exceptions in app code.

## Decision Drivers

- Visual consistency — designers control tokens in one place; app code consumes them.
- Dark-mode parity — every token that varies by theme has a light and a dark value, accessed through `ThemeExtension`s.
- WCAG AA compliance — token pairs are auditable; ad-hoc colors are not.

## Considered Options

- **DS tokens only — every color/style/shadow/radius/duration comes from `packages/design_system`**.
- **Tokens + escape hatches — bare hex allowed for "one-off" cases**.
- **Per-feature mini-themes — features define their own colors when needed**.

## Decision Outcome

Chosen option: **DS tokens only**.

The `lib/` layer must not contain raw `Color(0x…)` / hex literals, raw `TextStyle(...)` composites, or one-off shadow stacks. All tokens come from `packages/design_system`:

| Token | Kind | Access | Add new tokens in |
|---|---|---|---|
| Colors | theme-aware | `context.geist.<token>` (Geist palette) or legacy `context.<token>` (Tailor `CustomTheme`) | a `GeistTheme` field, with values in both `GeistTheme.light` and `GeistTheme.dark` |
| Shadows / elevation | theme-aware | `context.geist.cardShadow`, `shadowBorder`, `shadowFab`, etc. | a `GeistTheme` color field plus a derived getter |
| Typography | static | `GeistTextStyles.<role>`, colored from the theme: `GeistTextStyles.bodyM.copyWith(color: context.geist.muted)`; legacy `context.<textStyle>` | `GeistTextStyles` |
| Radii | static | `GeistRadius.<scale>` | `GeistRadius` |
| Durations | static | `GeistDuration.<speed>` | `GeistDuration` |
| Spacing | static | `kSpacingNpx` constants; `Gap(kSpacingNpx)` between siblings | `packages/design_system/lib/src/core/src/constants/constants.dart` |

`GeistTheme`, `GeistTextStyles`, `GeistRadius` and `GeistDuration` all live in [`geist_theme.dart`](../../packages/design_system/lib/src/theme/src/geist_theme.dart).

### Static and theme-aware tokens

A token is one of two kinds, and the kind decides where a new one goes.

- **Static tokens** are `const` values that are identical in every theme: spacing, radii, durations, and the metrics of a text style (size, weight, height, letter spacing). They are plain constants: `kSpacingNpx`, `GeistRadius`, `GeistDuration`, `GeistTextStyles`.
- **Theme-aware tokens** are values that differ between light and dark: every color (shadow colors included) and non-color values such as `focusHaloAlpha`. They are fields on the `GeistTheme` `ThemeExtension`, read through `context.geist`.

A value that differs between light and dark is always exposed through `context.geist` and never as a constant. A colour that is genuinely identical in both themes (a brand colour generated into the design system from `assets/colors/colors.xml`) is the one static colour case; a colour typed as a `Color(...)` constant in `lib/` never is.

Non-visual timing is not a design token. A debounce window, a request timeout or a retry backoff is a named `Duration` constant in `lib/core/constants/` (or next to the one class that uses it), never an inline literal. Motion durations — anything that times an animation or transition — always come from `GeistDuration`. That is why `GeistTextStyles` carries no color: the style is static, and the color is applied from the theme.

### Spacing

Space between siblings in a `Row`, `Column` or other flex uses `Gap(kSpacingNpx)` from `package:gap`, not `SizedBox(height: …)` or `SizedBox(width: …)`. `Gap` takes the axis of its parent, so the same spacer works in both directions. Padding around a widget uses `kSpacingNpx` values as well.

### Adding a token

1. Decide the kind. A static token goes into `GeistRadius`, `GeistDuration`, `GeistTextStyles` or the spacing constants. A theme-aware token becomes a field on [`GeistTheme`](../../packages/design_system/lib/src/theme/src/geist_theme.dart) (or the relevant `ThemeExtension`) with both `light` and `dark` values.
2. For a `GeistTheme` field, update `copyWith` and `lerp`.
3. Consume it in `lib/` through the token (`context.geist.newToken`, `GeistRadius.newScale`). Adding a token is the alternative to a local literal: never inline the hex, and never write a bespoke `TextStyle(...)` or `BoxShadow(...)` in its place.

The only "bare" colors permitted in `lib/` are `Colors.transparent` and the result of `Color.lerp` applied to tokens already sourced from the DS.

### Dark mode

Both `lightTheme` and `darkTheme` register `GeistTheme` (see [`light_theme.dart`](../../packages/design_system/lib/src/theme/src/light_theme.dart)). Follow [DESIGN.md](../../DESIGN.md) — desaturated tonal variants, not pure inversion. Every foreground/background pair must meet WCAG AA (4.5:1 body, 3:1 large/UI) in **both** modes.

### Consequences

- Good: visual consistency by construction; new screens cannot drift from the system.
- Good: dark mode is a property of the token, not the consumer.
- Good: a designer changing a token cascades to every site automatically.
- Bad: prototyping a new color requires editing the DS package first.
- Bad: developers must know the token catalog — adding the wrong token name silently picks a similar-looking but semantically different token.

## Pros and Cons of the Options

### DS tokens only
- Good: enforced consistency; auditable dark mode.
- Bad: friction for prototypes.

### Tokens + escape hatches
- Good: ergonomic for one-offs.
- Bad: "one-off" decays — escape hatches accumulate, dark mode regresses.

### Per-feature mini-themes
- Good: feature autonomy.
- Bad: cross-feature inconsistency; brand drift; designer tooling fragments.

## Links

- [ADR-0014 Melos package split](0014-melos-package-split.md)
- Code: [packages/design_system](../../packages/design_system), [DESIGN.md](../../DESIGN.md)
