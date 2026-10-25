# Library / SDK / CLI stack notes

## Run
Wire `make build test lint e2e` (or direct commands) in `harness/stacks/library.env`.

## Make it testable
- The public API is the contract: list it in the spec, keep it in one place, and check it mechanically (api-extractor, apidiff, japicmp, cargo-semver-checks, or a snapshot of the exported symbols).
- `examples/` that compile and run in CI. They double as E2E.
- Deterministic output for CLIs: stable ordering, no timestamps unless asked, exit codes documented.

## Evaluator protocol
1. Build the artifact the way a consumer gets it (package, wheel, binary), install it into a scratch project outside the repo.
2. For each scenario run the real call or command, save the transcript to `<change-dir>/evidence/`; check outputs, exit codes and error messages.
3. Probe: invalid input, empty input, very large input, concurrent use, unsupported platforms, upgrade from the previous version.
4. Compare the public API to the last release; any breaking change must be in the spec and the changelog.

## Pitfalls agents hit here
- Breaking the public API while "just refactoring"; leaking internal types.
- Adding dependencies for trivial utilities.
- Missing changelog or version bump when behaviour changes.
