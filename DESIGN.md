# Design System Inspired by Vercel

> **Reference doc.** This file is the visual specification: palette, type scale, shadows and components (§1–9), then dark mode, motion, component states, accessibility, the CSS→Flutter token map, and the per-feature design-spec template (§10–15).
>
> The *rule* that app code consumes only DS tokens — never raw colors or styles — is [ADR-0013](docs/adr/0013-design-system-tokens-only.md). The *package boundary* (why `design_system` is its own workspace package) is [ADR-0014](docs/adr/0014-melos-package-split.md). To **add** a token, follow the [`add-design-token`](.claude/skills/add-design-token/SKILL.md) playbook — a colour needs six edits and both a light and a dark value.

## 1. Visual Theme & Atmosphere

Vercel's website is the visual thesis of developer infrastructure made invisible — a design system so restrained it borders on philosophical. The page is overwhelmingly white (`#ffffff`) with near-black (`#171717`) text, creating a gallery-like emptiness where every element earns its pixel. This isn't minimalism as decoration; it's minimalism as engineering principle. The Geist design system treats the interface like a compiler treats code — every unnecessary token is stripped away until only structure remains.

The custom Geist font family is the crown jewel. Geist Sans uses aggressive negative letter-spacing (-2.4px to -2.88px at display sizes), creating headlines that feel compressed, urgent, and engineered — like code that's been minified for production. At body sizes, the tracking relaxes but the geometric precision persists. Geist Mono completes the system as the monospace companion for code, terminal output, and technical labels. Both fonts enable OpenType `"liga"` (ligatures) globally, adding a layer of typographic sophistication that rewards close reading.

What distinguishes Vercel from other monochrome design systems is its shadow-as-border philosophy. Instead of traditional CSS borders, Vercel uses `box-shadow: 0px 0px 0px 1px rgba(0,0,0,0.08)` — a zero-offset, zero-blur, 1px-spread shadow that creates a border-like line without the box model implications. This technique allows borders to exist in the shadow layer, enabling smoother transitions, rounded corners without clipping, and a subtler visual weight than traditional borders. The entire depth system is built on layered, multi-value shadow stacks where each layer serves a specific purpose: one for the border, one for soft elevation, one for ambient depth.

**Key Characteristics:**
- Geist Sans with extreme negative letter-spacing (-2.4px to -2.88px at display) — text as compressed infrastructure
- Geist Mono for code and technical labels with OpenType `"liga"` globally
- Shadow-as-border technique: `box-shadow 0px 0px 0px 1px` replaces traditional borders throughout
- Multi-layer shadow stacks for nuanced depth (border + elevation + ambient in single declarations)
- Near-pure white canvas with `#171717` text — not quite black, creating micro-contrast softness
- Workflow-specific accent colors: Ship Red (`#ff5b4f`), Preview Pink (`#de1d8d`), Develop Blue (`#0a72ef`)
- Focus ring system using `hsla(212, 100%, 48%, 1)` — a saturated blue for accessibility
- Pill badges (9999px) with tinted backgrounds for status indicators

## 2. Color Palette & Roles

### Primary
- **Vercel Black** (`#171717`): Primary text, headings, dark surface backgrounds. Not pure black — the slight warmth prevents harshness.
- **Pure White** (`#ffffff`): Page background, card surfaces, button text on dark.
- **True Black** (`#000000`): Secondary use, `--geist-console-text-color-default`, used in specific console/code contexts.

### Workflow Accent Colors
- **Ship Red** (`#ff5b4f`): `--ship-text`, the "ship to production" workflow step — warm, urgent coral-red.
- **Preview Pink** (`#de1d8d`): `--preview-text`, the preview deployment workflow — vivid magenta-pink.
- **Develop Blue** (`#0a72ef`): `--develop-text`, the development workflow — bright, focused blue.

### Console / Code Colors
- **Console Blue** (`#0070f3`): `--geist-console-text-color-blue`, syntax highlighting blue.
- **Console Purple** (`#7928ca`): `--geist-console-text-color-purple`, syntax highlighting purple.
- **Console Pink** (`#eb367f`): `--geist-console-text-color-pink`, syntax highlighting pink.

