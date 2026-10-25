# iOS stack notes

## Run
`scripts/harness/verify.sh --fast` builds and lints. Unit tests run on the simulator named in `harness/stacks/ios.env`.

## Make the app testable (do this once, agents depend on it)
- `accessibilityIdentifier` on every interactive element and key label. Name them `screen.element` (for example `login.submit`).
- A launch argument such as `-UITests` that resets state, seeds fixtures, disables animations and stubs the network. Document the arguments here.
- Previews (`#Preview`) for every screen with fixed data. Agents can render and inspect them.

## Evaluator protocol
1. Boot a simulator: `xcrun simctl boot "iPhone 16"`, build and install the app, launch with the test launch arguments.
2. Observe: `xcrun simctl io booted screenshot <change-dir>/evidence/<name>.png`; UI tree via `maestro hierarchy` or the Xcode MCP / XcodeBuildMCP tools if installed.
3. Drive: Maestro flows (`.maestro/*.yaml`) or XCUITest. Prefer identifiers over coordinates.
4. Check: light and dark mode, Dynamic Type at the largest size, VoiceOver labels, background and foreground, no network.
Agents with Xcode 26.3 or later can also use Xcode's agent integration for builds, tests and previews.

## Pitfalls agents hit here
- Editing `.pbxproj` by hand. Prefer SwiftPM, Tuist or XcodeGen so project files are generated.
- Main-actor and concurrency warnings silenced instead of fixed.
- Hardcoded strings instead of the String Catalog.
- Simulator name drift between local and CI. Keep it in `ios.env` only.
