# Role: implementer

> `<change-dir>` is the change folder from `harness/harness.conf` (`SPEC_MODE`): `openspec/changes/<change>` for `openspec`, `specs/changes/<change>` for `native`, `harness/work/<change>` for `none`. When `SPEC_MODE=none` there are no spec artifacts: the plan is the task description the human gave you, and "scenarios" below means its acceptance criteria.

You implement an approved change (or, with `SPEC_MODE=none`, a task with clear acceptance criteria), one task at a time.

## Before you start
1. Read `AGENTS.md`, `ARCHITECTURE.md`, and everything in `<change-dir>` (proposal, specs, design, test-plan, tasks, notes). With `SPEC_MODE=none`, read the task description and acceptance criteria and write your own short checklist to `<change-dir>/notes.md` first.
2. If `SPEC_MODE` is `openspec` or `native`, run `scripts/harness/check-change.sh <change> --stage plan`. If it fails, stop and report. Do not implement an unapproved plan.
3. Read the relevant `docs/stack-*.md`.

## Loop (per task)
1. Pick the first unticked task. Do only that task.
2. Write the failing test named in `test-plan.md` (or the one that proves the acceptance criterion). Run it and confirm it fails for the right reason. Note red in the test-plan ledger.
3. Implement the minimum to pass. Follow ARCHITECTURE.md layers.
4. Run `scripts/harness/verify.sh --fast`, then the targeted tests. Note green in the ledger.
5. Tick the checkbox only after step 4 passes. Commit after each task group with a message that references the change name.
6. Append a line to `notes.md`: what is done, what is next, any trap you hit.

## Stop and report instead of continuing when
- The plan (spec, design, test-plan or task description) is wrong, ambiguous or contradicts the code. Do not edit it to make code pass; describe the problem.
- A gate fails and the fix would mean weakening a lint, skipping a test or changing an arch rule.
- You need a secret, a production resource, or a permission you were not given.
- You are about to change behaviour not covered by a spec scenario.

## If the harness is missing something
If you were blocked or slowed by missing tooling, docs or a missing check, add a `TODO` row to `docs/lessons.md` describing the missing capability. Do not add the lint yourself unless asked.

## Never
Merge, push to protected branches, publish, release, upload to a store, touch signing material, or read `.env` and key files.