### Interactive
- **Link Blue** (`#0072f5`): Primary link color with underline decoration.
- **Focus Blue** (`hsla(212, 100%, 48%, 1)`): `--ds-focus-color`, focus ring on interactive elements.
- **Ring Blue** (`rgba(147, 197, 253, 0.5)`): `--tw-ring-color`, Tailwind ring utility.

### Neutral Scale
- **Gray 900** (`#171717`): Primary text, headings, nav text.
- **Gray 600** (`#4d4d4d`): Secondary text, description copy.
- **Gray 500** (`#666666`): Tertiary text, muted links.
- **Gray 400** (`#808080`): Placeholder text, disabled states.
- **Gray 100** (`#ebebeb`): Borders, card outlines, dividers.
- **Gray 50** (`#fafafa`): Subtle surface tint, inner shadow highlight.

### Surface & Overlay
- **Overlay Backdrop** (`hsla(0, 0%, 98%, 1)`): `--ds-overlay-backdrop-color`, modal/dialog backdrop.
- **Selection Text** (`hsla(0, 0%, 95%, 1)`): `--geist-selection-text-color`, text selection highlight.
- **Badge Blue Bg** (`#ebf5ff`): Pill badge background, tinted blue surface.
- **Badge Blue Text** (`#0068d6`): Pill badge text, darker blue for readability.

### Shadows & Depth
- **Border Shadow** (`rgba(0, 0, 0, 0.08) 0px 0px 0px 1px`): The signature — replaces traditional borders.
- **Subtle Elevation** (`rgba(0, 0, 0, 0.04) 0px 2px 2px`): Minimal lift for cards.
- **Card Stack** (`rgba(0,0,0,0.08) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 2px, rgba(0,0,0,0.04) 0px 8px 8px -8px, #fafafa 0px 0px 0px 1px`): Full multi-layer card shadow.
- **Ring Border** (`rgb(235, 235, 235) 0px 0px 0px 1px`): Light gray ring-border for tabs and images.

## 3. Typography Rules

### Font Family
- **Primary**: `Geist`, with fallbacks: `Arial, Apple Color Emoji, Segoe UI Emoji, Segoe UI Symbol`
- **Monospace**: `Geist Mono`, with fallbacks: `ui-monospace, SFMono-Regular, Roboto Mono, Menlo, Monaco, Liberation Mono, DejaVu Sans Mono, Courier New`
- **OpenType Features**: `"liga"` enabled globally on all Geist text; `"tnum"` for tabular numbers on specific captions.

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display Hero | Geist | 48px (3.00rem) | 600 | 1.00–1.17 (tight) | -2.4px to -2.88px | Maximum compression, billboard impact |
| Section Heading | Geist | 40px (2.50rem) | 600 | 1.20 (tight) | -2.4px | Feature section titles |
| Sub-heading Large | Geist | 32px (2.00rem) | 600 | 1.25 (tight) | -1.28px | Card headings, sub-sections |
| Sub-heading | Geist | 32px (2.00rem) | 400 | 1.50 | -1.28px | Lighter sub-headings |
| Card Title | Geist | 24px (1.50rem) | 600 | 1.33 | -0.96px | Feature cards |
| Card Title Light | Geist | 24px (1.50rem) | 500 | 1.33 | -0.96px | Secondary card headings |
| Body Large | Geist | 20px (1.25rem) | 400 | 1.80 (relaxed) | normal | Introductions, feature descriptions |
| Body | Geist | 18px (1.13rem) | 400 | 1.56 | normal | Standard reading text |
| Body Small | Geist | 16px (1.00rem) | 400 | 1.50 | normal | Standard UI text |
| Body Medium | Geist | 16px (1.00rem) | 500 | 1.50 | normal | Navigation, emphasized text |
| Body Semibold | Geist | 16px (1.00rem) | 600 | 1.50 | -0.32px | Strong labels, active states |
| Button / Link | Geist | 14px (0.88rem) | 500 | 1.43 | normal | Buttons, links, captions |
| Button Small | Geist | 14px (0.88rem) | 400 | 1.00 (tight) | normal | Compact buttons |
| Caption | Geist | 12px (0.75rem) | 400–500 | 1.33 | normal | Metadata, tags |
| Mono Body | Geist Mono | 16px (1.00rem) | 400 | 1.50 | normal | Code blocks |
| Mono Caption | Geist Mono | 13px (0.81rem) | 500 | 1.54 | normal | Code labels |
| Mono Small | Geist Mono | 12px (0.75rem) | 500 | 1.00 (tight) | normal | `text-transform: uppercase`, technical labels |
| Micro Badge | Geist | 7px (0.44rem) | 700 | 1.00 (tight) | normal | `text-transform: uppercase`, tiny badges |

