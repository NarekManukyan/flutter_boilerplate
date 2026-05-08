# CLAUDE.md

## Project Overview

Flutter mobile boilerplate using layered clean architecture with MobX state management, Retrofit API layer (`packages/api`), shared design system (`packages/design_system`), and GetIt + Injectable dependency injection. Melos-managed monorepo.

## Architectural decisions

Rules below are summaries. Full context, alternatives considered, and rationale are in [`docs/adr/`](docs/adr/README.md). Read the ADR when you need *why*.

- **Layered architecture, adjacent-only access** — UI → State → Store → DioService → API Provider; UI never reaches Dio or stores directly. [ADR-0001](docs/adr/0001-layered-architecture.md)
- **State vs Store separation** — `*_state.dart` is per-screen with no API access; `*_store.dart` owns API and may be feature-scoped or `@singleton`. [ADR-0002](docs/adr/0002-state-vs-store-separation.md)
- **No use-case → use-case dependencies** — UCs depend on services/stores/navigators only; shared logic becomes a service, not a peer UC. [ADR-0003](docs/adr/0003-no-use-case-to-use-case-dependencies.md)
- **Use-case taxonomy + colocation** — 4 UC types (API / Navigation / Service Coordination / State Delegation); placement follows the consumer layer; promote on second consumer. [ADR-0004](docs/adr/0004-use-case-taxonomy-and-colocation.md)
- **Flat feature tree** — features are peers under a domain grouping; no nested `features/` inside a feature. [ADR-0005](docs/adr/0005-flat-feature-tree.md)
- **Feature-owned singletons** — every store lives under its owning feature's `mobx/`, regardless of `@singleton` vs `@injectable`; `lib/shared/` is deprecated. [ADR-0006](docs/adr/0006-feature-owned-singletons.md)
- **DI scopes + constructor injection** — `@injectable`, `@singleton`, `@lazySingleton`; flavor bindings via `@dev`/`@prod`; never `getIt<>()` inside classes (one allowed seam: `Provider(create:)`). [ADR-0007](docs/adr/0007-di-scopes-and-constructor-injection.md)
- **`AppNavigator` routing abstraction** — pages never use `context.router`; states inject `AppNavigator`. [ADR-0008](docs/adr/0008-appnavigator-routing-abstraction.md)
- **Provider-based state access** — page roots create `Provider<MyPageState>`; descendants read via `context.read<T>()`; never pass state as widget params. [ADR-0009](docs/adr/0009-provider-based-state-access.md)
- **`HookWidget` default** — `HookWidget` for any widget needing controllers/effects/local state; `StatelessWidget` for pure presentation; `StatefulWidget` only for hook-incompatible APIs. [ADR-0010](docs/adr/0010-hookwidget-default.md)
- **Retrofit + freezed typed API layer** — `@RestApi()` providers in `packages/api`; `@freezed sealed` DTOs; `ListResponseDto<T>` for paginated lists; access only via `DioService`. [ADR-0011](docs/adr/0011-retrofit-typed-api-layer.md)
- **Mandatory localization** — no inline UI strings; `LocaleKeys.x.tr()` only; add to `assets/translations/en-US.json` then `melos run translations`. [ADR-0012](docs/adr/0012-mandatory-localization.md)
- **DS tokens only in `lib/`** — no raw colors, text styles, or shadow stacks; tokens live in `packages/design_system` with both light + dark values. [ADR-0013](docs/adr/0013-design-system-tokens-only.md)
- **Melos workspace, two packages** — `packages/api` + `packages/design_system` as Dart workspace siblings; melos scripts drive codegen / lint / test. [ADR-0014](docs/adr/0014-melos-package-split.md)

## Commands

```bash
# Development (dev flavor)
flutter run -t lib/main_dev.dart

# Production
flutter run -t lib/main_prod.dart

# Bootstrap workspace (deps + codegen, all packages)
melos run bootstrap     # runs `melos run deps && melos run generate`
# Note: bare `melos bootstrap` (Melos built-in) only fetches deps.

# Code generation (after changing MobX, Retrofit, Freezed, Injectable annotations)
melos run build

# Single package codegen
melos exec --scope api -- "dart run build_runner build -d"
melos exec --scope design_system -- "dart run build_runner build -d"

# Analyze / test / format / auto-fix lints
melos run analyze
melos run test
melos run format
melos run lint          # dart fix --apply

# Single test file
flutter test test/path/to_file_test.dart

# Translations (after editing assets/translations/en-US.json)
melos run translations

# Deploy dev build (iOS)
melos run deploy-dev
```

