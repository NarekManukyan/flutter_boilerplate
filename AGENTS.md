# AGENTS.md

Instructions for any coding agent working in this repo (Claude Code, Codex, Cursor, Copilot, Gemini, Zed, Amp…). This file is the **single source** — tool-specific files are generated from it, see [ADR-0017](docs/adr/0017-single-source-agent-instructions.md).

Three layers, read in this order:

| Layer | Answers | Where | Loaded |
|---|---|---|---|
| **This file** | *what* the rules are | `AGENTS.md` | always |
| **Playbooks** | *how* to build a thing | `.claude/skills/{name}/SKILL.md` | on demand — open before you build |
| **ADRs** | *why* the rule exists | `docs/adr/` | when you need to argue with a rule |

**Before writing code for a new feature, follow the delivery workflow below. Before building any artifact in the playbook index, open its playbook first.**

## Project Overview

Flutter mobile boilerplate: layered clean architecture, MobX state management, Retrofit API layer (`packages/api`), shared design system (`packages/design_system`), GetIt + Injectable DI. Melos-managed monorepo, Dart workspace.

## Delivery workflow — plan before code

Full rationale: [ADR-0016](docs/adr/0016-plan-first-delivery-workflow.md). Playbook: [`plan-feature`](.claude/skills/plan-feature/SKILL.md). Command: `/build-feature`.

**No code for a new feature until a plan is approved.** Read the ticket in full — *every* acceptance criterion, plus comments and linked issues — restate the AC as verifiable outcomes, analyse the codebase, write a file-level plan mapping each AC line to the test that will prove it, get it approved, build, then exit through the QA gate.

The playbook has the rest, including when to split work across parallel agents (only when it is both large and separable — otherwise do not ask).

## Playbooks — open before you build

| Building… | Playbook | Governed by |
|---|---|---|
| A whole feature module | [`create-feature`](.claude/skills/create-feature/SKILL.md) | ADR-0001, 0005, 0006 |
| A page + its state | [`create-page`](.claude/skills/create-page/SKILL.md) | ADR-0009, 0010 |
| A route, guard, modal or dialog | [`add-route`](.claude/skills/add-route/SKILL.md) | ADR-0008 |
| A MobX store | [`create-store`](.claude/skills/create-store/SKILL.md) | ADR-0002, 0006, 0007 |
| A use case | [`create-use-case`](.claude/skills/create-use-case/SKILL.md) | ADR-0003, 0004 |
| A DTO | [`create-dto`](.claude/skills/create-dto/SKILL.md) | ADR-0011 |
| A Retrofit API provider | [`create-api-provider`](.claude/skills/create-api-provider/SKILL.md) | ADR-0011 |
| A UI string | [`add-localization`](.claude/skills/add-localization/SKILL.md) | ADR-0012 |
| A colour / text style / radius / duration | [`add-design-token`](.claude/skills/add-design-token/SKILL.md) | ADR-0013 |
| A design-system component | [`create-ds-component`](.claude/skills/create-ds-component/SKILL.md) | ADR-0013, 0014 |
| Unit + widget tests | [`write-tests`](.claude/skills/write-tests/SKILL.md) | ADR-0015 |
| A Maestro E2E flow | [`write-maestro-flow`](.claude/skills/write-maestro-flow/SKILL.md) | ADR-0015 |
| The QA pass on a finished feature | [`qa-feature`](.claude/skills/qa-feature/SKILL.md) | ADR-0015 |
| A plan for a Jira ticket | [`plan-feature`](.claude/skills/plan-feature/SKILL.md) | ADR-0016 |
| A new architectural decision | [`create-adr`](.claude/skills/create-adr/SKILL.md) | — |

## Commands

This repo does not commit `ios/` or `android/` — every app generated from it runs `flutter create --platforms=ios,android --org com.yourcompany .` with its own identity first. Everything except building or running on a device works without them, so do not treat their absence as a broken checkout.

```bash
flutter run -t lib/main_dev.dart     # dev flavor
flutter run -t lib/main_prod.dart    # prod flavor

melos run bootstrap                  # deps + codegen, all packages
melos run build                      # codegen after MobX/Retrofit/Freezed/Injectable annotation changes
melos run translations               # after editing assets/translations/en-US.json

melos run analyze                    # dart analyze
melos run lint                       # dart fix --apply
melos run format                     # dart format
melos run test                       # flutter test — unit + widget
melos run test:coverage              # with lcov
melos run maestro                    # Maestro E2E, needs a booted device
melos run sync-agents                # regenerate tool instruction files from this one
melos run verify                     # lint + analyze + format + test — run before every PR
```

