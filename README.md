# Agent Harness Kit

A generic, editable harness that makes coding agents (Claude Code, GitHub Copilot, Codex, Cursor, anything that reads `AGENTS.md`) reliable on any kind of project: mobile (iOS, Android, React Native, Flutter), frontend, backend, libraries and CLIs, or anything else. It works with OpenSpec, with a built-in minimal spec flow, or with no specs at all.

The kit gives you: one short `AGENTS.md` map, architecture rules enforced by a linter, one verify command for every stack, separate **planner / reviewer / implementer / evaluator / code-reviewer** roles, mechanical gates for CI, and a lessons log that turns every agent mistake into a permanent fix.

## Install

```bash
unzip agent-harness-kit.zip && cd agent-harness-kit
./install.sh /path/to/your/project            # everything auto-detected
```

Common variations:

```bash
./install.sh ~/app --spec none                          # no specs, lightest process
./install.sh ~/app --spec native --stacks ios,backend   # built-in spec flow, explicit stacks
./install.sh ~/app --spec openspec --setup-openspec     # integrate with OpenSpec
./install.sh ~/app --tools claude --ci none             # only Claude wrappers, no CI files
./install.sh ~/app --dry-run                            # preview, write nothing
./install.sh ~/app --upgrade                            # pull kit updates, keep your edits
./install.sh ~/app --uninstall                          # remove unmodified kit files
```

Prefer not to run a script? `harness-bootstrap-prompt.md` installs exactly the same setup through any coding agent.

Requirements: bash 3.2+ (macOS default is fine), grep, sed, awk, find, git. Windows: use WSL or Git Bash. OpenSpec mode also needs Node and the `openspec` CLI.

## Choose your planning mode (`harness/harness.conf`)

| Mode | What it is | Pick it when |
|---|---|---|
| `openspec` | OpenSpec owns specs and changes. The kit adds two artifacts (`review`, `test-plan`) via a forked schema, plus gates. Default when `openspec/` exists. | you already use OpenSpec |
| `native` | Plain-markdown spec flow: `specs/changes/<name>/` with proposal, spec, design, review, test-plan, tasks. `scripts/harness/change.sh` scaffolds, gates and archives. Default otherwise. | you want specs without extra tooling |
| `none` | The task description and its acceptance criteria are the plan. You still get independent evaluation, review, gates and the lessons loop. | specs feel heavy, or small teams and prototypes |

Switch any time by editing `SPEC_MODE`. CI strictness is `CI_SPEC_GATE=fail|warn|off` (defaults: `fail` for openspec, `warn` for native, `off` for none).

## What gets installed

```
AGENTS.md                 short map: commands, workflow for your mode, invariants, pointers
ARCHITECTURE.md           your layers and modules (fill in once)
docs/                     workflow, testing, quality, security, qa (evaluator), lessons, stack-*.md
harness/
  harness.conf            mode, CI strictness, limits
  roles/                  plan-reviewer, implementer, evaluator, code-reviewer (single source of truth)
  stacks.list, stacks/    one env file per stack: build, test, lint, e2e commands and ROOT
  arch-rules/             architecture lint rules (agent-readable errors)
  templates/              review, test-plan, verification, notes (+ native spec templates)
scripts/harness/          verify, build, test, lint, e2e, arch-lint, check-docs, check-change, doctor
                          (+ change.sh in native mode, setup-openspec.sh in openspec mode)
.claude/                  subagents, /harness:* commands, settings.json secret deny-list      [if claude]
.github/                  Copilot instructions, agents, prompts, path rules                    [if copilot]
.github/workflows         harness-ci.yml, PR template                                          [if github CI]
```

Stacks: `ios android react-native flutter frontend backend library generic` (use several for monorepos; `generic` covers infra, data, ML, embedded, docs sites).

## How you use it day to day

1. `scripts/harness/doctor.sh` shows what is still unconfigured. Fix the TODOs first: real commands in `harness/stacks/*.env`, layers in `ARCHITECTURE.md` and `harness/arch-rules/*.rules`.
2. Agents run `scripts/harness/verify.sh --fast` after each step and `verify.sh` before they claim done. `--e2e` adds end-to-end.
3. Planning, review, evaluation and code review follow `docs/workflow.md` for your mode. Invoke a role with `/harness:review-plan <change>` (Claude Code), `/harness-review-plan` (Copilot), the files in `.claude/agents` or `.github/agents`, or by pointing any agent at `harness/roles/<role>.md`.
4. Every time an agent gets something wrong, add a row to `docs/lessons.md` and turn it into a lint, test or doc line.

## Customising

Everything is plain text and yours to edit: roles (rubrics), templates, arch rules, stack env files, docs, `harness.conf`. To add a second app of the same kind (say an admin frontend), copy `harness/stacks/frontend.env` to `frontend-admin.env`, set its `ROOT`, add `frontend-admin` to `harness/stacks.list` and optionally a `frontend-admin.rules` file. `install.sh --upgrade` records what it installed in `harness/.kit-manifest`, refreshes only files you have not touched, and writes `*.harness-new` next to the rest.

## Design choices (from the research)

- **Short AGENTS.md, depth in docs/.** OpenAI reported a single large instruction file failed and a roughly 100-line map worked; an ETH Zurich study found context files often did not help and raised cost by over 20%, so only non-inferable rules belong in them. The kit caps it (`MAX_AGENTS_MD_LINES`).
- **Separate roles for review and evaluation.** Anthropic's long-running harness work found a standalone skeptical evaluator is easier to tune than a self-critical generator.
- **Mechanical enforcement.** Layer rules live in `.rules` files with errors that say WHAT, FIX and REF. `verify.sh` is the one command for agents and CI.
- **Ratchet.** Mistakes become lints, tests or docs, logged in `docs/lessons.md`.
- **One source of truth.** Tool wrappers point to `harness/roles/`; change a rule once.

## Limits

- `check-change.sh` checks that artifacts exist and that the final `VERDICT:` and `RESULT:` lines say approve and pass. It cannot prove who wrote them. Keep CI required in branch protection and consider CODEOWNERS on `review.md`.
- Arch-lint is regex-based: good for import and API bans, not a real dependency-graph tool. Adopt SwiftPM/Tuist graph checks, Gradle module rules, dependency-cruiser, import-linter or ArchUnit when you outgrow it.
- Stack auto-detection is a heuristic (a Go or Python repo may be a library, not a backend); edit `harness/stacks.list` if it guessed wrong. Profiles are starting points.
- Copilot custom-agent frontmatter and path-instruction behaviour change between releases; check current GitHub docs. Copilot's cloud agent runs on Linux, so iOS builds need a macOS runner or a local agent session.
- Tested with OpenSpec CLI 1.15.0. If a future release changes the `tasks` artifact, `setup-openspec.sh` fails loudly and says what to patch by hand.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Contact

For questions or feedback, email [dhruvnarayan1023@gmail.com](mailto:dhruvnarayan1023@gmail.com).
