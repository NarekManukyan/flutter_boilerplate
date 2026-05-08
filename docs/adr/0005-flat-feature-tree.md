# 5. Flat Feature Tree (No Nested `features/`)

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

A feature can grow sub-modules — for example, a meeting feature may sprout an AI-chat sub-module with its own store, state, and view. The shortest path to organize that is a nested `features/` directory inside the parent feature. Done repeatedly, the tree becomes a recursive maze where the same naming patterns appear at multiple depths and DI scoping becomes unclear.

We need a rule that says *features are peers*, not parents and children.

## Decision Drivers

- Predictable depth — `lib/features/{feature}/{layer}/...` is a known shape; deeper nesting breaks tooling expectations and grep paths.
- DI clarity — feature scoping is one level deep; nesting forces sub-feature DI scopes nobody actually configures.
- Discoverability — top-level `lib/features/` listing should surface every feature.

## Considered Options

- **Flat — features are peers under a domain grouping**.
- **Nested — `features/` allowed inside any feature**.
- **Domain folders without `features/`** — `lib/meetings/{ai_chat,details}/` without a `features/` parent at all.

## Decision Outcome

Chosen option: **Flat — features are peers under a domain grouping**.

```
# ❌ Wrong — nested features
lib/features/meetings/meeting_details/features/ai_chat/

# ✅ Correct — peer features
lib/features/meetings/ai_chat/
lib/features/meetings/meeting_details/
```

A feature with its own store/state/view is a feature, not a sub-module. Promote it to a sibling under the domain grouping.

Pure view-layer sub-pages (no store, no state class) may remain under the parent's `view/` — for example, `meeting_details/view/share_meeting/` is fine because it has no MobX class of its own.

This codebase's current features are already flat: [`lib/features/`](../../lib/features/) holds `app`, `auth`, `challenges`, `home`, `splash`, `todo_details` as peers. Modals nest inside their owning feature (`home/modals/add_todo_modal/`), but a *modal* is not a feature — it has no route, no router config, and no top-level entry.

### Consequences

- Good: every feature appears at one known depth; tooling and search paths stay shallow.
- Good: no ambiguity over which DI scope a class belongs to.
- Good: refactor "is this a feature?" answered by directory location, not annotation.
- Bad: closely related sub-modules sit as siblings instead of nesting visually.
- Bad: domain grouping can grow wide (many peers under `meetings/`) before someone splits the domain.

## Pros and Cons of the Options

### Flat
- Good: one shape, predictable depth.
- Bad: wider directories at the domain level.

### Nested `features/`
- Good: visual grouping of parent + children.
- Bad: recursive structure; same names recur at multiple depths.
- Bad: DI scopes for "child features" are never actually wired.

### Domain folders without `features/`
- Good: shorter paths.
- Bad: mixes app-level and feature-level conventions; no single place to enumerate features.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0006 Feature-owned singletons](0006-feature-owned-singletons.md)
