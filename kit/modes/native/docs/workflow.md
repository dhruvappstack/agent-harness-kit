# Workflow: native spec-driven (no external tooling)

A lightweight spec-driven flow in plain markdown. Each change is a folder in `specs/changes/<name>/`; finished changes move to `specs/archive/`; accepted requirements are merged into `specs/current/`. Mode is set in `harness/harness.conf` (`SPEC_MODE=native`). To adopt OpenSpec later, set `SPEC_MODE=openspec` and migrate; the roles and gates stay the same.

## Pipeline

| # | Step | Who | Output | Gate |
|---|------|-----|--------|------|
| 1 | Scaffold | `scripts/harness/change.sh new <name>` | folder with templates | none |
| 2 | Plan | planner agent (or you) | `proposal.md`, `spec.md`, `design.md` | none |
| 3 | Plan review | plan-reviewer, fresh context, ideally a different model | `review.md` ending in `VERDICT: APPROVE` or `VERDICT: REVISE` | needs APPROVE |
| 4 | Test plan and tasks | planner | `test-plan.md`, `tasks.md` | `check-change.sh <name> --stage plan` |
| 5 | Human plan approval | you | go / no-go | you |
| 6 | Implement | implementer role | code + tests, tasks ticked | `verify.sh --fast` per task group, `verify.sh` at end |
| 7 | Evaluate | evaluator role | `verification.md` ending in `RESULT: PASS` or `RESULT: FAIL`, plus `evidence/` | `verify.sh --e2e`, `check-change.sh <name> --stage done` |
| 8 | Code review | code-reviewer role | severity-ranked findings | findings fixed or triaged |
| 9 | Human PR review | you | approval | branch protection |
| 10 | Archive | `scripts/harness/change.sh archive <name>` | moved to `specs/archive/` | done gate |

Why separate roles: an agent grades its own work too leniently. A separate evaluator and reviewer with their own context and a written rubric is easier to make skeptical than the author is to make self-critical.

## Tiers: do not over-process small work
- Tier 0 (typo, copy, config, dependency bump): normal PR labelled `no-spec`. `verify.sh` still runs.
- Tier 1 (bug fix, small refactor): `change.sh new <name> --no-spec` for behaviour-neutral work. A bug fix that restores specified behaviour needs a regression test, not a new spec.
- Tier 2 (new or changed behaviour): the full pipeline.
- Tier 3 (data migration, auth, payments, permissions, release config): full pipeline plus a second human reviewer. Agents never run production migrations or releases.

## Invoking each role
- Claude Code: `/harness:review-plan <change>`, `/harness:evaluate <change>`, `/harness:review-code <change>`, or the subagents in `.claude/agents/`.
- Copilot: prompt files `/harness-review-plan`, `/harness-evaluate`, `/harness-review-code`, or the custom agents in `.github/agents/`.
- Any other agent: point it at `harness/roles/<role>.md`.
Role instructions live only in `harness/roles/`; the tool wrappers just point there. Edit the roles to fit your team.

## Long-running or multi-session work
Agents lose context between sessions. Keep state in files, not chat: the task checklist (`tasks.md` or `notes.md`) is the progress ledger and `notes.md` in the change folder holds handoff notes (what is done, what is next, traps). A fresh session starts by reading those.

## When an agent gets something wrong
Do not just fix the code. Ask what the harness was missing and add one of: an arch-lint rule, a test, a line in a stack doc, a planning rule. Record it in `docs/lessons.md`. This is how the harness gets better over time.