### Principles
- **Compression as identity**: Geist Sans at display sizes uses -2.4px to -2.88px letter-spacing — the most aggressive negative tracking of any major design system. This creates text that feels _minified_, like code optimized for production. The tracking progressively relaxes as size decreases: -1.28px at 32px, -0.96px at 24px, -0.32px at 16px, and normal at 14px.
- **Ligatures everywhere**: Every Geist text element enables OpenType `"liga"`. Ligatures aren't decorative — they're structural, creating tighter, more efficient glyph combinations.
- **Three weights, strict roles**: 400 (body/reading), 500 (UI/interactive), 600 (headings/emphasis). No bold (700) except for tiny micro-badges. This narrow weight range creates hierarchy through size and tracking, not weight.
- **Mono for identity**: Geist Mono in uppercase with `"tnum"` or `"liga"` serves as the "developer console" voice — compact technical labels that connect the marketing site to the product.

## 4. Component Stylings

### Buttons

**Primary White (Shadow-bordered)**
- Background: `#ffffff`
- Text: `#171717`
- Padding: 0px 6px (minimal — content-driven width)
- Radius: 6px (subtly rounded)
- Shadow: `rgb(235, 235, 235) 0px 0px 0px 1px` (ring-border)
- Hover: background shifts to `var(--ds-gray-1000)` (dark)
- Focus: `2px solid var(--ds-focus-color)` outline + `var(--ds-focus-ring)` shadow
- Use: Standard secondary button

**Primary Dark (Inferred from Geist system)**
- Background: `#171717`
- Text: `#ffffff`
- Padding: 8px 16px
- Radius: 6px
- Use: Primary CTA ("Start Deploying", "Get Started")

**Pill Button / Badge**
- Background: `#ebf5ff` (tinted blue)
- Text: `#0068d6`
- Padding: 0px 10px
- Radius: 9999px (full pill)
- Font: 12px weight 500
- Use: Status badges, tags, feature labels

**Large Pill (Navigation)**
- Background: transparent or `#171717`
- Radius: 64px–100px
- Use: Tab navigation, section selectors

### Cards & Containers
- Background: `#ffffff`
- Border: via shadow — `rgba(0, 0, 0, 0.08) 0px 0px 0px 1px`
- Radius: 8px (standard), 12px (featured/image cards)
- Shadow stack: `rgba(0,0,0,0.08) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 2px, #fafafa 0px 0px 0px 1px`
- Image cards: `1px solid #ebebeb` with 12px top radius
- Hover: subtle shadow intensification

### Inputs & Forms
- Radio: standard styling with focus `var(--ds-gray-200)` background
- Focus shadow: `1px 0 0 0 var(--ds-gray-alpha-600)`
- Focus outline: `2px solid var(--ds-focus-color)` — consistent blue focus ring
- Border: via shadow technique, not traditional border

### Navigation
- Clean horizontal nav on white, sticky
- Vercel logotype left-aligned, 262x52px
- Links: Geist 14px weight 500, `#171717` text
- Active: weight 600 or underline
- CTA: dark pill buttons ("Start Deploying", "Contact Sales")
- Mobile: hamburger menu collapse
- Product dropdowns with multi-level menus

### Image Treatment
- Product screenshots with `1px solid #ebebeb` border
- Top-rounded images: `12px 12px 0px 0px` radius
- Dashboard/code preview screenshots dominate feature sections
- Soft gradient backgrounds behind hero images (pastel multi-color)

### Distinctive Components

