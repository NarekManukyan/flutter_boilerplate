# Performance Guide

Read this when you are building a long list, an animation, an image-heavy screen, startup work or heavy parsing, or when you are chasing jank, memory growth, battery drain or app size. It covers where time and memory go on this stack (MobX `Observer`, flutter_hooks, the Geist design system, `extended_image`, `skeletonizer`, Dio/Retrofit/freezed, easy_localization, auto_route) and how to measure before you change anything. The rules live in [`AGENTS.md`](../AGENTS.md), the how-tos in the playbooks and the reasons in the [ADRs](adr/). Every API and command below was checked against Flutter 3.47.0 and the versions in `pubspec.lock`.

**Related:** [`state-management-guide.md`](state-management-guide.md) (MobX reactivity, reactions, store lifetimes) · [ADR-0010](adr/0010-hookwidget-default.md) · [ADR-0013](adr/0013-design-system-tokens-only.md) · [ADR-0018](adr/0018-widget-construction-discipline.md) · [ADR-0019](adr/0019-hook-selection.md) · [`DESIGN.md` §11 Motion](../DESIGN.md#11-motion) · playbooks [`create-page`](../.claude/skills/create-page/SKILL.md), [`create-store`](../.claude/skills/create-store/SKILL.md), [`create-ds-component`](../.claude/skills/create-ds-component/SKILL.md)

## Measure first

Don't judge performance in debug mode. It runs JIT code with asserts on and is several times slower than release. Profile on a physical device, ideally a mid-range Android phone. Profile mode does not run on the iOS Simulator.

```bash
flutter run --profile -t lib/main_prod.dart
flutter run --profile --trace-startup -t lib/main_prod.dart      # writes build/start_up_info.json
flutter build apk --target-platform android-arm64 --analyze-size -t lib/main_prod.dart
flutter build ipa --analyze-size -t lib/main_prod.dart
```

Profile the **prod** flavor. The dev flavor adds `MockTodosInterceptor`, which delays every `/todos` call by 300 ms, and a `LogInterceptor` that turns every response body into a string on the main isolate. Both distort network and frame numbers. Every non-debug build, including profile, also starts Sentry, tracing 20% of transactions in prod and all of them in dev ([`main.dart`](../lib/main.dart)).

A frame has 16.7 ms at 60 Hz and 8.3 ms at 120 Hz. The UI thread and the raster thread each get that budget separately.

| Tool | Where | Answers |
|---|---|---|
| Performance overlay | `P` in the `flutter run` terminal, or DevTools → Performance → **Performance Overlay** | Which frames go over budget, and on which thread (top graph: raster, bottom: UI) |
| Frame chart | DevTools → Performance → select a frame → **Frame Analysis**, **Timeline Events** | What ran in that frame |
| Build, layout, paint events | Performance → **Enhance Tracing** → **Trace widget builds** / **Trace layouts** / **Trace paints** (the `debugProfileBuildsEnabled` family) | Which widgets built, laid out or painted in a frame |
| Rebuild counts | Performance → **Rebuild Stats** → **Count widget builds**. Debug mode only, so read the counts as relative | Which widget rebuilds more than its data changes |
| Raster cost | Performance → **More debugging options** → **Render Clip layers** / **Render Opacity layers** / **Render Physical Shape layers**, **Highlight Oversized Images** | Whether clips, opacity, shadows or oversized images cost the frame |
| CPU | DevTools → **CPU Profiler** → **Record**, reproduce the problem, stop, then read bottom-up | Dart hot spots: parsing, sorting, `fromJson` |
| Memory | DevTools → Memory → **Profile Memory**, **Diff Snapshots**, **Trace Instances** | What grew between two snapshots, and who allocates a class |
| Network | DevTools → **Network** | Duplicate requests, payload sizes, timings |
| Console, no DevTools | `debugPrintRebuildDirtyWidgets = true`, `debugRepaintRainbowEnabled = true` (debug) | Every rebuild and every repaint as it happens |

`--analyze-size` prints the path of a JSON file. Open it in DevTools → **App Size**. It cannot be combined with `--split-debug-info`. For leaks in widget tests, enable `LeakTesting.enable()` from `leak_tracker_flutter_testing` in a `test/flutter_test_config.dart`. That package is not a direct dev dependency yet.

## Rebuild scope

An `Observer` rebuilds when any observable it read during its last build changes, and everything inside its builder rebuilds with it. Scope rebuilds to the data each subtree reads. The MobX side of this (what counts as a read, `@computed`, why an `Observer` does not fire) is in [`state-management-guide.md`](state-management-guide.md#observer-placement).

- **Small `Observer`s, placed low.** Don't read observables at the page root and pass values down. The widget that shows the value observes it:

  ```dart
  class _DoneCount extends StatelessWidget {
    const _DoneCount();

    @override
    Widget build(BuildContext context) {
      final state = context.read<HomePageState>();
      return Observer(
        builder: (_) => AnimatedCount(
          value: state.doneCount,
          style: GeistTextStyles.bodyM.copyWith(color: context.geist.ink),
        ),
      );
    }
  }
  ```

- **Real widget classes with `const` constructors** ([ADR-0018](adr/0018-widget-construction-discipline.md)). A `const` child, or a child instance passed in from above, is skipped when its parent rebuilds. `PressScale` rebuilds on every press, but the `child` it was given does not.
- **`useValueNotifier` when only part of a widget reads a value** ([ADR-0019](adr/0019-hook-selection.md)). The Home FAB used `useState` from a scroll listener, which rebuilt the app bar, the filter bar and the list on every change of scroll direction. Now only the FAB rebuilds:

  ```dart
  final fabVisible = useValueNotifier(true); // not useState
  // ...
  floatingActionButton: ValueListenableBuilder<bool>(
    valueListenable: fabVisible,
    builder: (_, visible, _) =>
        _NewTodoFab(visible: visible, onPressed: state.onAddTodoPressed),
  ),
  ```

- **`AnimatedBuilder` and `ValueListenableBuilder` take a `child`.** Build the static part once and pass it in, the way `_Wordmark` in `login_page.dart` does. Otherwise it is rebuilt on every tick.
- **`RepaintBoundary` around a small animation that runs next to static content**, so the static content is not repainted with it. Check the result with **Highlight Repaints**, because a boundary around something that changes together with its parent only adds a layer.
- **Rows that can be removed, inserted or re-filtered** need `ValueKey(item.id)` on the widget the builder returns, plus an index callback. Without one, Flutter matches rows by position: each moved row is rebuilt from scratch, loses its state and replays its entry animation. On Flutter 3.47 it is `findItemIndexCallback` on `ListView.separated` / `SliverList.separated` (`findChildIndexCallback` is deprecated there) and `findChildIndexCallback` on `.builder`. The full pattern is in [`create-page`](../.claude/skills/create-page/SKILL.md#lists-whose-rows-are-removed-or-inserted):

  ```dart
  findItemIndexCallback: (key) {
    final index = todos.indexWhere((todo) => ValueKey(todo.id) == key);
    return index == -1 ? null : index;
  },
  ```

## Work in `build()`

`build()` runs whenever an ancestor, an inherited widget or an observable changes, and on every frame of a rebuild-driven animation. Don't parse, sort, filter, group, format dates or compile a `RegExp` inside it.

- **Derived data from a store** is a `@computed` on the store or page state. It is cached while observed and recomputed only when its inputs change ([`create-store`](../.claude/skills/create-store/SKILL.md#search-and-filtering)). `HomePageState`:

  ```dart
  @computed
  List<TodoDto> get visibleTodos =>
      _homeStore.todos.where(_filter.matches).toList();

  @computed
  int get doneCount => _homeStore.todos.where((todo) => todo.completed).length;
  ```

- **Widget-local derived values** go in `useMemoized` with a complete key list. **`DateFormat` and `NumberFormat`** parse their pattern and load locale data when they are constructed. Create one per locale, not one per row per frame. For locales other than `en`, call intl's `initializeDateFormatting()` once at startup.

  ```dart
  final locale = context.locale.toLanguageTag();
  final format = useMemoized(() => DateFormat.yMMMd(locale), [locale]);
  ```

## Lists and scrolling

- **Lazy builders only.** Use `ListView.builder`, `SliverList.builder` or `.separated`, all inside one `CustomScrollView` when a page mixes headers and lists. Never put a long list in a `Column` inside a `SingleChildScrollView`: that builds and lays out every row up front. For the same reason, never nest a `shrinkWrap: true` list inside another scroll view; make both slivers of one `CustomScrollView`.
- **Fixed-height rows:** set `itemExtent` or `prototypeItem` on `ListView`, or use `SliverFixedExtentList.builder` / `SliverVariedExtentList.builder`. The viewport can then work out scroll offsets without laying out rows, which matters for jumps and scrollbar drags.
- **Paginate** anything the server can grow. The store rules (re-entry guard, advance the page only on success, drop late pages after a refresh) are in [`create-store`](../.claude/skills/create-store/SKILL.md#pagination).
- **Keep-alive has a cost.** `useAutomaticKeepAlive()` keeps an off-screen element, with its controllers and images, in memory. Use it for tab pages with scroll position or form state, not for list rows.
- **Rows are disposed once they scroll out of the cache extent** and rebuilt when they come back. Anything a row does on mount (an entry animation, a fetch) runs again.

## Images

A decoded image costs `width × height × 4` bytes regardless of the size it is drawn at, so a 12 MP photo is about 46 MB. Decode at the drawn size times the device pixel ratio.

- `Image.asset` / `Image.network` / generated `Assets.*.image()` take `cacheWidth` / `cacheHeight`. `ExtendedImage.network` takes the same parameters, plus `compressionRatio` and `maxBytes`.
- Set **one** dimension to keep the aspect ratio: the one the layout fixes. With `BoxFit.cover`, an image whose aspect ratio is far from the box's can look soft. Decode at the box's longer side in that case.
- The design system's [`ImageWidget`](../packages/design_system/lib/src/components/src/images/src/image_widget.dart) decodes at full resolution today. Fixed:

  ```dart
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return LayoutBuilder(
    builder: (context, constraints) {
      return ExtendedImage.network(
        image,
        // Decode at the drawn size. One dimension keeps the aspect ratio.
        cacheWidth: constraints.hasBoundedWidth
            ? (constraints.maxWidth * dpr).round()
            : null,
        timeRetry: const Duration(seconds: 2),
        fit: BoxFit.cover,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        shape: shape,
        border: border,
        borderRadius: borderRadius,
      );
    },
  );
  ```

- **Caching.** `ExtendedImage.network(cache: true)` (the default) caches bytes on disk. Decoded images go to Flutter's `ImageCache`, which holds up to 1000 images or 100 MB. For a one-off large image such as a full-screen viewer, pass `clearMemoryCacheWhenDispose: true`. **Placeholders:** give the image box a fixed size so the layout does not jump when the image arrives, and use `loadStateChanged` for the loading and failed states.
- **SVG** is parsed and tessellated on first paint. Icons ship as PNG at 1.5x–4x, and that is the cheaper choice for small, static assets. Note that the design system's `flutter_gen` config enables the `flutter_svg` integration, but the package is not a dependency.
- **Precache above-the-fold assets** so they do not pop in on the first frame: `useEffect(() { unawaited(precacheImage(Assets.icons.user.provider(), context)); return null; }, const [])`.

## Animations and motion

- **Tokens and primitives.** Durations come from `GeistDuration.fast/base/slow/breathe`, curves follow [`DESIGN.md` §11](../DESIGN.md#11-motion), and [`geist_motion.dart`](../lib/core/ui/geist_motion.dart) provides `PressScale`, `FadeSlideIn`, `AnimatedCount` and `geistReducedMotion`.
- **Implicit first.** `AnimatedOpacity`, `AnimatedSlide` and `AnimatedScale` can be interrupted and need no controller. For an explicit one, use `useAnimationController`, which disposes it for you.
- **Animate transform and opacity, not layout.** `FadeTransition`, `SlideTransition`, `ScaleTransition` and `Transform` skip layout. Animating a size, padding or `FractionallySizedBox.widthFactor` re-lays out the subtree on every frame. An animated `BoxShadow` blur repaints on every frame.
- **Loops** keep the raster thread busy for as long as they are on screen. Stop them under reduced motion, and isolate them:

  ```dart
  final reduced = geistReducedMotion(context);
  final controller = useAnimationController(duration: GeistDuration.breathe);
  final opacity = useMemoized(
    () => Tween<double>(begin: 0.4, end: 1).animate(controller),
    [controller],
  );
  useEffect(() {
    if (reduced) {
      controller.value = 1;
    } else {
      unawaited(controller.repeat(reverse: true));
    }
    return null;
  }, [reduced]);

  return RepaintBoundary(
    child: FadeTransition(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.geist.focusBlue, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 6),
      ),
    ),
  );
  ```

- **Skeletons shimmer only while loading.** `Skeletonizer(enabled: isLoading, child: realLayout)` paints its effect on every frame while enabled, so the skeleton must leave the tree when data arrives. It never settles, which is why widget tests use the bounded `settleFrames()` in [`pump_app.dart`](../test/helpers/pump_app.dart) instead of `pumpAndSettle` ([`troubleshooting.md`](troubleshooting.md)).
- **Stagger** at most four items, per `DESIGN.md`. A staggered entry on every list row costs a controller and a timer per row, and it replays on scroll.

## Async work and isolates

- **Dio already decodes large bodies off the main isolate.** Its default `FusedTransformer` JSON-decodes any response of 50 KB or more in a background isolate. The `fromJson` into freezed DTOs in Retrofit's generated code still runs on the main isolate. When the CPU profiler shows mapping over a frame budget (typically thousands of DTOs), use `@RestApi(parser: Parser.FlutterCompute)` with top-level `deserializeX` functions, or `Isolate.run` for local work such as a large asset or file. Below that size, spawning an isolate and copying the input costs more than it saves.
- **Debounce input** that triggers work: `useDebouncedCallback` ([ADR-0019](adr/0019-hook-selection.md)) in the widget, or `debounceReaction` on a store query. The window is a named `Duration` constant.
- **Cancel stale requests.** A newer query makes the in-flight one useless. `IssueTrackingService.isCancellation` keeps a cancelled request out of Sentry and out of the notice ([`error-handling-guidelines.md`](error-handling-guidelines.md), [`issue_tracking_service.dart`](../lib/core/services/issue_tracking_service.dart)), but your `catch` still runs, so it must not set the error state. `searchTodos` below is illustrative. Declare it with a `@CancelRequest() CancelToken? cancelToken` parameter.

  ```dart
  @action
  Future<void> search(String query) async {
    _inFlight?.cancel(); // the previous query is stale
    final token = CancelToken();
    _inFlight = token;
    try {
      final todos = await _dioService.todosProvider.searchTodos(query, cancelToken: token);
      _results = ObservableList.of(todos);
      _error = null;
    } catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(e, stackTrace: stackTrace, handlingContext: 'search_todos');
      // Not reported, no notice — but this catch still runs.
      if (!IssueTrackingService.isCancellation(e)) {
        _error = e is DioException ? e.message : e.toString();
      }
    }
  }
  ```

- **No fire-and-forget work in hot paths.** Don't start a future from `build()`, a scroll listener or an `Observer` builder. When a future is deliberately not awaited, wrap it in `unawaited(...)`, and cancel timers in the `useEffect` cleanup. `Future.delayed` cannot be cancelled, which is why `FadeSlideIn` waits with a `Timer`.

## Memory and leaks

- **Controllers:** the `use*Controller` hooks dispose what they create. Anything built with `useMemoized` needs a disposing `useEffect` ([ADR-0019](adr/0019-hook-selection.md)).
- **Subscriptions, timers and reactions:** every `listen` has a `cancel`, every `Timer` a `cancel`, every `ReactionDisposer` a call. Disposal rules and store lifetimes are in [`state-management-guide.md`](state-management-guide.md#lifetimes-and-ownership). A periodic timer that is never cancelled also drains the battery.
- **No `BuildContext` in long-lived objects** ([ADR-0018](adr/0018-widget-construction-discipline.md)). A context held by a singleton keeps a disposed route's element tree alive. `AppNavigator` reaches the navigator through its key instead.
- **Singletons live for the whole process.** Everything a `@singleton` store holds, such as `HomeStore.todos`, stays in memory until `resetDependencies()` runs on logout. Keep screen data in `@injectable` stores, and never dispose an injected singleton from a screen.

## Startup

Before the first frame, in order ([`main.dart`](../lib/main.dart)):

1. `SystemChrome.setPreferredOrientations` (a platform-channel round trip), then `EasyLocalization.ensureInitialized()` (reads `SharedPreferences`).
2. `registerGetIt` → `configureDependencies`. **Every `@singleton` is constructed here** ([`injectable.config.dart`](../lib/injectable.config.dart)): `FlavorService`, `NotificationsStore`, `AuthStore`, `AppNavigator` (builds `AppRouter`), `HomeStore` and `ConnectivityStore` (starts a connectivity check). `HomeStore` needs `DioService`, so that `@lazySingleton` and both of its `Dio` clients are built eagerly too.
3. Release and profile builds only: `await SentryFlutter.init(...)`. This stays before `runApp` so startup crashes are captured.
4. `runApp`. Until the easy_localization delegate has loaded `assets/translations/en-US.json`, `Localizations` renders nothing. Then `SplashRoute` shows, and `SplashPageState` reads the stored token and replaces it with Home or Login.

- **`@singleton` only for what the first frame needs.** Everything else is `@lazySingleton` (built on first use; `@LazySingleton(dispose: …)` exists too) or `@injectable`. A `@singleton` that depends on a `@lazySingleton` makes it eager.
- **Defer work the first frame does not need**, such as store version checks, notification setup and analytics:

  ```dart
  // Not needed for the first frame: start it after that frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(getIt<AppUpdateService>().checkAppVersion());
  });
  ```

- **Splash.** `ios/` and `android/` are generated per app, so match the native launch screen's background to `SplashPage` to hide the handoff, and never add an artificial delay. Compare `timeToFirstFrameRasterizedMicros` in `build/start_up_info.json` before and after a startup change.

## Network

- **Timeouts.** `DioService` sets 15 s to connect and 30 s to send and receive; `uploadImageDio` 15 s to connect, 120 s to send and 30 s to receive. Keep connect short: at 30 s, a user on a dead connection watches a skeleton for half a minute before the error state. New timing values are named `Duration` constants in `TimingConstants` ([ADR-0013](adr/0013-design-system-tokens-only.md)); the `DioService` values are still inline literals.
- **Payload.** Fetch what the screen shows. Paginate lists, and fetch one item by id. Response size shows in DevTools → Network.
- **Caching.** Dio has no HTTP cache here (`CacheInterceptor` is commented out). If the backend sends `ETag` or `Cache-Control`, add a caching interceptor in `DioService`. Otherwise, render the singleton store's data first and refresh in the background.
- **No refetch on rebuild.** Requests start from actions: `Provider(create:)`, a user event, a debounced reaction. Never from `build()` or an `Observer` builder, which run far more often than you expect.

## App size

- **Measure** with `--analyze-size`, then DevTools → **App Size** (see *Measure first*). Compare a build before and after adding a dependency.
- **Split debug info for release:** `flutter build apk --obfuscate --split-debug-info=build/symbols -t lib/main_prod.dart` (same flags for `ipa`). Keep the symbols. Use `flutter symbolize`, or upload them to Sentry, to read stack traces.
- **Icon fonts.** `--tree-shake-icons` is on by default for release. It fails when an `IconData` is not `const`, so keep icons `const`.
- **Fonts.** The design system ships Inter (854 KB) and Lexend (172 KB) as variable TTFs. Subset them to the scripts you ship.
- **Assets.** Compress raster assets and use WebP for photos. Declare only the directories you use.
- **Dependencies.** Unused pure-Dart packages are tree-shaken out of the binary. They still cost pub resolution and upgrade churn. An unused **plugin** still links its native code, so remove it. Check with `melos run deps:check`, and grep for the import before assuming a package is used.

## PR checklist

- [ ] Measured in profile mode on a device (prod flavor) if the PR claims a speed-up or touches a hot path
- [ ] Each `Observer` wraps only the subtree that reads its observables
- [ ] No `Widget _buildX()` methods; static subtrees are `const` or passed as `child`
- [ ] `useValueNotifier` where only part of a widget reads a value; no `useState` set from a scroll or animation listener
- [ ] Nothing parsed, sorted, filtered or formatted in `build()`; `@computed` or `useMemoized` instead
- [ ] Long lists use builders or slivers; no long `Column` in a `SingleChildScrollView`; no nested `shrinkWrap: true`
- [ ] Removable or re-filtered rows: `ValueKey(id)` plus `findItemIndexCallback` / `findChildIndexCallback`
- [ ] Network images decode at their drawn size (`cacheWidth` / `cacheHeight`)
- [ ] Animations use `GeistDuration`, animate transform or opacity rather than layout, and honour `geistReducedMotion`; loops sit in a `RepaintBoundary` and stop when data arrives
- [ ] Every controller, subscription, timer and reaction is disposed; no `BuildContext` stored
- [ ] Superseded requests are cancelled, and a cancellation does not show the error state
- [ ] New app-wide services are `@lazySingleton` unless the first frame needs them
- [ ] No new dependency without a size check; unused plugins removed

## Current state of this template

From an audit of this repo. Severity is for an app built on the template as it stands. Rows marked **Fixed** were fixed after the audit.

| Area | Current state | Impact | Recommended fix | Severity |
|---|---|---|---|---|
| Startup DI | `HomeStore` is `@singleton` and pulls `@lazySingleton DioService` into `configureDependencies` | Two `Dio` clients and their interceptors are built before `runApp`; the cost grows with every eager store | `@lazySingleton` or `@injectable` for `HomeStore` | Medium |
| Offline wrapper | `ConnectionWrapperPage` keeps the router child mounted and lays the offline page over it in a `Stack` | — | — | **Fixed** |
| Home rebuild scope | The filter is `@readonly` on `HomePageState` (**fixed**), but one `Observer` still wraps the hero, filter bar and list | A filter tap or any todo change rebuilds the whole scroll view | One `Observer` each for hero, filter bar and list | Medium |
| Home work in build | `@computed visibleTodos` and `doneCount` on `HomePageState` | — | — | **Fixed** |
| Home rows | Every `_TodoCard` wraps `FadeSlideIn` with a `30 ms × index` delay (up to 300 ms); rows are keyed but have no `findItemIndexCallback` | A controller and a timer per row; the animation replays when a row scrolls back in and on every filter switch; spec says 40 ms, four items max | Animate only the first four rows on first load with a token stagger; add `findItemIndexCallback` | Medium |
| Looping repaints | `_PulsingDot` (todo details) animates a `BoxShadow` blur; login `_Wordmark` animates shadow alpha; both loop forever with no `RepaintBoundary` | The page repaints every frame while visible, which costs battery; `DESIGN.md` allows only the skeleton to loop | Remove the loops, or use `RepaintBoundary` + `FadeTransition` over a static box | Medium |
| Raw durations | `FadeSlideIn` 280 ms and `AnimatedCount` 420 ms defaults; home 600/280/240/1200 ms; details 1600 ms and stagger literals; login and add-todo staggers; `_AnimatedCheckbox` uses `Curves.easeOutBack` | Motion drifts from the tokens (ADR-0013) and the no-bounce rule | `GeistDuration.*`; add a stagger token | Low |
| Skeleton | Hand-rolled `_TodoSkeletonList`: raw 1200 ms, `Tween.animate` allocated each build; `skeletonizer` is declared but never imported | Minor cost; diverges from `DESIGN.md` and `create-page` | `Skeletonizer(enabled:)` over the real layout, or remove the dependency | Low |
| `FadeSlideIn` delay | A `Timer` cancelled in the `useEffect` cleanup | — | — | **Fixed** |
| Progress bar | `_ProgressTrack` tweens `FractionallySizedBox.widthFactor` over 600 ms | Layout on every frame of the tween (small subtree) | `Transform.scale(scaleX:)` aligned left | Low |
| Images | DS `ImageWidget` has no decode size and no placeholder (not used in `lib/` yet) | A full-resolution decode per image, about 46 MB for a 12 MP photo | `ExtendedImage.network(cacheWidth:)` as shown above | Medium |
| Timeouts | 15 s connect, 30 s send and receive; `uploadImageDio` 15 / 120 / 30 s | — | — | **Fixed** |
| Payload | `FetchTodoUseCase` downloads every todo to show one; `HomePageState.init` refetches on each Home mount | O(n) payload per details open; a duplicate request on every return to Home | `GET /todos/{id}` or read from `HomeStore`; refresh when stale | Medium |
| Unused utilities | `addInfiniteScrollListener` adds a listener that cannot be removed. (`TimerState` was deleted: **fixed**.) | Repeated page loads unless the store guards | Return a remover from the extension | Low |
| Dependencies | Never imported: `rxdart`, `faker`, `uuid`, `skeletonizer`, `flutter_gen` (runtime), `socket_io_client` and `rxdart` in `api`, `flutter_driver`. Plugins with no live caller: `path_provider` (unused `FileUtil`) and `upgrader` (`checkAppVersion` never called) | Pure-Dart packages are tree-shaken; unused plugins still add native code | Remove, or wire them up | Low |
| Sentry | `tracesSampleRate` is 0.2 in prod, 1.0 elsewhere | — | — | **Fixed** |
| Fonts | Inter 854 KB and Lexend 172 KB variable TTFs | About 1 MB of install size | Subset to the scripts in use | Low |

## More information

- [`state-management-guide.md`](state-management-guide.md) (`Observer`, `@computed`, reactions, disposal) · [ADR-0018 Widget construction discipline](adr/0018-widget-construction-discipline.md) · [ADR-0019 Hook selection](adr/0019-hook-selection.md) · [ADR-0013 Design-system tokens only](adr/0013-design-system-tokens-only.md)
- [`create-page`](../.claude/skills/create-page/SKILL.md) (lists, hooks, motion) · [`create-store`](../.claude/skills/create-store/SKILL.md) (pagination, search) · [`write-tests`](../.claude/skills/write-tests/SKILL.md#rows-keep-their-element-when-a-row-is-removed) (row identity test)
- [`DESIGN.md` §11 Motion](../DESIGN.md#11-motion) · [`troubleshooting.md`](troubleshooting.md)
- Flutter: [Performance best practices](https://docs.flutter.dev/perf/best-practices) · [DevTools performance view](https://docs.flutter.dev/tools/devtools/performance)
