---
applyTo: "src/**,lib/**,pkg/**,cmd/**,include/**"
---
- Public API changes need a spec entry, a changelog line and a compatibility check. Never export internals by accident.
- Return errors to the caller; never panic, exit or print from library code.
- Keep dependencies minimal and justified.