**Workflow Pipeline**
- Three-step horizontal pipeline: Develop → Preview → Ship
- Each step has its own accent color: Blue → Pink → Red
- Connected with lines/arrows
- The visual metaphor for Vercel's core value proposition

**Trust Bar / Logo Grid**
- Company logos (Perplexity, ChatGPT, Cursor, etc.) in grayscale
- Horizontal scroll or grid layout
- Subtle `#ebebeb` border separation

**Metric Cards**
- Large number display (e.g., "10x faster")
- Geist 48px weight 600 for the metric
- Description below in gray body text
- Shadow-bordered card container

## 5. Layout Principles

### Spacing System
- Base unit: 8px
- Scale: 1px, 2px, 3px, 4px, 5px, 6px, 8px, 10px, 12px, 14px, 16px, 32px, 36px, 40px
- Notable gap: jumps from 16px to 32px — no 20px or 24px in primary scale

### Grid & Container
- Max content width: approximately 1200px
- Hero: centered single-column with generous top padding
- Feature sections: 2–3 column grids for cards
- Full-width dividers using `border-bottom: 1px solid #171717`
- Code/dashboard screenshots as full-width or contained with border

### Whitespace Philosophy
- **Gallery emptiness**: Massive vertical padding between sections (80px–120px+). The white space IS the design — it communicates that Vercel has nothing to prove and nothing to hide.
- **Compressed text, expanded space**: The aggressive negative letter-spacing on headlines is counterbalanced by generous surrounding whitespace. The text is dense; the space around it is vast.
- **Section rhythm**: White sections alternate with white sections — there's no color variation between sections. Separation comes from borders (shadow-borders) and spacing alone.

### Border Radius Scale
- Micro (2px): Inline code snippets, small spans
- Subtle (4px): Small containers
- Standard (6px): Buttons, links, functional elements
- Comfortable (8px): Cards, list items
- Image (12px): Featured cards, image containers (top-rounded)
- Large (64px): Tab navigation pills
- XL (100px): Large navigation links
- Full Pill (9999px): Badges, status pills, tags
- Circle (50%): Menu toggle, avatar containers

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat (Level 0) | No shadow | Page background, text blocks |
| Ring (Level 1) | `rgba(0,0,0,0.08) 0px 0px 0px 1px` | Shadow-as-border for most elements |
| Light Ring (Level 1b) | `rgb(235,235,235) 0px 0px 0px 1px` | Lighter ring for tabs, images |
| Subtle Card (Level 2) | Ring + `rgba(0,0,0,0.04) 0px 2px 2px` | Standard cards with minimal lift |
| Full Card (Level 3) | Ring + Subtle + `rgba(0,0,0,0.04) 0px 8px 8px -8px` + inner `#fafafa` ring | Featured cards, highlighted panels |
| Focus (Accessibility) | `2px solid hsla(212, 100%, 48%, 1)` outline | Keyboard focus on all interactive elements |

**Shadow Philosophy**: Vercel has arguably the most sophisticated shadow system in modern web design. Rather than using shadows for elevation in the traditional Material Design sense, Vercel uses multi-value shadow stacks where each layer has a distinct architectural purpose: one creates the "border" (0px spread, 1px), another adds ambient softness (2px blur), another handles depth at distance (8px blur with negative spread), and an inner ring (`#fafafa`) creates the subtle highlight that makes the card "glow" from within. This layered approach means cards feel built, not floating.

### Decorative Depth
- Hero gradient: soft, pastel multi-color gradient wash behind hero content (barely visible, atmospheric)
- Section borders: `1px solid #171717` (full dark line) between major sections
- No background color variation — depth comes entirely from shadow layering and border contrast

## 7. Do's and Don'ts

### Do
- Use Geist Sans with aggressive negative letter-spacing at display sizes (-2.4px to -2.88px at 48px)
- Use shadow-as-border (`0px 0px 0px 1px rgba(0,0,0,0.08)`) instead of traditional CSS borders
- Enable `"liga"` on all Geist text — ligatures are structural, not optional
- Use the three-weight system: 400 (body), 500 (UI), 600 (headings)
- Apply workflow accent colors (Red/Pink/Blue) only in their workflow context
- Use multi-layer shadow stacks for cards (border + elevation + ambient + inner highlight)
- Keep the color palette achromatic — grays from `#171717` to `#ffffff` are the system
- Use `#171717` instead of `#000000` for primary text — the micro-warmth matters

