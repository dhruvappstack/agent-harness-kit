# Backend stack notes

## Run
Wire `make build test lint e2e` (or direct commands) in `harness/stacks/backend.env`. `verify.sh --fast` must stay fast (seconds to a couple of minutes).

## Make the service testable
- One command to start an ephemeral stack with seeded data (for example `docker compose -f compose.test.yaml up -d`) and one to tear it down.
- An API contract (OpenAPI or schema) checked into the repo; contract tests run in E2E.
- Deterministic clock and ID generation injected, not read from globals.
- Migrations tested forward on a copy of realistic data. Agents never run migrations against shared or production databases.

## Evaluator protocol
1. Start the ephemeral stack. Seed data. Record versions.
2. For each spec scenario send the real request (curl or the test client) and save the transcript to `<change-dir>/evidence/`. Check status, body, headers, persisted state and emitted events.
3. Probe: invalid input, missing auth, wrong role, idempotent retry, concurrent requests, downstream timeout, large payload.
4. Check logs for errors and for leaked PII or secrets.

## Pitfalls agents hit here
- Business logic in handlers; raw SQL outside repositories.
- Tests that pass because the mock returns what the code expects.
- Breaking API changes without a versioning or deprecation plan in the spec.
- Missing indexes and N+1 queries on new endpoints.
