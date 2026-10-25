# Android stack notes

## Run
`scripts/harness/verify.sh --fast` assembles and lints. Unit tests: `testDebugUnitTest`.

## Make the app testable
- `Modifier.testTag("screen.element")` (Compose) or `android:id` + content descriptions (Views) on every interactive element. Enable `testTagsAsResourceId` so Maestro and UI Automator can see tags.
- A debug-only way to launch into a known state (intent extra, debug menu, or a fake `Application` module) with seeded data and a stubbed network.
- `@Preview` for every composable with fixed data.

## Evaluator protocol
1. Start an emulator: `emulator -avd <name> -no-snapshot-save`, wait for boot (`adb wait-for-device`), `./gradlew installDebug`.
2. Observe: `adb exec-out screencap -p > <change-dir>/evidence/<name>.png`; UI tree via `adb shell uiautomator dump` or `maestro hierarchy`; logs via `adb logcat -d`.
3. Drive: Maestro flows (`.maestro/*.yaml`) or Espresso/Compose UI tests.
4. Check: dark mode, font scale 1.3 and above, TalkBack labels, rotation, process death and restore, no network.
Google's Android CLI and Android Studio agent tooling can also render previews and run journeys from the command line; use them if installed.

## Pitfalls agents hit here
- Running full `./gradlew build` for every change. Use module-scoped tasks while iterating.
- Adding dependencies without updating the version catalog.
- Blocking the main thread; leaking Activity or Context in long-lived objects.
- Hardcoded strings instead of `strings.xml`.
