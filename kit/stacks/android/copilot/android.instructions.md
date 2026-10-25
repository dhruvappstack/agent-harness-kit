---
applyTo: "**/*.kt,**/*.java,**/*.gradle,**/*.gradle.kts"
---
- Kotlin coroutines and Flow; never block the main thread. No `!!` in app code.
- Dependencies and versions go through the version catalog (`libs.versions.toml`).
- Every interactive composable gets a `testTag("screen.element")`.
- User-facing strings come from resources, never literals.
- Prefer module-scoped Gradle tasks while iterating; run the harness verify before finishing.
