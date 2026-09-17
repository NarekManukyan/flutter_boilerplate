# Project Structure

Where things live in this boilerplate, and how to find them quickly. Companion to [architecture.md](architecture.md), which explains how the layers talk to each other. The placement rules come from [ADR-0005](adr/0005-flat-feature-tree.md), [ADR-0006](adr/0006-feature-owned-singletons.md) and [ADR-0014](adr/0014-melos-package-split.md).

## Root structure

```
flutter_boilerplate/
  lib/                     the Flutter app
  packages/                api/ and design_system/, the two workspace packages
  assets/translations/     en-US.json
  test/                    unit + widget tests, mirrors lib/
  .maestro/                config.yaml, flows/{feature}/, common/ subflows, output/ (gitignored)
  tool/                    run_maestro.sh, sync_agents.sh, git-hooks/pre-commit
  docs/                    adr/, plans/, and the guides
  .claude/                 skills/, agents/, commands/, scripts/, settings.json
  .github/workflows/       verify.yml, maestro.yml, claude*.yml, glm.yml
  .cursor/rules/           Cursor rules; 000-agents.mdc is generated
  AGENTS.md                agent instructions, the single source (ADR-0017)
  CLAUDE.md  GEMINI.md     generated from AGENTS.md; do not edit
  DESIGN.md                visual spec for the design system
  pubspec.yaml             dependencies, Dart workspace, melos scripts
  analysis_options.yaml    lints, several promoted to errors
```

