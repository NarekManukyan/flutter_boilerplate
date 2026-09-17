---
name: add-design-token
description: Add or change a design-system token — GeistTheme colour, GeistTextStyles text style, GeistRadius, GeistDuration, spacing constant or shadow stack. Covers the static vs theme-aware decision, the six edit points a new colour needs, light+dark pairing, WCAG contrast, Gap spacing, design-system codegen, and consuming tokens from lib/. Use whenever a colour, text style, radius, duration, spacing value or shadow is needed and no token exists.
---

# Add a design token

Governed by [ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md). Visual spec: [`DESIGN.md`](../../../DESIGN.md).

**`lib/` contains no raw visual values.** No `Color(0x…)`, no `TextStyle(…)` composite, no `BorderRadius.circular(12)`, no `Duration(milliseconds: 200)`, no hand-assembled `BoxShadow` list. If the token does not exist, add it here — do not inline it "just this once".

The only bare colours allowed in `lib/` are `Colors.transparent` and a `Color.lerp` between two tokens.

## Static or theme-aware? Decide first

Ask one question: **does this need a different value in dark mode?**

| Answer | Kind | Where it goes | Read as |
|---|---|---|---|
| Yes | **theme-aware** | a field on the `GeistTheme` `ThemeExtension`, with a light **and** a dark value | `context.geist.token` |
| No | **static** | a `const` in `GeistRadius`, `GeistDuration`, `GeistTextStyles` or the spacing constants | `GeistRadius.comfortable`, `kSpacing16px` |

Colours almost always answer yes — shadow colours included — and so do non-colour values that change with the theme, such as `focusHaloAlpha`. Spacing, radii, durations and text-style metrics (size, weight, height, tracking) answer no.

A value that differs between light and dark is **never** a constant: a constant cannot change with the theme, so dark mode silently renders the light value. That is also why `GeistTextStyles` carries no colour — the metrics are static, and the colour is applied from `context.geist` at the use site.

**For a theme-aware token the dark value is never optional.** A token missing from one theme does not fail to compile, it fails at runtime: `context.geist` falls back to `GeistTheme.light` when the extension is missing, so dark mode quietly shows light colours, and the legacy `context.customTheme` getter throws. `GeistTheme`'s constructor makes every field `required`, so fill in `dark` properly, not with a copy of the light value.

## Where each kind of token lives

| Token | Kind | File | Consumed as |
|---|---|---|---|
| Colour / shadow layer | theme-aware | `GeistTheme` in `packages/design_system/lib/src/theme/src/geist_theme.dart` | `context.geist.tokenName` |
| Text style | static | `GeistTextStyles` (same file) | `GeistTextStyles.role` |
| Radius | static | `GeistRadius` (same file) | `GeistRadius.comfortable` |
| Duration | static | `GeistDuration` (same file) | `GeistDuration.base` |
| Spacing | static | `packages/design_system/lib/src/core/src/constants/constants.dart` | `kSpacing16px`, `Gap(kSpacing16px)` |
| Generated brand colour | static | `packages/design_system/assets/colors/colors.xml` → `lib/gen/colors.gen.dart` | `AppColors.name` |
| Legacy Tailor theme | theme-aware | `theme_tailor/custom_theme.dart` | `context.tokenName` |

New work uses the Geist tokens. Only touch the Tailor `CustomTheme` when editing code that already reads from it. A generated `AppColors` value is identical in both themes by construction, so use one only for a colour that really is the same in light and dark (a brand mark); anything that sits on a surface goes through `GeistTheme`.

## Adding a theme-aware colour — six edit points, all required

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

## Spacing

Spacing values are the `kSpacingNpx` constants. Space **between siblings** in a `Row`, `Column` or other flex is `Gap` with the matching constant, never a `SizedBox`:

```dart
Column(
  children: [
    const _Title(),
    const Gap(kSpacing8px),   // not SizedBox(height: 8)
    const _Subtitle(),
  ],
)
```

`Gap` (from `package:gap`) takes its axis from the parent, so the same spacer works in a `Row`. Padding around a widget uses the same constants: `EdgeInsets.all(kSpacing16px)`. A spacing value with no constant is a new constant in `constants.dart`, not a literal.

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

`GeistTheme`, `GeistTextStyles`, `GeistRadius`, `GeistDuration` and the spacing constants are hand-written — no codegen needed.

`packages/design_system/lib/gen/` **is** generated (`flutter_gen`): assets, fonts, and the brand colours in `assets/colors/colors.xml`. After adding or changing a brand colour, an asset or a font, re-run the design-system codegen and never edit `lib/gen/` by hand:

```bash
melos run build:design_system
```

If the change alters a type the app reads, run `melos run build:app` after it, or `melos run build` for everything in order ([ADR-0014](../../../docs/adr/0014-melos-package-split.md)).

Both `lightTheme` and `darkTheme` must register the extension — check `light_theme.dart` and `dark_theme.dart` if a new token is not resolving.

## Checklist

- [ ] Token added to the design system, not inlined in `lib/`
- [ ] Kind decided: different in dark mode → theme-aware `GeistTheme` field; identical → static constant
- [ ] Theme-aware colour: all six edit points — field, constructor, light, dark, `copyWith`, `lerp`
- [ ] Named for its role, not its appearance
- [ ] Light **and** dark values, both meeting WCAG AA against their pairing
- [ ] Text style has no baked-in colour; use-site `copyWith` changes colour only
- [ ] Sibling spacing is `Gap(kSpacingNpx)`, never `SizedBox`
- [ ] Shadows composed in `GeistTheme`, never assembled in `lib/`
- [ ] `melos run build:design_system` run after a brand colour, asset or font change
- [ ] `DESIGN.md` updated if this introduces a new visual concept
