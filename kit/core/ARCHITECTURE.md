# ARCHITECTURE.md

Fill this in once, keep it short. Agents read it before every design.

## Layers
Dependencies point downward only. A layer may import only from layers below it.

```
UI / Presentation      screens, views, components, controllers, routes
Application / Service  use cases, view models, orchestration
Domain                 entities, business rules, pure logic (no framework imports)
Data / Infrastructure  network, database, storage, platform SDK wrappers
```

Adapt names to your stack (for example Handler -> Service -> Repository for a backend).
Machine-enforced rules live in `harness/arch-rules/*.rules`. When you add a rule here, add it there.

## Modules
| Module / package | Layer | Owns | May depend on |
|---|---|---|---|
| (fill in) | | | |

## Cross-cutting decisions
- Error handling: (fill in)
- Dependency injection: (fill in)
- Navigation / routing: (fill in)
- Persistence and migrations: (fill in)
- Feature flags / remote config: (fill in)
- Observability (logging, analytics, crash reporting): (fill in)

## Things agents get wrong here
Add one line per recurring mistake, then add a lint or test so it cannot recur. Log it in docs/lessons.md.
