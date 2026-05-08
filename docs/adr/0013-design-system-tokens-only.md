# 13. Design-System Tokens Only in `lib/`

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Once a `Color(0xFF...)` literal slips into a feature widget, it spreads. Each new feature copies the nearest neighbor; visual inconsistency compounds; dark-mode support requires hunting every literal across `lib/`. The same applies to ad-hoc `TextStyle(...)` composites, hand-rolled `BoxShadow` stacks, and arbitrary `Duration` values.

The remedy is a hard rule: every visual token comes from the design-system package — no exceptions in app code.

## Decision Drivers

- Visual consistency — designers control tokens in one place; app code consumes them.
- Dark-mode parity — every token has a light and a dark value, accessed through `ThemeExtension`s.
- WCAG AA compliance — token pairs are auditable; ad-hoc colors are not.

## Considered Options

- **DS tokens only — every color/style/shadow/radius/duration comes from `packages/design_system`**.
- **Tokens + escape hatches — bare hex allowed for "one-off" cases**.
- **Per-feature mini-themes — features define their own colors when needed**.

## Decision Outcome

Chosen option: **DS tokens only**.

The `lib/` layer must not contain raw `Color(0x…)` / hex literals, raw `TextStyle(...)` composites, or one-off shadow stacks. All tokens come from `packages/design_system`:

| Token kind | Access | Add new tokens in |
|---|---|---|
| Colors | `context.geist.<token>` (Geist palette) or legacy `context.<token>` (Tailor `CustomTheme`) | `packages/design_system/lib/src/theme/src/` — both light + dark values |
| Typography | `GeistTextStyles.<role>` or `context.<textStyle>` | `GeistTextStyles` (geist) or `TextStyles` (legacy) |
| Radii | `GeistRadius.<scale>` | DS package |
| Durations | `GeistDuration.<speed>` | DS package |
| Shadows / elevation | `context.geist.cardShadow`, `shadowBorder`, `shadowFab`, etc. | `GeistTheme` extension |
| Spacing | `kSpacingNpx` constants | `design_system` |

### Adding a token

1. Add the field to [`GeistTheme`](../../packages/design_system/lib/src/theme/src/geist_theme.dart) (or the relevant `ThemeExtension`) with both `light` and `dark` values.
2. Update `copyWith` and `lerp`.
3. Consume in `lib/` via `context.geist.newToken` — never inline the hex.

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
