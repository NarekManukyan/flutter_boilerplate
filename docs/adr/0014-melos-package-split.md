# 14. Melos Package Split: `api` and `design_system`

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Two parts of the codebase have a different change cadence and audience from feature code: the HTTP client + DTOs, and the design system. Keeping them inside `lib/` mixes their codegen with feature-level codegen, makes it hard to share them with future apps, and clutters feature trees with `models/` and `theme/` peers.

We need a packaging strategy that isolates these concerns without forcing a multi-repo setup.

## Decision Drivers

- Reuse — `packages/api` and `packages/design_system` are candidates for sharing across apps.
- Build hygiene — codegen scoped to the package that needs it, not the whole app.
- Single repo — one `git`/PR/CI for everything; no submodules.

## Considered Options

- **Melos workspace + Dart `workspace:` + two packages (`api`, `design_system`)**.
- **Single package — everything under `lib/`**.
- **Separate repos for `api` and `design_system`, consumed via git refs or pub.dev**.

## Decision Outcome

Chosen option: **Melos workspace + Dart `workspace:`**.

Top-level [`pubspec.yaml`](../../pubspec.yaml) declares:

```yaml
workspace:
  - packages/api
  - packages/design_system
```

…which makes `dart pub` resolve all three packages together, and registers `melos` (`^7.5.1`) for multi-package script orchestration. Melos scripts (defined in the same `pubspec.yaml`) drive package-aware operations:

| Script | Purpose |
|---|---|
| `melos run bootstrap` (custom) | Get deps + generate code for every package — runs `melos run deps && melos run generate` |
| `melos run build` | `translations`, then `build:api` → `build:design_system` → `build:app`, in that order |
| `melos run build:api` / `build:design_system` / `build:app` | `dart run build_runner build -d` scoped to one package |
| `melos run analyze` / `test` / `format` / `lint` | Per-package code quality |
| `melos run translations` | Run `easy_localization:generate` against `assets/translations/en-US.json` |
| `melos exec --scope api -- "..."` | Run an arbitrary command inside one package |

> **Naming note:** `melos bootstrap` (without `run`) is the Melos built-in that runs `pub get` across the workspace. The custom `bootstrap:` script defined in `pubspec.yaml` is invoked as `melos run bootstrap` and additionally runs codegen. Use `melos run bootstrap` when you want both deps + codegen; the bare `melos bootstrap` only fetches deps.

### Codegen order

Codegen runs in a fixed order: `api`, then `design_system`, then the app. The app's generators (Injectable, MobX, AutoRoute) resolve types from both packages, so the packages' generated code has to exist before the app's build runs. Otherwise a type such as a freezed DTO does not resolve while the app's code is generated.

Each step has its own script: `build:api`, `build:design_system` and `build:app`. `melos run build` runs `translations` first and then the three scripts in that order. Translations come first because the generated `LocaleKeys` are not committed, and a clean checkout does not analyze without them. A change confined to one package only needs that package's script. If the change alters a type the app uses, run `build:app` after it.

### Package responsibilities

- **`packages/api`** — HTTP boundary. `@RestApi()` Retrofit providers + `@freezed` DTOs. Has no Flutter dependency on widgets. See [ADR-0011](0011-retrofit-typed-api-layer.md).
- **`packages/design_system`** — visual language. `GeistTheme`, components (`PrimaryButton`, etc.), generated `Assets`, asset codegen via `flutter_gen`. See [ADR-0013](0013-design-system-tokens-only.md).
- **`lib/`** (the app) — features, navigation, DI bootstrap, app-level services (`DioService`, interceptors), localization wiring.

### Dependency direction

Dependencies point one way, into the packages:

```
            app (lib/)
           /          \
          v            v
        api      design_system
```

- The app depends on both packages.
- **`api` and `design_system` depend on neither each other nor the app.** A DTO or provider never imports a widget or a token, and a component never imports a DTO, a provider, or anything from `lib/`.
- The app is where the two meet. A store turns DTOs into observable state, and a page passes plain values and callbacks into design-system components.

This is what the reuse driver depends on. A package that imports the app does not build in any other app. A package that imports its sibling drags the sibling into every app that wants only one of them, and an edge from `api` to `design_system` would also invert the codegen order above.

In practice:

- A package's `pubspec.yaml` never lists `flutter_boilerplate` or the other package.
- A package's files never import `package:flutter_boilerplate/…`, the other package, or a relative path that climbs out of the package.
- A component that shows API data takes the fields it renders as parameters; mapping the DTO to those fields is app code.
- Something both packages seem to need is defined in each, or lives in the app. If a real shared core appears, it becomes a third package that both depend on, recorded in a new ADR.

### Consequences

- Good: codegen runs only where it changes. Editing a DTO needs `build:api` (plus `build:app` if the app uses the changed type), not the design system.
- Good: `packages/*` can be lifted into another app with no rewrite — they have no dependency on `lib/`.
- Good: Dart workspace gives a single `pub get` resolution; no version drift between packages.
- Bad: three `pubspec.yaml` files instead of one — adding a dependency requires choosing the right package.
- Bad: `melos` is an extra tool contributors must install (`dart pub global activate melos` or via the workspace dev_dependency).
- Bad: the codegen order is enforced only by the `build` script. Running a single package script by hand in the wrong order can leave the app's generated code stale.
- Bad: the dependency direction is not enforced by the analyzer. A package could add the other one to its pubspec and nothing would fail until another app tried to reuse it; review has to catch it.
- Neutral: code that maps API data to UI cannot live in either package, so it sits in the app, even when it looks generic.

### Confirmation

These checks print nothing while the dependency direction holds:

```bash
grep -nE '^\s+(api|design_system|flutter_boilerplate):' packages/api/pubspec.yaml packages/design_system/pubspec.yaml
grep -rnE "package:(flutter_boilerplate|design_system)/" packages/api/lib; grep -rnE "package:(flutter_boilerplate|api)/" packages/design_system/lib
```

## Pros and Cons of the Options

### Melos workspace + Dart `workspace:`
- Good: clean isolation, single repo, shared lockfile.
- Bad: extra `pubspec.yaml` files; melos learning curve.

### Single package
- Good: simplest pubspec.
- Bad: codegen and tests run for the whole app every time; no path to reuse `api` / `design_system` in another app.

### Separate repos
- Good: maximal isolation; independent versioning.
- Bad: cross-cutting changes need three PRs; submodule / pub-private setup adds CI complexity.

## Links

- [ADR-0011 Retrofit + freezed typed API layer](0011-retrofit-typed-api-layer.md)
- [ADR-0013 Design-system tokens only](0013-design-system-tokens-only.md)
- Code: [pubspec.yaml](../../pubspec.yaml), [packages/api](../../packages/api), [packages/design_system](../../packages/design_system)
