# Architecture Decision Records

ADRs codify the **why** behind architectural rules in this repo. CLAUDE.md and `.cursor/rules/*.mdc` carry the day-to-day conventions and how-to material; this directory is the source of truth for decisions that had real alternatives.

Format: [MADR 3.0](https://adr.github.io/madr/). Status `Accepted` means the rule describes how the codebase already works.

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-layered-architecture.md) | Layered architecture with adjacent-only access | Accepted |
| [0002](0002-state-vs-store-separation.md) | State vs Store separation | Accepted |
| [0003](0003-no-use-case-to-use-case-dependencies.md) | Use cases never depend on other use cases | Accepted |
| [0004](0004-use-case-taxonomy-and-colocation.md) | Use case taxonomy and colocation by consumer | Accepted |
| [0005](0005-flat-feature-tree.md) | Flat feature tree (no nested `features/`) | Accepted |
| [0006](0006-feature-owned-singletons.md) | Feature-owned singletons (no `lib/shared/`) | Accepted |
| [0007](0007-di-scopes-and-constructor-injection.md) | DI scopes and constructor injection | Accepted |
| [0008](0008-appnavigator-routing-abstraction.md) | `AppNavigator` routing abstraction | Accepted |
| [0009](0009-provider-based-state-access.md) | Provider-based state access in widgets | Accepted |
| [0010](0010-hookwidget-default.md) | `HookWidget` as the default stateful widget | Accepted |
| [0011](0011-retrofit-typed-api-layer.md) | Retrofit + freezed typed API layer | Accepted |
| [0012](0012-mandatory-localization.md) | Mandatory localization (no hardcoded UI strings) | Accepted |
| [0013](0013-design-system-tokens-only.md) | Design-system tokens only in `lib/` | Accepted |
| [0014](0014-melos-package-split.md) | Melos package split: `api` and `design_system` | Accepted |

## Adding a new ADR

1. Copy `0000-template.md` to `NNNN-kebab-slug.md`.
2. Fill in MADR fields. List at least 2 alternatives with concrete trade-offs.
3. Add a row above.
4. If the decision changes a rule referenced from CLAUDE.md, update the CLAUDE.md "Architectural decisions" section.