Single test file: `flutter test test/path/to_file_test.dart`.
Single Maestro flow: `maestro test .maestro/flows/{feature}/{flow}.yaml`.

## Architecture

Rationale: [ADR-0001](docs/adr/0001-layered-architecture.md).

```
UI → State → Store → DioService → API Provider
          ↘ Use Case ↗
```

| Layer | Files | May access | Must not access |
|---|---|---|---|
| UI | `*_page.dart`, `*_widget.dart` | State via `context.read<T>()` | DioService, Stores |
| State | `*_state.dart` | Stores, `AppNavigator`, Use Cases | DioService |
| Store | `*_store.dart` | DioService, other Stores, Use Cases | — |
| Use Case | `*_use_case.dart` | DioService, Services, `AppNavigator` | **Other Use Cases** |
| Data | `packages/api` providers | — | — |

**State vs Store:** needs API access → Store (`features/*/mobx/`). Does not → State (`features/*/view/`).

## Project Structure

```
lib/
  core/                    configs, constants, extensions, guards, navigation,
                           services (Flavor, Dio, interceptors, social auth),
                           ui (cross-feature widgets), use_cases, utils
  features/{feature}/
    view/                  pages, states, widgets  (+ view/use_cases/)
    mobx/                  stores                  (+ mobx/use_cases/)
    core/use_cases/        use cases shared across layers of this feature
    models/  modals/  components/
  gen/                     GENERATED — never edit
packages/
  api/lib/src/            providers/{resource}_provider/ — one dir per resource,
                          each with its own DTOs and barrel
  design_system/lib/      src/ (theme, components, colors, typography), gen/
assets/translations/       en-US.json …
test/                      unit + widget, mirrors lib/
.maestro/flows/{feature}/  E2E: {feature}_{happy|failure|edge}.yaml
docs/adr/                  architecture decision records
```

- **Features are peers, never nested** — no `features/` inside a feature ([ADR-0005](docs/adr/0005-flat-feature-tree.md)).
- **`lib/shared/` is deprecated** — new stores go under their owning feature's `mobx/` even when `@singleton` ([ADR-0006](docs/adr/0006-feature-owned-singletons.md)).

## Naming

| Type | Pattern | | Type | Pattern |
|---|---|---|---|---|
| Page | `*_page.dart` | | DTO | `*_dto.dart` |
| Page state | `*_page_state.dart` | | Service | `*_service.dart` |
| Store | `*_store.dart` | | API provider | `*_api_provider.dart` |
| Use case | `*_use_case.dart` | | Test ids | `*_keys.dart` |
| Widget | `*_widget.dart` | | Maestro flow | `{feature}_{category}.yaml` |

## File Boundaries

- **Safe to edit:** `lib/`, `packages/*/lib/src/`, `test/`, `.maestro/`, `docs/`
- **Never edit by hand:** `*.g.dart`, `*.gr.dart`, `*.freezed.dart`, `*.gen.dart`, `*.tailor.dart`, `lib/gen/`, `packages/*/lib/gen/`, `injectable.config.dart`
- **Generated from `AGENTS.md`** — edit this file, then `melos run sync-agents`: `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursor/rules/000-agents.mdc`

## Architectural decisions

One line each. Open the ADR when you need the *why* or want to challenge the rule.

- **Layered, adjacent-only access** — UI never reaches Dio or stores directly. [ADR-0001](docs/adr/0001-layered-architecture.md)
- **State vs Store separation** — `*_state.dart` is per-screen with no API access; `*_store.dart` owns API access. [ADR-0002](docs/adr/0002-state-vs-store-separation.md)
- **No use-case → use-case** — shared logic becomes a service, never a peer UC. [ADR-0003](docs/adr/0003-no-use-case-to-use-case-dependencies.md)
- **Use-case taxonomy + colocation** — place next to the consumer; promote on second consumer. [ADR-0004](docs/adr/0004-use-case-taxonomy-and-colocation.md)
- **Flat feature tree** — features are peers under a domain grouping. [ADR-0005](docs/adr/0005-flat-feature-tree.md)
- **Feature-owned singletons** — every store under its owning feature's `mobx/`. [ADR-0006](docs/adr/0006-feature-owned-singletons.md)
- **DI scopes + constructor injection** — never `getIt<>()` inside a class; one seam only, `Provider(create:)`. [ADR-0007](docs/adr/0007-di-scopes-and-constructor-injection.md)
- **`AppNavigator` routing** — pages never use `context.router`; states inject `AppNavigator`. [ADR-0008](docs/adr/0008-appnavigator-routing-abstraction.md)
- **Provider-based state access** — page root creates the `Provider`; descendants `context.read<T>()`. Never pass state as a widget parameter. [ADR-0009](docs/adr/0009-provider-based-state-access.md)
- **`HookWidget` default** — `StatelessWidget` for pure presentation; `StatefulWidget` only for hook-incompatible APIs. [ADR-0010](docs/adr/0010-hookwidget-default.md)
- **Retrofit + freezed API layer** — `@RestApi()` providers in `packages/api`, `@freezed sealed` DTOs, access only via `DioService`. [ADR-0011](docs/adr/0011-retrofit-typed-api-layer.md)
- **Mandatory localization** — no inline UI strings; `LocaleKeys.x.tr()` only. [ADR-0012](docs/adr/0012-mandatory-localization.md)
- **DS tokens only in `lib/`** — no raw colours, text styles, radii, durations or shadow stacks. [ADR-0013](docs/adr/0013-design-system-tokens-only.md)
- **Melos workspace, two packages** — `api` + `design_system` as workspace siblings. [ADR-0014](docs/adr/0014-melos-package-split.md)
- **Mandatory test coverage + QA gate** — unit + widget + Maestro happy/failure/edge per feature. [ADR-0015](docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)
- **Plan-first delivery** — AC checklist and written plan before code. [ADR-0016](docs/adr/0016-plan-first-delivery-workflow.md)
- **Single-source agent instructions** — this file; tool files generated. [ADR-0017](docs/adr/0017-single-source-agent-instructions.md)