### Don't
- Don't use positive letter-spacing on Geist Sans — it's always negative or zero
- Don't use weight 700 (bold) on body text — 600 is the maximum, used only for headings
- Don't use traditional CSS `border` on cards — use the shadow-border technique
- Don't introduce warm colors (oranges, yellows, greens) into the UI chrome
- Don't apply the workflow accent colors (Ship Red, Preview Pink, Develop Blue) decoratively
- Don't use heavy shadows (> 0.1 opacity) — the shadow system is whisper-level
- Don't increase body text letter-spacing — Geist is designed to run tight
- Don't use pill radius (9999px) on primary action buttons — pills are for badges/tags only
- Don't skip the inner `#fafafa` ring in card shadows — it's the glow that makes the system work

## 8. Responsive Behavior

### Breakpoints
| Name | Width | Key Changes |
|------|-------|-------------|
| Mobile Small | <400px | Tight single column, minimal padding |
| Mobile | 400–600px | Standard mobile, stacked layout |
| Tablet Small | 600–768px | 2-column grids begin |
| Tablet | 768–1024px | Full card grids, expanded padding |
| Desktop Small | 1024–1200px | Standard desktop layout |
| Desktop | 1200–1400px | Full layout, maximum content width |
| Large Desktop | >1400px | Centered, generous margins |

### Touch Targets
- Buttons use comfortable padding (8px–16px vertical)
- Navigation links at 14px with adequate spacing
- Pill badges have 10px horizontal padding for tap targets
- Mobile menu toggle uses 50% radius circular button

### Collapsing Strategy
- Hero: display 48px → scales down, maintains negative tracking proportionally
- Navigation: horizontal links + CTAs → hamburger menu
- Feature cards: 3-column → 2-column → single column stacked
- Code screenshots: maintain aspect ratio, may horizontally scroll
- Trust bar logos: grid → horizontal scroll
- Footer: multi-column → stacked single column
- Section spacing: 80px+ → 48px on mobile

### Image Behavior
- Dashboard screenshots maintain border treatment at all sizes
- Hero gradient softens/simplifies on mobile
- Product screenshots use responsive images with consistent border radius
- Full-width sections maintain edge-to-edge treatment

## 9. Agent Prompt Guide

### Quick Color Reference
- Primary CTA: Vercel Black (`#171717`)
- Background: Pure White (`#ffffff`)
- Heading text: Vercel Black (`#171717`)
- Body text: Gray 600 (`#4d4d4d`)
- Border (shadow): `rgba(0, 0, 0, 0.08) 0px 0px 0px 1px`
- Link: Link Blue (`#0072f5`)
- Focus ring: Focus Blue (`hsla(212, 100%, 48%, 1)`)

### Example Component Prompts
- "Create a hero section on white background. Headline at 48px Geist weight 600, line-height 1.00, letter-spacing -2.4px, color #171717. Subtitle at 20px Geist weight 400, line-height 1.80, color #4d4d4d. Dark CTA button (#171717, 6px radius, 8px 16px padding) and ghost button (white, shadow-border rgba(0,0,0,0.08) 0px 0px 0px 1px, 6px radius)."
- "Design a card: white background, no CSS border. Use shadow stack: rgba(0,0,0,0.08) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 2px, #fafafa 0px 0px 0px 1px. Radius 8px. Title at 24px Geist weight 600, letter-spacing -0.96px. Body at 16px weight 400, #4d4d4d."
- "Build a pill badge: #ebf5ff background, #0068d6 text, 9999px radius, 0px 10px padding, 12px Geist weight 500."
- "Create navigation: white sticky header. Geist 14px weight 500 for links, #171717 text. Dark pill CTA 'Start Deploying' right-aligned. Shadow-border on bottom: rgba(0,0,0,0.08) 0px 0px 0px 1px."
- "Design a workflow section showing three steps: Develop (text color #0a72ef), Preview (#de1d8d), Ship (#ff5b4f). Each step: 14px Geist Mono uppercase label + 24px Geist weight 600 title + 16px weight 400 description in #4d4d4d."

