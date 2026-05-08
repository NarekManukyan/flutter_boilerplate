# 12. Mandatory Localization (No Hardcoded UI Strings)

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

User-facing strings start as English literals during a feature's first iteration. If the codebase tolerates inline strings, retrofitting localization later means a sweep across hundreds of files, frequent regressions ("forgot this Snackbar"), and ad-hoc keys that don't follow any scheme.

Banning hardcoded UI strings from day one keeps the localization debt at zero.

## Decision Drivers

- Avoid retrofit cost — adding a locale shouldn't require rewriting widget files.
- Compile-time key references — typos in string keys should fail at build, not at runtime.
- Single workflow — one tool, one JSON file format, one key generator.

## Considered Options

- **`easy_localization` + `LocaleKeys` codegen, mandatory for every UI string**.
- **Hardcode strings, internationalize later**.
- **Flutter's `intl` + ARB files**.

## Decision Outcome

Chosen option: **`easy_localization` + `LocaleKeys` codegen**.

Workflow:

1. Add the string to `assets/translations/en-US.json` (add other locale files as needed). Supported locales are enumerated in [`lib/core/constants/supported_locals.dart`](../../lib/core/constants/supported_locals.dart).
2. Run `melos run translations`. This regenerates [`lib/gen/locale_keys.g.dart`](../../lib/gen/locale_keys.g.dart) — never edit this file by hand.
3. Use the generated key in UI: `Text(LocaleKeys.loginPage_title.tr())`.

Hard rule: **no inline string literals in `Text(...)`, `Snackbar`, `AppBar(title:)`, error messages, or any other user-facing surface**. Tooltips, semantic labels, modal copy — all routed through `LocaleKeys`.

```dart
// ❌ Forbidden
Text('Continue with email')

// ✅ Required
Text(LocaleKeys.loginPage_continueWithEmail.tr())
```

The bootstrap path in [`lib/main.dart`](../../lib/main.dart) calls `EasyLocalization.ensureInitialized()` before `runApp`, and [`lib/app.dart`](../../lib/app.dart) wires the `EasyLocalization` widget into the app root.

### Consequences

- Good: zero localization debt. Adding a locale is a translation task, not an engineering project.
- Good: typos in keys break the build (the generated `LocaleKeys` field doesn't exist).
- Good: every string lives in one auditable JSON file per locale.
- Bad: trivial debug strings still cost a key + codegen run.
- Bad: codegen step (`melos run translations`) is required before the keys appear, which slows down "just add a label" PRs.

## Pros and Cons of the Options

### `easy_localization` + `LocaleKeys`
- Good: typed keys; single JSON; existing wiring.
- Bad: codegen friction.

### Hardcode now, internationalize later
- Good: fastest path to ship.
- Bad: retrofit cost grows with the codebase; regressions inevitable.

### Flutter `intl` + ARB
- Good: official Flutter approach; rich plural / select syntax.
- Bad: more verbose generator setup; ARB tooling less ergonomic for non-localizers; requires migrating existing JSON content.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- Code: [lib/gen/locale_keys.g.dart](../../lib/gen/locale_keys.g.dart), [assets/translations/en-US.json](../../assets/translations/en-US.json)
