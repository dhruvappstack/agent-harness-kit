---
applyTo: "**/*.ts,**/*.tsx"
---
- TypeScript strict. No `any` in domain code; no `@ts-ignore` without an issue link.
- Every interactive element gets `testID="screen.element"` and an accessibility label.
- Use the app logger, not `console.log`. Secrets go in the secure store, never AsyncStorage.
- A change that touches native modules must say how it was verified on iOS and Android.