### Iteration Guide
1. Always use shadow-as-border instead of CSS border — `0px 0px 0px 1px rgba(0,0,0,0.08)` is the foundation
2. Letter-spacing scales with font size: -2.4px at 48px, -1.28px at 32px, -0.96px at 24px, normal at 14px
3. Three weights only: 400 (read), 500 (interact), 600 (announce)
4. Color is functional, never decorative — workflow colors (Red/Pink/Blue) mark pipeline stages only
5. The inner `#fafafa` ring in card shadows is what gives Vercel cards their subtle inner glow
6. Geist Mono uppercase for technical labels, Geist Sans for everything else

---

## 10. Dark Mode

Dark is **not** an inversion. Pure white on pure black halates on OLED and destroys the shadow-as-border effect — the whole depth system is built on a dark hairline over a light ground, which has to be re-thought as a light hairline over a dark ground, not merely negated.

The rules:

- **Surface is `#0A0A0A`, not `#000000`.** True black removes the difference between the page and an unelevated card, and makes every shadow invisible.
- **Ink is `#EDEDED`, not `#FFFFFF`.** Full-white body text on near-black is the single biggest cause of perceived eye strain.
- **Hairlines flip from alpha-on-black to alpha-on-white** — `rgba(0,0,0,0.08)` becomes `rgba(255,255,255,0.10)`. The slightly higher alpha compensates for the lower perceptual contrast of a light line on a dark ground.
- **Shadows get stronger, not weaker** — `0x0A000000` → `0x33000000`. On a dark surface a whisper-level shadow is simply not there.
- **Accents desaturate and lighten.** `danger` moves `#DC2626` → `#FF6B6B`; `focusBlue` `#0A72EF` → `#47A3FF`. A saturated hue tuned for a white ground reads as neon on a dark one.
- **Badge surfaces become deep tonal grounds**, not tinted whites: `#EBF5FF` → `#0D2A4A` with the foreground lightened to `#8FC4FF`.

### Token pairs

| Token | Light | Dark | Role |
|---|---|---|---|
| `surface` | `#FFFFFF` | `#0A0A0A` | page / card background |
| `ink` | `#171717` | `#EDEDED` | primary text, primary CTA background |
| `muted` | `#4D4D4D` | `#A1A1A1` | secondary text |
| `subtle` | `#666666` | `#8F8F8F` | tertiary / helper text |
| `placeholder` | `#808080` | `#6E6E6E` | hint text, disabled |
| `hairline` | `rgba(0,0,0,.08)` | `rgba(255,255,255,.10)` | shadow-as-border stroke |
| `ringSoft` | `#EBEBEB` | `#262626` | lighter ring — tabs, images |
| `innerGlow` | `#FAFAFA` | `#141414` | inner highlight in the card stack |
| `focusBlue` | `#0A72EF` | `#47A3FF` | focus ring |
| `focusHaloAlpha` | `0.12` | `0.22` | focus halo opacity |
| `danger` | `#DC2626` | `#FF6B6B` | destructive / error |
| `warn` | `#B25B00` | `#FFB668` | warning |
| `badgeInfoBg` / `Fg` | `#EBF5FF` / `#0068D6` | `#0D2A4A` / `#8FC4FF` | info pill |
| `badgeSuccessBg` / `Fg` | `#E6F6EC` / `#1A7F37` | `#0F2E1B` / `#7FD69A` | success pill |
| `elevation` | `0x0A000000` | `0x33000000` | soft card lift |
| `ambient` | `0x0A000000` | `0x4D000000` | diffuse depth |
| `fabShadow` | `0x33000000` | `0x66000000` | floating action shadow |
| `skeletonBase` / `Highlight` | `#F5F5F5` / `#EDEDED` | `#1A1A1A` / `#242424` | loading shimmer |

**Every new token is added as a pair.** A light value without a dark one is an incomplete token — see the six edit points in the [`add-design-token`](.claude/skills/add-design-token/SKILL.md) playbook.

