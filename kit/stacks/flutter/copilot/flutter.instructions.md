---
applyTo: "**/*.dart"
---
- Null-safe, strict analysis. No `print`; use the app logger. Check `mounted` after awaits before using `BuildContext`.
- Keep business logic out of widgets; follow the project's state management pattern.
- Every interactive widget gets a `Key('screen.element')` and a semantic label.
- Secrets go in secure storage, never SharedPreferences.
