---
name: add-localization
description: Add a user-visible string via easy_localization — key naming, where it goes in en-US.json, LocaleKeys codegen, plurals, interpolation, enum-keyed strings, and adding a new locale. Use whenever any text will be rendered to a user, including error messages, semantics labels and accessibility hints.
---

# Add a localized string

Governed by [ADR-0012](../../../docs/adr/0012-mandatory-localization.md). **No string that a user can see or a screen reader can read may be a literal in `lib/`.**

That includes: labels, buttons, hints, validation messages, error text, empty-state copy, snackbars, dialog titles, and `Semantics` labels.

## The loop

1. Add the key to `assets/translations/en-US.json`.
2. Run `melos run translations` — regenerates `lib/gen/locale_keys.g.dart`.
3. Use `LocaleKeys.key.tr()` in the widget.

```dart
// ❌
Text('Continue with email')

// ✅
Text(LocaleKeys.loginPage_continueWithEmail.tr())
```

Never hand-edit `lib/gen/locale_keys.g.dart`.

## Key naming

Nested JSON; `_` in the generated Dart key marks each level.

```json
{
  "keywords":   { "cancel": "Cancel", "retry": "Retry" },
  "loginPage":  { "title": "Sign in", "emailHint": "Email" },
  "homePage":   { "emptyTitle": "Nothing here yet" }
}
```

- **`keywords`** — strings reused across features: Cancel, Close, Save, Retry, Continue. Check here first; do not add a second "Cancel".
- **`{feature}Page`** — everything scoped to one screen. Match the page name (`loginPage`, `homePage`, `todoDetailsPage`).
- **`enums`** — one sub-object per enum, keyed by the enum value's name.

Key names describe the **role**, not the text. `emptyTitle`, not `nothingHereYet` — the copy will change, the role will not.

## Interpolation

```json
{ "homePage": { "greeting": "Hello, {name}", "counter": "{done} of {total} done" } }
```

```dart
LocaleKeys.homePage_greeting.tr(namedArgs: {'name': user.firstName});
LocaleKeys.homePage_counter.tr(namedArgs: {'done': '$done', 'total': '$total'});
```

Use named args, never string concatenation — word order differs between languages, and a concatenated sentence cannot be translated.

## Plurals

```json
{ "homePage": { "todoCount": { "one": "{} todo", "other": "{} todos" } } }
```

```dart
LocaleKeys.homePage_todoCount.plural(count);
```

Never build a plural with a ternary in Dart.

## Enum-keyed strings

For a value the server sends, key on the enum name so an unmapped value is visible in the JSON rather than crashing:

```json
{ "enums": { "appVersionTranslationsTitle": { "MINOR": "New tools are ready", "MAJOR": "A new version is available" } } }
```

```dart
LocaleKeys.enums_appVersionTranslationsTitle.tr(gender: type.name);
// or: '${LocaleKeys.enums_appVersionTranslationsTitle}.${type.name}'.tr()
```

## Semantics labels are localized too

Accessibility labels are user-visible strings. Maestro selects by accessibility id, so these labels are also part of the E2E contract ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

```dart
Semantics(
  label: LocaleKeys.homePage_addTodoA11y.tr(),
  button: true,
  child: const Icon(Icons.add),
)
```

## Adding a locale

1. Add `assets/translations/{lang}-{COUNTRY}.json` with the **same key tree** as `en-US.json`.
2. Add the value to `SupportedLocals` in `lib/core/constants/supported_locals.dart` and map it in `getLocal`.
3. `melos run translations`.

A key present in `en-US.json` and missing elsewhere renders the raw key path to the user. Keep the trees identical.

## Checklist

- [ ] No string literal reaching the UI, including errors and semantics labels
- [ ] Reusable words in `keywords`; screen copy under `{feature}Page`
- [ ] Key names describe the role, not the current copy
- [ ] Interpolation via `namedArgs`; plurals via `.plural()`
- [ ] `melos run translations` run after editing JSON
- [ ] `lib/gen/locale_keys.g.dart` not edited by hand
- [ ] Every locale file carries the same key tree