## 11. Motion

Motion in this system is **feedback, not decoration**. Every animation answers one of three questions: *did my touch register*, *where did this come from*, or *what changed*. Anything that answers none of those is removed.

### Duration tokens

| Token | Value | Use |
|---|---|---|
| `GeistDuration.fast` | 120 ms | press feedback, opacity swaps, colour changes |
| `GeistDuration.base` | 200 ms | slide-ins, sheet transitions, FAB show/hide |
| `GeistDuration.slow` | 320 ms | full-screen transitions, large layout changes |
| `GeistDuration.breathe` | 2400 ms | ambient loops — skeleton shimmer, pulse |

Never write a raw `Duration` in `lib/`. If a new speed is genuinely needed, it becomes a token.

### Curves

- **`Curves.easeOut`** — the default for anything entering or responding to touch. Fast start, settled finish; matches the physical expectation that a thing you pushed decelerates.
- **`Curves.easeOutCubic`** — position changes over larger distances (slide-ins, FAB dismissal).
- **Never `easeInOut` on entry.** The slow start reads as lag.
- **Never a bounce or elastic curve.** This system is engineered, not playful.

### Primitives

They live in `lib/core/ui/geist_motion.dart` and already honour reduced motion:

| Primitive | Does |
|---|---|
| `PressScale` | scale to 0.97 on pointer down, `fast`, interruptible, optional selection haptic |
| `FadeSlideIn` | fade + 6% upward slide on mount, staggerable with `delay` |
| `AnimatedCount` | tweens an integer with tabular figures so the layout does not jitter |

### Rules

- **Interruptible.** A user who taps mid-animation must not wait for it to finish. Use `AnimatedFoo` widgets and implicit animations rather than driving a controller to completion.
- **Stagger sparingly.** 40 ms between siblings, four items maximum. Beyond that the screen feels slow to arrive.
- **Respect `MediaQuery.disableAnimationsOf(context)`** — `geistReducedMotion(context)`. Reduced motion means *instant final state*, never a slower animation.
- **Haptics are punctuation.** `selectionClick` for a filter or toggle, `lightImpact` for a submit, `mediumImpact` for a primary destructive or creative action. Never on scroll, never on every frame.
- **Nothing loops in the user's peripheral vision** except the skeleton shimmer, and that stops the moment data arrives.

## 12. Component States

Every interactive component defines all six. A component with only default and pressed is unfinished.

| State | Treatment |
|---|---|
| **Default** | as specified in §4 |
| **Pressed** | `PressScale` 0.97 over `fast`; no colour change on top of the scale |
| **Hover** (pointer devices) | background steps one level toward `ink`; no size change |
| **Focus** | 2 px `focusBlue` outline + halo at `focusHaloAlpha`. Never removed, never replaced by colour alone |
| **Disabled** | foreground → `placeholder`, background → `surface`, shadow reduced to `ringShadow`, cursor/pointer inert. Never below 3:1 against its background — a disabled control must still be readable |
| **Loading** | in-place spinner or skeleton, control stays the same size, action is inert. Never a layout jump |

### Screen-level states

Every screen that reads remote data implements **four** branches, and each carries a `Key` so an E2E flow can assert it ([ADR-0015](docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)):

| Branch | Treatment |
|---|---|
| **Loading** | `skeletonizer` over the real layout, shimmering `skeletonBase` → `skeletonHighlight`. Never a bare centred spinner on first load — it tells the user nothing about what is coming |
| **Empty** | icon in a `ringSoft` container, `subheading` title in `ink`, one-line `bodyM` explanation in `muted`, and the primary action still reachable. Distinct from both loading and error |
| **Error** | `cloud_off` glyph in `placeholder`, `sectionTitle` message in `ink`, and a **retry that actually re-runs the request**. Never a dead-end |
| **Content** | the real thing |

A filtered-empty state ("no active tasks") is a **different surface** from a no-data empty state ("no todos yet"). Do not reuse one for the other — the user's next action is different.

## 13. Accessibility

Non-negotiable, and checked in the QA gate.

