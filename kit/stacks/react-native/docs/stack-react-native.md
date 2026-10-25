# React Native stack notes

## Run
`scripts/harness/verify.sh --fast` typechecks and lints; unit tests run through Jest. Ensure `typecheck`, `lint` and `test` scripts exist in `package.json`.

## Make the app testable
- `testID="screen.element"` on every interactive element, plus `accessibilityLabel`.
- A way to launch into a known state: a deep link, an env flag in a dev build, or a mock API layer (MSW or a local mock server).
- Test the JS layer with Jest and React Native Testing Library; use Maestro for real-device flows.

## Evaluator protocol
Run on both platforms when the change is user-facing.
1. Start Metro or install a dev build. iOS: boot a simulator and launch. Android: start an emulator and install.
2. Observe with the platform tools in `docs/stack-ios.md` and `docs/stack-android.md` (screenshots, hierarchy via `maestro hierarchy`).
3. Drive with Maestro flows (`.maestro/*.yaml`) using `testID`s.
4. Check: both platforms, dark mode, font scaling, keyboard avoidance, safe areas, offline, backgrounding.

## Pitfalls agents hit here
- Platform differences ignored (`Platform.OS` branches untested on one side).
- Installing native packages without running pods or syncing Gradle, then reporting success after only typechecking.
- Heavy work on the JS thread; unkeyed or unmemoized long lists.
- Mixing `any` into the domain layer to silence the typechecker.