## Architecture

Rationale + alternatives: [ADR-0001](docs/adr/0001-layered-architecture.md).

### Layer Rules

| Layer | Files | Can Access | Cannot Access |
|---|---|---|---|
| UI | `*_page.dart`, `*_widget.dart` | State classes via `context.read<T>()` | DioService, Stores directly |
| State | `*_state.dart` | Stores, AppNavigator, Use Cases | DioService directly |
| Store | `*_store.dart` | DioService, other Stores, Use Cases | — |
| Use Case | `*_use_case.dart` | DioService, Services, AppNavigator | Other Use Cases |
| Data | `packages/api` providers | — | — |

### Communication Flow

```
UI → State → Store → DioService → API Provider
                ↘ Use Case ↗
```

### Entry Flow

`main_dev.dart` / `main_prod.dart` → `main.dart:run(FlavorType)` → `WidgetsFlutterBinding` + portrait lock + `EasyLocalization.ensureInitialized()` + `registerGetIt(env)` → Sentry init in release, skipped in debug → `MyApp` renders `MaterialApp.router` with `AppNavigator.config` from GetIt, wrapped in `ConnectionWrapperPage` + `OverlaySupport.global`.

## Project Structure

```
flutter_boilerplate/
├── lib/
│   ├── core/
│   │   ├── configs/          # App configuration
│   │   ├── constants/        # FlavorType, SupportedLocals, etc.
│   │   ├── extensions/       # Dart extensions
│   │   ├── guards/           # Route guards
│   │   ├── navigation/       # AppNavigator, router
│   │   ├── services/         # FlavorService, DioService, interceptors, social auth
│   │   ├── ui/               # Reusable widgets (cross-feature)
│   │   ├── use_cases/        # App-wide use cases (cross-feature)
│   │   └── utils/            # Utilities
│   ├── features/{feature}/
│   │   ├── view/             # Pages, states, widgets
│   │   │   └── use_cases/    # Use cases consumed only by view/state layer
│   │   ├── mobx/             # Feature stores
│   │   │   └── use_cases/    # Use cases consumed only by store layer
│   │   ├── core/use_cases/   # Use cases shared across layers within the feature
│   │   ├── models/
│   │   ├── modals/
│   │   │   └── use_cases/    # Use cases consumed only by modal states
│   │   └── components/
│   ├── gen/                  # Generated (locale_keys.g.dart, assets) — NEVER edit
│   ├── app.dart              # MyApp root widget
│   ├── main.dart             # run() entry
│   ├── main_dev.dart         # dev flavor entrypoint
│   ├── main_prod.dart        # prod flavor entrypoint
│   ├── injectable.dart       # configureDependencies, resetDependencies
│   └── injectable.config.dart # Generated DI wiring — NEVER edit
├── packages/
│   ├── api/lib/src/
│   │   ├── providers/        # Retrofit API providers (@RestApi)
│   │   ├── models/           # DTOs (*_dto.dart) with freezed + json_serializable
│   │   └── constants/
│   └── design_system/lib/
│       ├── src/              # Themes, components, colors, typography
│       └── gen/              # Generated asset bindings — NEVER edit
├── assets/translations/      # en-US.json etc.
└── test/
```

### `lib/shared/` — DEPRECATED — see [ADR-0006](docs/adr/0006-feature-owned-singletons.md)

`lib/shared/` currently contains `stores/` (auth_store, connectivity, notifications_store), `features/connection_wrapper`, `widgets/`, `modals/`, `state/`, `constants/`. **Do not add new files there.** New code belongs under the owning feature, regardless of singleton scope.

- **Stores** (even singletons like `AuthStore`) → `lib/features/{owning_feature}/mobx/`
- **Reusable UI components** → `lib/core/ui/`
- **Reusable models** → `lib/core/models/` or the owning feature's `models/`

Existing `lib/shared/` files may be migrated opportunistically when touched.