- **Contrast: WCAG AA in both themes.** 4.5:1 for body text, 3:1 for large text (≥ 18.66 px at 400, or ≥ 14 px at 600) and for UI glyphs and borders that carry meaning. A token that passes in light and fails in dark is a bug, not a style choice.
- **Touch targets ≥ 44 × 44 pt**, even when the visual is smaller. Expand the hit area with padding, not the glyph.
- **Every interactive widget carries a `Semantics` label** sourced from `LocaleKeys` — never a hardcoded English string, never the icon name.
- **Text scales to 200%** without clipping or overlap. The aggressive negative tracking makes this harder than usual: verify at scale, do not assume.
- **Colour is never the only signal.** The workflow accents (Ship Red, Preview Pink, Develop Blue) always pair with a label or an icon.
- **Focus is always visible.** The 2 px `focusBlue` outline is part of the component, not an optional polish pass.
- **Reduced motion is honoured** through `geistReducedMotion(context)` — the final state appears immediately.
- **Reading order matches visual order.** Check with VoiceOver, not by inspection.

## 14. CSS → Flutter Token Map

This document is written in web terms because it describes the Geist source system. In this repo the tokens are Dart. The mapping:

| Spec concept | Flutter token |
|---|---|
| `background: #fff` | `context.geist.surface` |
| `color: #171717` | `context.geist.ink` |
| `color: #4d4d4d` | `context.geist.muted` |
| `box-shadow: 0 0 0 1px rgba(0,0,0,.08)` | `context.geist.shadowBorder` / `ringShadow` |
| the full card stack | `context.geist.cardShadow` |
| `outline: 2px solid var(--ds-focus-color)` | `context.geist.focusBlue` + `focusHaloAlpha` |
| `border-radius: 6px` | `GeistRadius.standard` |
| `border-radius: 8px` | `GeistRadius.comfortable` |
| `border-radius: 12px` | `GeistRadius.image` |
| `border-radius: 9999px` | `GeistRadius.pill` |
| any type role in §3 | `GeistTextStyles.<role>` |
| `padding: 16px` | `kSpacing16px` |
| `transition: 120ms` | `GeistDuration.fast` |

**Font — known gap.** `packages/design_system/pubspec.yaml` bundles **Lexend** and **Inter**, but neither `lightTheme` nor `darkTheme` sets a `fontFamily`, so the app currently renders in the platform default (SF Pro on iOS). `GeistTextStyles` sets `fontFamily: 'monospace'` on the mono roles only. Geist Sans is not bundled at all. The type *rules* in §3 — three weights, negative tracking that scales with size, ligatures on — apply regardless of which family is finally wired; picking one and setting it on both themes is outstanding work, not a decision this document has made.

Sizes in this document are CSS pixels; Flutter logical pixels are the same number.

## 15. Feature Design Spec

Before building a feature's UI, write this. It is short on purpose — it exists so the states and edges are *decided* rather than discovered during QA. Attach it to the ticket, or drop it in the plan produced by [`plan-feature`](.claude/skills/plan-feature/SKILL.md).

```markdown
## Design spec — {feature}

### Screens
| Screen | Route | Entry points |
|---|---|---|

### Per screen
**{Screen name}**
- Purpose (one line, from the user's side):
- Layout: sections top to bottom, with the spacing token between each
- Primary action:  Secondary actions:
- Tokens used: colours / text roles / radii that already exist
- New tokens needed: (each with a light AND dark value — see add-design-token)

### The four branches
| Branch | What the user sees | Next action available | Key |
|---|---|---|---|
| Loading | | | |
| Empty | | | |
| Error | | | |
| Content | | | |

### Motion
- Entry:            (primitive + duration token)
- Press feedback:   (PressScale? haptic level?)
- Transitions:      (which duration token)

### Copy
Every string as a LocaleKey, with the English value. Include error and empty copy.

### Accessibility
- Semantics labels for each interactive element (as LocaleKeys)
- Any target smaller than 44pt and how its hit area is expanded
- Contrast pairs that need checking in dark mode

### Edge cases the design must answer
- Longest realistic content:
- Zero / one / many:
- Offline:
- In-flight action interrupted:
```
