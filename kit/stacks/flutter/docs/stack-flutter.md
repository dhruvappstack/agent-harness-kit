# Flutter stack notes

## Run
`scripts/harness/verify.sh --fast` analyzes and bundles. Unit and widget tests: `flutter test`. Integration tests need a device.

## Make the app testable
- `Key('screen.element')` or `Semantics(identifier: ...)` on every interactive widget, plus semantic labels.
- A way to launch into a known state: a `--dart-define=ENV=test` flag that seeds fixtures and swaps in fake repositories.
- Golden tests for key screens with fixed data, fonts and surface size.

## Evaluator protocol
1. Boot a simulator or emulator, `flutter run --dart-define=ENV=test`.
2. Observe: `flutter screenshot`, or platform tools (`xcrun simctl io booted screenshot`, `adb exec-out screencap -p`) into `<change-dir>/evidence/`; widget tree via Flutter DevTools or Maestro `hierarchy`.
3. Drive with `integration_test` or Maestro flows using keys and semantics.
4. Check: both platforms when user-facing, dark mode, large text scale, TalkBack and VoiceOver labels, rotation, offline.

## Pitfalls agents hit here
- Business logic inside widgets; `setState` sprawl instead of the project's state management.
- Unawaited futures and using `BuildContext` across async gaps.
- Forgetting `pubspec.yaml` asset or dependency updates, then only running analyze.