### No nested `features/` — features are peers — see [ADR-0005](docs/adr/0005-flat-feature-tree.md)

A feature must **never** contain a `features/` subdirectory. Sub-modules with their own store/state/view get promoted to siblings under the domain grouping.

```
# ❌ WRONG — nested features
lib/features/meetings/meeting_details/features/ai_chat/

# ✅ CORRECT — peer features under domain
lib/features/meetings/ai_chat/
lib/features/meetings/meeting_details/
```

Pure view-layer sub-pages (no store) can remain under `view/` (e.g., `meeting_details/view/share_meeting/`).

## File Boundaries

- **Safe to edit**: `lib/`, `packages/api/lib/src/`, `packages/design_system/lib/src/`, `test/`
- **Never manually edit**: `*.g.dart`, `*.gr.dart`, `*.freezed.dart`, `*.gen.dart`, `lib/gen/`, `packages/*/lib/gen/`, `injectable.config.dart`

## Naming Patterns

| Type | Pattern | Example |
|---|---|---|
| Pages | `*_page.dart` | `login_page.dart` |
| Page States | `*_page_state.dart` | `login_page_state.dart` |
| Stores | `*_store.dart` | `auth_store.dart` |
| Use Cases | `*_use_case.dart` | `create_tag_use_case.dart` |
| Widgets | `*_widget.dart` | `avatar_widget.dart` |
| DTOs | `*_dto.dart` | `user_dto.dart` |
| Services | `*_service.dart` | `flavor_service.dart` |
| API Providers | `*_api_provider.dart` | `auth_api_provider.dart` |

## Critical Rules

### Navigation — NEVER use `context.router`

Rationale + alternatives: [ADR-0008](docs/adr/0008-appnavigator-routing-abstraction.md).

Always inject `AppNavigator` into state classes. Pages call state methods, never navigate directly.

```dart
// ❌ FORBIDDEN
context.router.push(const SomeRoute());

// ✅ CORRECT — in state class
abstract class _MyPageStateBase with Store {
  final AppNavigator _appNavigator;
  _MyPageStateBase(this._appNavigator);

  @action
  void navigateToSettings() {
    _appNavigator.push(const SettingsRoute());
  }
}
```

### State Access — NEVER pass state as widget parameters

Rationale + alternatives: [ADR-0009](docs/adr/0009-provider-based-state-access.md).

Create `Provider` at the page root. Child widgets access via `context.read<T>()`.

```dart
// ❌ WRONG
class _MySection extends StatelessWidget {
  final MyPageState state;
}

// ✅ CORRECT
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => getIt<MyPageState>()..init(),
      dispose: (_, value) => value.dispose(),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.read<MyPageState>();
    return Scaffold(/* ... */);
  }
}
```

### MobX @readonly — NEVER create redundant getters

`@readonly` auto-generates a public getter. Never add `@computed` for it.

```dart
// ✅ CORRECT
@readonly
bool _hasActiveSubscription = false;
// Access as: store.hasActiveSubscription (auto-generated)

// ❌ FORBIDDEN — redundant getter
@readonly
bool _hasActiveSubscription = false;
@computed
bool get hasActiveSubscription => _hasActiveSubscription; // DELETE

// ✅ @computed only for derived state
@computed
bool get hasItems => _items.isNotEmpty;
```

### Dependency Injection

Rationale + alternatives: [ADR-0007](docs/adr/0007-di-scopes-and-constructor-injection.md).

- `@injectable` — feature-scoped (State classes, feature Stores, Use Cases)
- `@singleton` — app-wide Stores (`AuthStore`, etc.) and `AppNavigator` — still live under their owning feature's `mobx/`
- `@lazySingleton` — app-wide services constructed on first resolution (e.g. `DioService`)
- Flavor-scope bindings with `@dev` / `@prod` — `configureDependencies(FlavorType)` passes the flavor name as the `environment` to injectable
- Always inject via constructor. Never call `getIt<>()` inside classes (except at Widget→State boundary inside `Provider(create:)`)
- `resetDependencies()` tears down GetIt and re-registers with current flavor — use for env switching

### Widgets — HookWidget over StatefulWidget

