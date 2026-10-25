# Workflow: no spec artifacts

For teams that do not use specs. The task description is the plan, and its acceptance criteria are the contract. The harness still gives you independent evaluation and review, mechanical gates and the lessons ratchet. Mode is set in `harness/harness.conf` (`SPEC_MODE=none`). To grow into specs later, set `SPEC_MODE=native` or `openspec`; nothing else has to change.

## Pipeline

| # | Step | Who | Output | Gate |
|---|------|-----|--------|------|
| 1 | Define | you | task with written acceptance criteria (issue, ticket or PR description) | criteria are observable and testable |
| 2 | Plan review (risky work only) | plan-reviewer, fresh context | findings in chat ending in a `VERDICT:` line | you decide |
| 3 | Implement | implementer role, test-first, one small step at a time | code + tests, checklist in `harness/work/<name>/notes.md` | `verify.sh --fast` per step, `verify.sh` at end |
| 4 | Evaluate | evaluator role | `harness/work/<name>/verification.md` ending in `RESULT: PASS` or `RESULT: FAIL`, plus `evidence/` | `verify.sh --e2e` |
| 5 | Code review | code-reviewer role | severity-ranked findings | findings fixed or triaged |
| 6 | Human PR review | you | approval; paste or link the verification summary in the PR | branch protection |

Use `scripts/harness/check-change.sh <name> --stage done` to check that a `verification.md` says `RESULT: PASS`.

## Tiers
- Tier 0 (typo, copy, config, dependency bump): normal PR; `verify.sh` still runs.
- Tier 1 (bug fix, small refactor): steps 3, 5, 6 with a regression test.
- Tier 2 (new or changed behaviour): all steps; evaluation is not optional for user-facing changes.
- Tier 3 (data migration, auth, payments, permissions, release config): all steps plus a second human reviewer and a plan review. Agents never run production migrations or releases.

## Invoking each role
- Claude Code: `/harness:review-plan <change>`, `/harness:evaluate <change>`, `/harness:review-code <change>`, or the subagents in `.claude/agents/`.
- Copilot: prompt files `/harness-review-plan`, `/harness-evaluate`, `/harness-review-code`, or the custom agents in `.github/agents/`.
- Any other agent: point it at `harness/roles/<role>.md`.
Role instructions live only in `harness/roles/`; the tool wrappers just point there. Edit the roles to fit your team.

## Long-running or multi-session work
Agents lose context between sessions. Keep state in files, not chat: the task checklist (`tasks.md` or `notes.md`) is the progress ledger and `notes.md` in the change folder holds handoff notes (what is done, what is next, traps). A fresh session starts by reading those.

## When an agent gets something wrong
Do not just fix the code. Ask what the harness was missing and add one of: an arch-lint rule, a test, a line in a stack doc, a planning rule. Record it in `docs/lessons.md`. This is how the harness gets better over time.

