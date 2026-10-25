---
applyTo: "**/*.ts,**/*.tsx,**/*.vue,**/*.svelte,**/*.css"
---
- TypeScript strict; no `any` in domain code.
- Semantic HTML first; every interactive element has an accessible name. Add `data-testid` only when role queries are not enough.
- No raw HTML injection; no tokens in web storage.
- Tests assert user-visible behaviour, use auto-waiting assertions, and never sleep.
