# 5. Flat Feature Tree (No Nested `features/`)

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

A feature can grow sub-modules — for example, a todo details feature may sprout a comments sub-module with its own store, state, and view. The shortest path to organize that is a nested `features/` directory inside the parent feature. Done repeatedly, the tree becomes a recursive maze where the same naming patterns appear at multiple depths and DI scoping becomes unclear.

We need a rule that says *features are peers*, not parents and children.

## Decision Drivers

- Predictable depth — `lib/features/{domain}/{feature}/{layer}/...` is a known shape; deeper nesting breaks tooling expectations and grep paths.
- DI clarity — feature scoping is one level deep; nesting forces sub-feature DI scopes nobody actually configures.
- Discoverability — top-level `lib/features/` listing should surface every feature or domain group.
- Cohesion — related features should still be visibly grouped once there are many of them.
- Explicit reuse — when one feature uses another, the dependency should show up in DI and imports, not be implied by a parent directory.

## Considered Options

- **Flat — features are peers under a domain grouping**.
- **Nested — `features/` allowed inside any feature**.
- **Domain folders without `features/`** — `lib/todos/{comments,todo_details}/` without a `features/` parent at all.
- **No domain grouping** — every feature is a direct child of `lib/features/`, in one flat list, however many features there are.

## Decision Outcome

Chosen option: **Flat — features are peers under a domain grouping**.

```
# ❌ Wrong — nested features
lib/features/todos/todo_details/features/comments/

# ✅ Correct — peer features
lib/features/todos/comments/
lib/features/todos/todo_details/
lib/features/todos/todo_list/
```

Maximum depth is `lib/features/{domain}/{feature}/{layer}/`. Below the layer directory only that layer's own structure follows, such as `view/use_cases/` or `modals/{modal}/use_cases/` from [ADR-0004](0004-use-case-taxonomy-and-colocation.md). No feature contains a `features/` directory.

The `{domain}` level groups related peer features. A feature with no related siblings sits directly under `lib/features/`, and the `{domain}` level is omitted for it. Paths written as `lib/features/{feature}/` in other ADRs and playbooks refer to the feature directory at whichever of the two depths it lives.

A sub-module becomes a peer feature when it has its own store, state and view. Move it to a sibling under the domain grouping. A purely view-layer sub-page with no store may stay under the parent's `view/`, even if it has its own page state. [`challenges/view/challenge_joined/`](../../lib/features/challenges/view/challenge_joined/) is an example: a page and its state, with no store.

Sibling features reuse each other only explicitly, through DI and shared stores: a feature injects the sibling's store, or calls a use case promoted per ADR-0004. Sitting under the same domain folder grants no implicit access.

This codebase's current features are already flat: [`lib/features/`](../../lib/features/) holds `app`, `auth`, `challenges`, `home`, `splash`, `todo_details` as peers, none of them grouped under a domain yet. Modals nest inside their owning feature (`home/modals/add_todo_modal/`), but a *modal* is not a feature — it has no route, no router config, and no top-level entry.

### Consequences

- Good: every feature appears at one of two known depths, and nothing goes deeper than `lib/features/{domain}/{feature}/{layer}/`; tooling and search paths stay shallow.
- Good: no ambiguity over which DI scope a class belongs to.
- Good: refactor "is this a feature?" answered by directory location, not annotation.
- Good: promoting a sub-module to a peer feature is a directory move, not a structural change.
- Bad: closely related sub-modules sit as siblings instead of nesting visually.
- Bad: domain grouping can grow wide (many peers under one domain) before someone splits the domain.
- Bad: siblings that share concerns must wire that reuse explicitly through DI and shared stores. This is intended, but it is more setup than reaching into a parent directory.

## Pros and Cons of the Options

### Flat
- Good: one shape, predictable depth.
- Good: a clear promotion rule, since a sub-module with its own store, state and view is a peer feature.
- Bad: wider directories at the domain level.
- Bad: needs judgment on when a set of features deserves a domain folder.

### Nested `features/`
- Good: visual grouping of parent + children.
- Bad: recursive structure; same names recur at multiple depths.
- Bad: DI scopes for "child features" are never actually wired.
- Bad: reorganizing a parent breaks import paths in every child.

### Domain folders without `features/`
- Good: shorter paths.
- Bad: mixes app-level and feature-level conventions; no single place to enumerate features.

### No domain grouping
- Good: simplest; one listing shows every feature.
- Bad: at 50+ features `lib/features/` becomes a single flat list, and related features (a list, its details page, its comments) scatter alphabetically and lose cohesion.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0004 Use case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0006 Feature-owned singletons](0006-feature-owned-singletons.md)