Rationale + alternatives: [ADR-0010](docs/adr/0010-hookwidget-default.md).

Use `HookWidget` for local state/lifecycle. Use `StatelessWidget` for pure presentation.

```dart
class _Content extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    useEffect(() { /* side effect */ return () { /* cleanup */ }; }, []);
    return Text('${counter.value}');
  }
}
```

## Use Cases

Use cases (`*_use_case.dart`) encapsulate a single business operation. `@injectable` classes with a `call()` method. Rationale + alternatives: [ADR-0003](docs/adr/0003-no-use-case-to-use-case-dependencies.md), [ADR-0004](docs/adr/0004-use-case-taxonomy-and-colocation.md).

- **No UC → UC** — UC depends on services / stores / `AppNavigator`, never another UC. Shared logic becomes a service.
- **4 types** — API / Navigation / Service Coordination / State Delegation.
- **Place next to consumer** — see Location Rules below; promote on second consumer.

### Pattern

```dart
@injectable
class CreateTagUseCase {
  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  CreateTagUseCase(this._dioService, this._issueTrackingService);

  Future<String?> call(String name, String color) async {
    try {
      final response = await _dioService.tagsProvider.createTag(
        tagCreateDto: TagCreateUpdateRequestDto(name: name, color: color),
      );
      return response.data.id;
    } on DioException catch (e) {
      _issueTrackingService.trackIssue(e);
      return null;
    }
  }
}

// Usage — direct call syntax (no .call() needed)
final id = await _createTagUseCase(name, color);
```

### Location Rules — by consumer layer

| Consumer | Path |
|---|---|
| Store only | `lib/features/{feature}/mobx/use_cases/` |
| State/View only | `lib/features/{feature}/view/use_cases/` |
| Modal only | `lib/features/{feature}/modals/{modal}/use_cases/` |
| Multiple layers within one feature | `lib/features/{feature}/core/use_cases/` |
| Multiple features | `lib/core/use_cases/` |

Rule: **place next to consumer.** Gains second consumer in different layer → promote one level. Gains consumer in different feature → promote to `lib/core/use_cases/`.

### Extract vs Keep Inline

- **Extract**: reused in 2+ places, coordinates 2+ services, complex enough for its own test
- **Keep inline**: trivial one-liner delegation

## API Layer

Rationale + alternatives: [ADR-0011](docs/adr/0011-retrofit-typed-api-layer.md).

### Retrofit Provider Pattern

```dart
@RestApi()
abstract class TodosApiProvider {
  factory TodosApiProvider(Dio dio) = _TodosApiProvider;

  @GET(_Paths.getTodos)
  Future<List<TodoDto>> getTodos();
}
```

- Single-resource endpoints return the DTO directly; paginated lists return `ListResponseDto<T>` (see `packages/api/lib/src/models/list_response_entity/`)
- DTOs are `@freezed sealed class` with `fromJson` factory (json_serializable `explicit_to_json: true`, `any_map: true` — see `build.yaml`)
- Providers accessed only through `DioService` in Stores/Use Cases
- Interceptors live in `lib/core/services/interceptors/` (app concerns: auth, logging, mocking)

## State vs Store Decision Tree

Rationale + alternatives: [ADR-0002](docs/adr/0002-state-vs-store-separation.md).

| Question | → State (`*_state.dart`) | → Store (`*_store.dart`) |
|---|---|---|
| Needs API access? | No — uses Stores | Yes — injects DioService |
| DI annotation? | `@injectable` | `@injectable` (feature) or `@singleton` (app-wide) |
| Location? | `features/*/view/` | `features/*/mobx/` (always under owning feature) |

## Localization

Rationale + alternatives: [ADR-0012](docs/adr/0012-mandatory-localization.md).

Never hardcode text in UI. Always use `LocaleKeys.keyName.tr()`.

```dart
// ❌ Text('Continue with email')
// ✅ Text(LocaleKeys.loginPage_continueWithEmail.tr())
```

Add strings to `assets/translations/en-US.json`, then run `melos run translations`. Supported locales enumerated in `lib/core/constants/supported_locals.dart` — add new locales there.

## Design System

