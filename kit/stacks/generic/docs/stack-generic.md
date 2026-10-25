# Project notes (generic stack)

Fill this in for your kind of project. Keep it short; delete what does not apply.

## Run
How to build, test and lint. Wire them in `harness/stacks/generic.env`.

## Make it verifiable
- What is the cheapest honest check an agent can run in seconds? Make that `BUILD_CMD` or `LINT_CMD`.
- What proves the thing really works? (A plan against a sandbox account, a pipeline run on sample data, a model eval above a threshold, a boot on a simulator.) Make it `E2E_CMD`.
- Fixtures, sandboxes and test accounts that are safe to use. Never production.

## Evaluator protocol
1. Stand up the real system in a safe environment.
2. For each scenario or acceptance criterion, perform it for real and save evidence to `<change-dir>/evidence/` (command transcripts, plans, output samples, screenshots, metrics).
3. List risky probes specific to this project (data volume, failure injection, rollback, cost).

## Pitfalls agents hit here
Add real ones as they happen, and log them in docs/lessons.md.
