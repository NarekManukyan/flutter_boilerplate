# 1. Layered Architecture with Adjacent-Only Access

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

A Flutter app mixes presentation, business logic, navigation, persistence, and HTTP concerns. Without a clear seam between them, widgets reach into HTTP clients, business logic embeds widgets, and tests devolve into integration setups.

This boilerplate must give every feature a predictable shape so reviewers know where a change belongs and tests can mock at the seam closest to the unit under test.

## Decision Drivers

- Reviewability — a reader should know which layer is responsible for a behavior in seconds.
- Testability — UI tests should not require HTTP mocking; store tests should not require widget pumping.
- Replaceability — swap HTTP client, swap navigation lib, swap state lib, without rewriting feature code.
- Existing convention — the codebase already follows this layout; the ADR codifies it.

## Considered Options

- **Layered with adjacent-only access** (UI → State → Store → DioService → API Provider). Each layer talks only to its immediate neighbor.
- **Hexagonal / ports-and-adapters**. Domain core plus inward-pointing adapters for UI, HTTP, persistence.
- **Flat / pragmatic**. Widgets call API providers directly, no intermediate state class.

## Decision Outcome

Chosen option: **Layered with adjacent-only access**.

The contract:

```
UI (page/widget) → State (*_state.dart) → Store (*_store.dart) → DioService → API Provider
                                       ↘ Use Case ↗
```

Hard rules:

- UI never touches `DioService` or stores directly. UI reads its `*_state.dart` via `context.read<T>()`.
- State has no direct API access. It calls stores or use cases.
- Stores own API access via `DioService` and may collaborate with other stores.
- Use cases (`*_use_case.dart`) are an orthogonal seam between State/Store and services — they encapsulate one operation and may be invoked from State, Store, or a modal state per [ADR-0004](0004-use-case-taxonomy-and-colocation.md).

### Consequences

- Good: each layer has a single allowed downstream collaborator type, so dependency graphs stay shallow.
- Good: tests target one layer at a time. State tests fake stores; store tests fake `DioService`.
- Good: swapping HTTP, navigation, or state library is layer-local.
- Bad: extra indirection for trivial features — a page that lists static data still gets a state class.
- Bad: developers learning the codebase must internalize five layer roles before shipping.

## Pros and Cons of the Options

### Layered with adjacent-only access
- Good: matches existing code; predictable for review.
- Good: clean unit-test seams.
- Bad: ceremony for trivial screens.

### Hexagonal / ports-and-adapters
- Good: maximum decoupling of domain from frameworks.
- Bad: overkill for a Flutter UI app — domain logic is thin, most code is presentation + IO.
- Bad: introduces ports/adapters/domain entities that duplicate DTOs.

### Flat / pragmatic
- Good: fastest to write a screen.
- Bad: widgets become untestable without HTTP setup.
- Bad: business logic spreads across `build()` methods and ad-hoc helpers.

## Links

- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0003 No use-case → use-case dependencies](0003-no-use-case-to-use-case-dependencies.md)
- [ADR-0004 Use case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- Code: [lib/core/services/dio_service.dart](../../lib/core/services/dio_service.dart), [packages/api](../../packages/api)