- Import from `package:design_system/design_system.dart`
- Use named constructors: `PrimaryButton.largeFilled()`
- Use generated `AppColors` and `Assets` — never hardcode colors or asset paths
- Themes (`lightTheme`, `darkTheme`) exposed from package root; both wired in `lib/app.dart`
- Asset codegen lives in `design_system/lib/gen`; root app asset codegen in `lib/gen` via `flutter_gen`

### No hardcoded colors or styles in `lib/` — see [ADR-0013](docs/adr/0013-design-system-tokens-only.md)

The `lib/` layer (app) must never contain raw `Color(0x…)` / hex literals, raw `TextStyle(…)` composites, or one-off shadow stacks. Every visual token lives in the design system package.

- **Colors** → `context.geist.<token>` (Geist palette) or legacy `context.<token>` (Tailor `CustomTheme`). Add new colors to the appropriate extension in `packages/design_system/lib/src/theme/src/` with **both light and dark variants**.
- **Typography** → `GeistTextStyles.<role>` or `context.<textStyle>`. Add new text styles to `GeistTextStyles` (geist) or `TextStyles` (legacy) with `.copyWith(color: …)` at the use site for color swaps only.
- **Radii** → `GeistRadius.<scale>` constants.
- **Durations** → `GeistDuration.<speed>` constants.
- **Shadows / elevation** → `context.geist.cardShadow`, `shadowBorder`, `shadowFab`, etc. Never assemble ad-hoc `BoxShadow` stacks in `lib/`.
- **Spacing** → `kSpacingNpx` constants from `design_system`.

When a new design token is needed:
1. Add the field to `GeistTheme` (or the relevant `ThemeExtension`) with `light` and `dark` values.
2. Update `copyWith` and `lerp` methods.
3. Consume in `lib/` via `context.geist.newToken` — never inline the hex value.

The only allowed "bare" colors in `lib/` are `Colors.transparent` and `Color.lerp` results applied to tokens already sourced from the DS.

### Dark mode

Both `lightTheme` and `darkTheme` include the `GeistTheme` extension. Follow the DESIGN.md dark-mode guidance: desaturated tonal variants, not pure inversion. Always design new tokens in pairs — add a dark value for every new light value. Every foreground/background pair must meet WCAG AA (4.5:1 for body, 3:1 for large/UI glyphs) in **both** modes.

## Testing

- Always use `group()` — name after class under test
- Name tests with "should": `test('should create user with valid data', () {})`
- Ask: "Can this test fail if real code is broken?" — avoid testing only mocked behavior
- Prefer real objects > Fake > Mock
- Arrange-Act-Assert pattern

## Code Quality Workflow

1. Make changes
2. `melos run build` if codegen annotations changed
3. `melos run lint` (`dart fix --apply`)
4. `melos run analyze`
5. `melos run format`

`analysis_options.yaml` promotes these to **errors** (not warnings): `prefer_relative_imports`, `prefer_single_quotes`, `require_trailing_commas`, `cascade_invocations`, `avoid_print`, `cancel_subscriptions`. Use relative imports inside `lib/`, single quotes, trailing commas on multiline args.

Extensive guidance in `.cursor/rules/*.mdc` covering architecture, testing, mocktail/mockito, MobX, navigation, design system, Flutter error handling — consult relevant rule for substantive work.

## Quick Navigation

- **Pages**: `lib/features/*/view/`
- **Page States**: `lib/features/*/view/*_page_state.dart`
- **Stores** (all, including singletons): `lib/features/*/mobx/`
- **Use Cases** (by consumer): `lib/features/*/mobx/use_cases/`, `lib/features/*/view/use_cases/`, `lib/features/*/core/use_cases/`, `lib/core/use_cases/`
- **Reusable UI**: `lib/core/ui/`
- **Core Services**: `lib/core/services/` (`FlavorService`, `DioService`, interceptors, social auth)
- **Navigation**: `lib/core/navigation/`
- **API Providers**: `packages/api/lib/src/providers/`
- **API Models (DTOs)**: `packages/api/lib/src/models/`
- **Design System Components**: `packages/design_system/lib/src/`
- **DI bootstrap**: `lib/injectable.dart`, `lib/core/services/get_it.dart`
- **Entrypoints**: `lib/main.dart`, `lib/main_dev.dart`, `lib/main_prod.dart`
