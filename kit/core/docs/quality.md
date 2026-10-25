# Quality bar and definition of done

A task is done only when all of these are true:
- [ ] `scripts/harness/verify.sh` passes (arch-lint, lint, build, unit tests).
- [ ] The test for each scenario or criterion failed before the change and passes after.
- [ ] No new warnings, no disabled lints, no skipped tests.
- [ ] User-facing text is localizable, interactive elements have accessible labels and test identifiers.
- [ ] Errors are handled and shown or logged per ARCHITECTURE.md. No silent catches.
- [ ] No secrets, no debug flags, no TODOs without an issue link.
- [ ] Docs touched by the change are updated in the same PR.

A change is done only when additionally:
- [ ] If the project uses specs (`SPEC_MODE` is `openspec` or `native` in `harness/harness.conf`): `review.md` ends with `VERDICT: APPROVE`.
- [ ] `verification.md` ends with `RESULT: PASS` and has evidence.
- [ ] `verify.sh --e2e` passes.
- [ ] A human has read the diff.

Keep this list short. Anything that can be checked by a script belongs in a script, not here.
