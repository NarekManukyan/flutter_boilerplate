---
name: add-design-token
description: Add or change a design-system token — GeistTheme colour, GeistTextStyles text style, GeistRadius, GeistDuration, spacing constant or shadow stack. Covers the six edit points a new colour needs, light+dark pairing, WCAG contrast, and consuming tokens from lib/. Use whenever a colour, text style, radius, duration or shadow is needed and no token exists.
---

# Add a design token

Governed by [ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md). Visual spec: [`DESIGN.md`](../../../DESIGN.md).

**`lib/` contains no raw visual values.** No `Color(0x…)`, no `TextStyle(…)` composite, no `BorderRadius.circular(12)`, no `Duration(milliseconds: 200)`, no hand-assembled `BoxShadow` list. If the token does not exist, add it here — do not inline it "just this once".

The only bare colours allowed in `lib/` are `Colors.transparent` and a `Color.lerp` between two tokens.

## Where each kind of token lives

| Token | File | Consumed as |
|---|---|---|
| Colour / shadow layer | `GeistTheme` in `packages/design_system/lib/src/theme/src/geist_theme.dart` | `context.geist.tokenName` |
| Text style | `GeistTextStyles` (same file) | `GeistTextStyles.role` |
| Radius | `GeistRadius` (same file) | `GeistRadius.comfortable` |
| Duration | `GeistDuration` (same file) | `GeistDuration.base` |
| Spacing | `packages/design_system/lib/src/core/src/constants/constants.dart` | `kSpacing16px` |
| Legacy Tailor theme | `theme_tailor/custom_theme.dart` | `context.tokenName` |

New work uses the Geist tokens. Only touch the Tailor `CustomTheme` when editing code that already reads from it.

## Adding a colour — six edit points, all required

`GeistTheme` is a hand-written `ThemeExtension`. Missing one of these compiles but breaks at runtime or during a theme animation.

1. **Field** — `final Color myToken; // what it is for`
2. **Constructor** — `required this.myToken,`
3. **`static const GeistTheme light`** — the light value
4. **`static const GeistTheme dark`** — the dark value (**never optional**)
5. **`copyWith`** — parameter `Color? myToken,` and `myToken: myToken ?? this.myToken,`
6. **`lerp`** — `myToken: Color.lerp(myToken, other.myToken, t)!,`

Non-`Color` fields lerp with the local `_lerpD` helper, not `Color.lerp`.

Name the token for its **role**, not its appearance: `danger`, `hairline`, `skeletonBase`, `placeholder` — not `red`, `grey12`, `lightGrey`.

## Dark is not an inversion

Follow the dark-mode guidance in `DESIGN.md`: desaturated tonal variants, surface `#0A0A0A` rather than pure black, ink `#EDEDED` rather than pure white, and alpha-on-white for hairlines. Pure inversion produces halation on OLED and destroys the shadow-as-border effect.

Every foreground/background pair must meet **WCAG AA in both modes** — 4.5:1 for body text, 3:1 for large text and UI glyphs. Check the pair before committing; a token that passes in light and fails in dark is a bug, not a style preference.

## Text styles

Add to `GeistTextStyles` with the Geist rules: weights 400 / 500 / 600 only, negative tracking that scales with size (-2.4 at 48px, -1.28 at 32px, -0.96 at 24px, -0.32 at 16px, normal at 14px), `"liga"` on.

Styles carry **no colour**. Colour is applied at the use site:

```dart
Text(
  LocaleKeys.homePage_title.tr(),
  style: GeistTextStyles.cardTitle.copyWith(color: context.geist.ink),
)
```

`.copyWith` at a use site is for **colour only**. Changing size, weight or tracking there means the role is missing — add it to `GeistTextStyles`.

## Shadows

`GeistTheme` exposes composed stacks (`cardShadow`, `ringShadow`, `shadowBorder`, `shadowFab`). Use those. Never assemble a `BoxShadow` list in `lib/` — if a new elevation is needed, compose it as a getter on `GeistTheme` from the existing layer colours (`hairline`, `elevation`, `ambient`, `innerGlow`).

## Consuming from `lib/`

```dart
final g = context.geist;

Container(
  padding: const EdgeInsets.all(kSpacing16px),
  decoration: BoxDecoration(
    color: g.surface,
    borderRadius: BorderRadius.circular(GeistRadius.comfortable),
    boxShadow: g.cardShadow,
  ),
  child: Text(
    LocaleKeys.homePage_emptyTitle.tr(),
    style: GeistTextStyles.bodyS.copyWith(color: g.muted),
  ),
)
```

Read `context.geist` **once** at the top of `build`, not repeatedly inside the tree.

## After editing

`GeistTheme` is hand-written — no codegen needed. `packages/design_system/lib/gen/` (assets, colours, fonts) **is** generated: after adding an asset or font, run `melos exec --scope design_system -- "dart run build_runner build -d"` and never edit `lib/gen/`.

Both `lightTheme` and `darkTheme` must register the extension — check `light_theme.dart` and `dark_theme.dart` if a new token is not resolving.

## Checklist

- [ ] Token added to the design system, not inlined in `lib/`
- [ ] Colour: all six edit points — field, constructor, light, dark, `copyWith`, `lerp`
- [ ] Named for its role, not its appearance
- [ ] Light **and** dark values, both meeting WCAG AA against their pairing
- [ ] Text style has no baked-in colour; use-site `copyWith` changes colour only
- [ ] Shadows composed in `GeistTheme`, never assembled in `lib/`
- [ ] `DESIGN.md` updated if this introduces a new visual concept