## Rules that apply to every change

These are the ones worth carrying in your head. Everything else is in a playbook.

- **No `context.router`** anywhere. Inject `AppNavigator` into the state class.
- **No state as a widget parameter.** `Provider` at the page root, `context.read<T>()` below.
- **No `getIt<>()` inside a class.** Constructor injection only; `Provider(create:)` is the sole exception.
- **No inline UI strings.** `LocaleKeys.key.tr()`, added to `assets/translations/en-US.json`, then `melos run translations`.
- **No raw colours, `TextStyle(…)` composites, radii, durations or `BoxShadow` stacks in `lib/`.** Use `context.geist.*`, `GeistTextStyles.*`, `GeistRadius.*`, `GeistDuration.*`, `kSpacingNpx`. New tokens are added to the design system with **both light and dark values**.
- **No redundant getter for `@readonly`** — it already generates the public getter. `@computed` is for derived state only.
- **Relative imports inside `lib/`, single quotes, trailing commas on multiline args.** `analysis_options.yaml` promotes these to errors, along with `cascade_invocations`, `avoid_print`, `cancel_subscriptions`.
- **Never edit generated files.** Change the annotation and run `melos run build`.
- **Every widget an E2E flow touches is tagged with `TestId`** from the feature's `*_keys.dart` (plain `String` ids), plus a `Semantics` label from `LocaleKeys`. A bare `Key` is invisible to Maestro — only `Semantics(identifier:)` sets a native accessibility id.

## Testing

Rationale: [ADR-0015](docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). Playbooks: [`write-tests`](.claude/skills/write-tests/SKILL.md), [`write-maestro-flow`](.claude/skills/write-maestro-flow/SKILL.md), [`qa-feature`](.claude/skills/qa-feature/SKILL.md).

A feature is done when all three tiers exist:

| Tier | Where | Covers |
|---|---|---|
| Unit | `test/features/{feature}/` | stores, states, use cases, services |
| Widget | `test/features/{feature}/view/` | page renders each state; callbacks fire |
| E2E | `.maestro/flows/{feature}/` | the journey on a device — **happy, failure, edge** |

Run the E2E suite against `.maestro` (the workspace root), not `.maestro/flows` — the directory runner does not recurse.

## Before every PR

`melos run verify`, then `melos run maestro` (needs a booted device with the dev build installed), then the [`qa-feature`](.claude/skills/qa-feature/SKILL.md) gate: every AC line maps to a passing test or flow, and happy / failure / edge all exist.

## Quick Navigation

- Pages & states → `lib/features/*/view/` · Stores → `lib/features/*/mobx/`
- Use cases → `lib/features/*/{mobx,view,core}/use_cases/`, `lib/core/use_cases/`
- Reusable UI → `lib/core/ui/` · Services → `lib/core/services/` · Navigation → `lib/core/navigation/`
- API providers → `packages/api/lib/src/providers/` · DTOs → `packages/api/lib/src/models/`
- Design tokens → `packages/design_system/lib/src/theme/src/geist_theme.dart` · Visual spec → [`DESIGN.md`](DESIGN.md)
- DI bootstrap → `lib/injectable.dart`, `lib/core/services/get_it.dart`
- Entrypoints → `lib/main.dart`, `lib/main_dev.dart`, `lib/main_prod.dart`
