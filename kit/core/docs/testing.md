# Testing

## Levels (use the lowest level that can prove the behaviour)
1. Unit: pure logic, fast, no I/O. Runs in `verify.sh`.
2. Integration / contract: real database or real serialization, fake network edges. Runs in `verify.sh` where cheap.
3. UI / component / snapshot: renders real views with fixed data.
4. E2E: real app or real service, scripted flows (Maestro, Playwright, API suite). Runs in `verify.sh --e2e`.
5. Evaluator: agent drives the real app or service and judges against the scenarios or acceptance criteria. Not a replacement for 1 to 4; it finds what scripted tests miss.

## Rules
- Every spec scenario (or, without specs, every acceptance criterion) maps to a named test, recorded in the change's `test-plan.md` or in the PR description. Nothing is left without a test or an explicit evaluator check.
- Write the failing test first, see it fail for the right reason, then implement. Record red and green in the test-plan ledger when one exists.
- Deterministic by default: fixed clock, fixed locale, seeded data, no real network, no sleeps. A flaky test is a bug in the harness; fix or quarantine it with an issue, never retry it into green.
- Make the app testable: stable identifiers on every interactive element (accessibility id, `testID`, `data-testid`), a way to launch into a known state (launch argument, deep link, seed endpoint), and a way to stub the network.
- Tests assert observable behaviour, not implementation details or log lines.

## Fixtures and launch state
(Fill in: how to seed data, how to reset state, test accounts that are safe to use. Never use production credentials.)