`ios/` and `android/` are not committed; see [Platform code](#platform-code).

### Tooling folders

- **`.claude/`** — `skills/{name}/SKILL.md` are the playbooks. `agents/` holds `flutter-team`, `ios-team`, `android-team` and `mobile-orchestrator`. `commands/` holds slash commands such as `build-feature`, `qa-feature` and `review-pr`. `scripts/` holds the hooks `settings.json` registers: `track_change.sh` after each edit, `post_turn.sh` at the end of a turn. Everything is Markdown or shell, so any tool can read it. `settings.local.json`, `state/` and `worktrees/` are gitignored.
- **`docs/`** — `adr/` records decisions, indexed in `adr/README.md`. `plans/` holds approved feature plans as `{TICKET}-{slug}.md`; the first plan creates it. The guides sit flat in `docs/`.
- **`.maestro/`** — `config.yaml` runs `flows/*/*.yaml` and skips the `quarantine` tag. Subflows in `common/` (`launch`, `login`, `start_home`, `set_mock`, `go_offline`, `go_online`) never match that glob. `tool/run_maestro.sh` runs the suite from the workspace root with `APP_ID`.
- **`.github/workflows/`** — `verify.yml` runs the `melos run verify` checks on pull requests; `maestro.yml` runs the E2E suite.

## Main application (`lib/`)

```
lib/
  main.dart                run(): bindings, localization, DI, Sentry
  main_dev.dart  main_prod.dart   flavor entry points
  app.dart                 MaterialApp.router (keyed on dependencyGeneration), themes, ConnectionWrapperPage
  injectable.dart          configureDependencies, resetDependencies, dependencyGeneration
  core/                    cross-feature infrastructure
  features/                feature modules
  gen/                     GENERATED: locale_keys.g.dart, assets.gen.dart
```

### Core (`lib/core/`)

Infrastructure used by more than one feature, with no feature logic:

```
lib/core/
  configs/        environments/{development,production}/ (JSON + loader), models/config/ (Config)
  constants/      FlavorType, AppUpdateType, SupportedLocals, ReCaptchaAction, TimingConstants, regexp.dart
  extensions/     infinity_scroll_extension.dart
  guards/         AuthGuard
  navigation/     AppNavigator, AppRouter
  services/       DioService, FlavorService, IssueTrackingService, AppUpdateService,
                  get_it.dart, third_party_module.dart,
                  interceptors/ (ApiInterceptor, AuthInterceptor, MockTodosInterceptor)
  state/          LoadingState
  ui/             TestId, ErrorNotice, EmptyWidget, OverlayEntryLoading, geist_motion.dart
  use_cases/      OpenTodoDetailsUseCase
  utils/          debounce_reaction.dart, dimens.dart, file_util.dart, storage_utils.dart, ui_utils.dart
```

Three more folders appear when the app first needs them: `exceptions/`, `platform_channels/` and `hooks/` ([`create-feature`](../.claude/skills/create-feature/SKILL.md#what-belongs-in-libcore-instead)). A model several features share goes in `lib/core/models/`.

### Features (`lib/features/`)

Features are peers. None contains a `features/` folder, and each has only the folders it needs:

```
lib/features/{feature}/
  view/            *_page.dart, *_page_state.dart, *_keys.dart, widgets/, use_cases/
  mobx/            *_store.dart, use_cases/
  core/use_cases/  use cases shared by layers of this feature
  modals/{modal}/  view/, mobx/ (the modal's state), use_cases/
  models/  constants/  components/  overlays/
```

| Feature | Contents |
|---|---|
| `app` | `ConnectivityStore`, `NotificationsStore` (both `@singleton`) and `ConnectionWrapperState` in `mobx/`; `view/connection_wrapper_page.dart`; `modals/app_update_modal/` |
| `auth` | `mobx/auth_store.dart` (`@singleton`); `view/` login page, state and `login_keys.dart` |
| `challenges` | `view/challenge_joined/`: page, state and `widgets/`, no store |
| `home` | `mobx/home_store.dart` (`@singleton`); `models/todo_filter.dart`; `view/` page, state, `home_keys.dart`, `use_cases/show_add_todo_modal_use_case.dart`; `modals/add_todo_modal/` with `create_todo_use_case.dart` |
| `splash` | `view/splash_page.dart` and `splash_page_state.dart` (routes to Home or Login) |
| `todo_details` | `view/` page, state and `use_cases/fetch_todo_use_case.dart`; no store |

`app` holds app-wide concerns with no natural owner. `challenges/view/challenge_joined/` is a view-only sub-page, which may stay under its parent's `view/`; once it gains a store it becomes a peer feature. There is no `lib/shared/`, and nothing new goes there ([ADR-0006](adr/0006-feature-owned-singletons.md)).

## Packages (`packages/`)

Two workspace packages resolved together with the app. Dependencies point from the app into the packages; `api` and `design_system` import neither each other nor the app ([ADR-0014](adr/0014-melos-package-split.md)).

### API (`packages/api/`)

```
packages/api/lib/
  api.dart                            barrel: package:api/api.dart
  src/providers/auth_provider/        AuthProvider + models/ (AuthResponseDto, UserResponseDto, …)
  src/providers/todos_provider/       TodosApiProvider + models/ (TodoDto, TodoCreateRequestDto)
  src/models/list_response_entity/    ListResponseDto<T>, MetaDto: shared across providers
  src/constants/typedefs.dart
```

One directory per resource holds the `@RestApi()` provider, its DTOs under `models/src/`, and barrels. A DTO moves to `src/models/` when a second provider needs it ([ADR-0011](adr/0011-retrofit-typed-api-layer.md)). The app reaches a provider only through `DioService`, as in `_dioService.todosProvider`.

### Design system (`packages/design_system/`)

```
packages/design_system/
  lib/design_system.dart    barrel
  lib/src/theme/src/        geist_theme.dart (GeistTheme via context.geist, GeistTextStyles,
                            GeistRadius, GeistDuration), light_theme.dart, dark_theme.dart, theme_tailor/
  lib/src/components/src/   app_bars/, images/, modal_components/, radio/, LoadingWidget, MutedScaleTap
  lib/src/core/src/         constants/ (kSpacing16px, kBorderRadius16px, …), extensions/
  lib/gen/                  GENERATED by flutter_gen: assets, colors, fonts
  assets/                   fonts/ (Inter, Lexend), icons/, colors/colors.xml
```

Screens in `lib/` use these tokens instead of raw colours, text styles, radii and durations ([ADR-0013](adr/0013-design-system-tokens-only.md)). [DESIGN.md](../DESIGN.md) is the visual spec.

## Assets (`assets/`)

`assets/translations/en-US.json` holds every UI string. After editing it, run `melos run translations` to regenerate `lib/gen/locale_keys.g.dart`, and read strings as `LocaleKeys.x.tr()` ([ADR-0012](adr/0012-mandatory-localization.md)). Fonts, icons and colours belong to the design system, under `packages/design_system/assets/`. Per-flavor config is not an asset: it is in `lib/core/configs/environments/`.

## Platform code

`ios/` and `android/` are gitignored. Each app generates its own, with its own bundle id and signing: `flutter create --platforms=ios,android --org com.yourcompany .`. Everything except building and running on a device works without them. Native work in a generated app goes to the `ios-team`, `android-team` and `mobile-orchestrator` agents and the [`add-platform-channel`](../.claude/skills/add-platform-channel/SKILL.md) playbook.

## Testing (`test/`)

`test/` mirrors `lib/`, so a test's path says what it covers. `create_todo_use_case.dart` lives in `lib/features/home/modals/add_todo_modal/use_cases/`, and its test in `test/features/home/modals/add_todo_modal/use_cases/`.

```
test/
  core/services/          IssueTrackingService (all filtering rules), FlavorService, interceptors/ (AuthInterceptor)
  features/{feature}/     mirrors the source: mobx/ stores, view/ page states and widget tests side by side, modals/, use_cases/
  helpers/pump_app.dart   initLocalizationForTests, pumpApp, settleFrames
  widget_test.dart        ErrorNotice test; stops flutter create from writing its counter test
```

E2E flows live in `.maestro/flows/{feature}/`. A feature needs all three tiers ([ADR-0015](adr/0015-mandatory-test-coverage-and-qa-gate.md)); see [`write-tests`](../.claude/skills/write-tests/SKILL.md) and [`write-maestro-flow`](../.claude/skills/write-maestro-flow/SKILL.md).

## Naming conventions

| Type | Pattern | | Type | Pattern |
|---|---|---|---|---|
| Page | `*_page.dart` | | DTO | `*_dto.dart` |
| Page state | `*_page_state.dart` | | Service | `*_service.dart` |
| Modal | `*_modal.dart` | | Modal state | `*_modal_state.dart` |
| Store | `*_store.dart` | | API provider | `*_api_provider.dart` |
| Use case | `*_use_case.dart` | | Test ids | `*_keys.dart` |
| Model | `*_model.dart` | | Typed exception | `*_exception.dart` |
| Utils | `*_utils.dart` | | Platform channel | `*_channel.dart` |
| Constants | `*_constants.dart` | | Directories | `snake_case` |
| Widget | `*_widget.dart` | | Maestro flow | `{feature}_{scenario}_{happy\|failure\|edge}.yaml` |

File names are `snake_case` too. A test is the source file name plus `_test.dart`. The files already in `lib/core/constants/` predate the `*_constants.dart` suffix; only `timing_constants.dart` follows it. An enum in `models/` is named after its type (`todo_filter.dart`).

## Quick navigation

- Pages and page states → `lib/features/*/view/` · Stores → `lib/features/*/mobx/` · Modals → `lib/features/*/modals/`
- Use cases → `lib/features/*/{view,mobx,core}/use_cases/`, `lib/features/*/modals/*/use_cases/`, `lib/core/use_cases/`
- Reusable widgets → `lib/core/ui/` · State primitives → `lib/core/state/`
- Services and interceptors → `lib/core/services/` · Routes and `AppNavigator` → `lib/core/navigation/` · Guards → `lib/core/guards/`
- Flavor config → `lib/core/configs/environments/` · Strings → `assets/translations/en-US.json`
- API providers and their DTOs → `packages/api/lib/src/providers/` · Shared DTOs → `packages/api/lib/src/models/`
- Design tokens → `packages/design_system/lib/src/theme/src/geist_theme.dart` · Visual spec → [DESIGN.md](../DESIGN.md)
- DI bootstrap → `lib/injectable.dart`, `lib/core/services/get_it.dart` · Entry points → `lib/main.dart`, `lib/main_dev.dart`, `lib/main_prod.dart`
- Playbooks → `.claude/skills/` · Decisions → `docs/adr/` · Plans → `docs/plans/`

## Generated code

Never edit by hand: `*.g.dart`, `*.gr.dart`, `*.freezed.dart`, `*.gen.dart`, `*.tailor.dart`, `lib/gen/`, `packages/*/lib/gen/`, `injectable.config.dart`. Change the annotation and run `melos run build`, which runs translations, then `api`, `design_system` and the app, in that order. These files are gitignored, so a fresh clone needs `melos run bootstrap` before it analyzes.

`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` and `.cursor/rules/000-agents.mdc` are generated from `AGENTS.md`. Edit `AGENTS.md`, then run `melos run sync-agents`.

## More information

- [ADR-0005 Flat feature tree](adr/0005-flat-feature-tree.md) · [ADR-0006 Feature-owned singletons](adr/0006-feature-owned-singletons.md) · [ADR-0014 Melos package split](adr/0014-melos-package-split.md) · [ADR-0004 Use case colocation](adr/0004-use-case-taxonomy-and-colocation.md)
- Playbooks: [`create-feature`](../.claude/skills/create-feature/SKILL.md), [`create-store`](../.claude/skills/create-store/SKILL.md), [`create-use-case`](../.claude/skills/create-use-case/SKILL.md)
- Guides: [architecture.md](architecture.md), [use_cases_guide.md](use_cases_guide.md), [troubleshooting.md](troubleshooting.md) · [AGENTS.md](../AGENTS.md)
