---
applyTo: "src/**,app/**,server/**,internal/**,pkg/**"
---
- Handlers stay thin: validate input, call a service, map the result. Business rules live in Domain.
- Parameterized queries only. Every new endpoint documents auth, input limits, errors and idempotency in the spec.
- Never run migrations or destructive scripts against shared or production databases.
- Log without PII or secrets; include a request id.
