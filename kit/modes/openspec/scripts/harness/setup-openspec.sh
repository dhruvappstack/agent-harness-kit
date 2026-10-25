#!/usr/bin/env bash
# Creates the "harness" OpenSpec schema by forking the built-in spec-driven schema (so upstream
# instruction improvements are kept), then adds two artifacts: review and test-plan.
# Safe to rerun. Never overwrites an existing config.yaml key.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
command -v openspec >/dev/null || { echo "ERROR: openspec CLI not found. FIX: npm install -g @fission-ai/openspec@latest"; exit 1; }
command -v node >/dev/null || { echo "ERROR: node not found"; exit 1; }
[ -d openspec ] || { echo "ERROR: no openspec/ directory. FIX: run 'openspec init' first"; exit 1; }

dst=openspec/schemas/harness
if [ ! -d "$dst" ]; then openspec schema fork spec-driven harness || exit 1; fi
cp harness/templates/review.md harness/templates/test-plan.md "$dst/templates/"

node - "$dst/schema.yaml" <<'JS'
const fs = require('fs');
const p = process.argv[2];
let s = fs.readFileSync(p, 'utf8');
if (s.includes('- id: review')) { console.log('schema already patched'); process.exit(0); }
const block = `  - id: review
    generates: review.md
    description: Independent plan review with an approval verdict
    template: review.md
    instruction: |
      Review the plan as an independent, skeptical reviewer following harness/roles/plan-reviewer.md.
      This artifact should be written by a fresh-context agent that did not write the plan (ideally a different model).
      Read proposal, specs and design. Do not edit them. List findings as [BLOCKER], [MAJOR] or [MINOR] with a concrete fix.
      The final line of the file MUST be exactly "VERDICT: APPROVE" (no BLOCKER or MAJOR) or "VERDICT: REVISE".
      Leave the template's "VERDICT: REVISE" in place until the review has actually been done.
    requires:
      - specs
      - design

  - id: test-plan
    generates: test-plan.md
    description: Mapping from every spec scenario to a named test or evaluator check
    template: test-plan.md
    instruction: |
      Map every scenario in the specs to a named test at the lowest level that can prove it (unit, integration, ui, e2e),
      or to an explicit evaluator check with a reason. List fixtures, launch state and test identifiers the tests need.
      Remove all template comments and placeholder rows when done. Leave Red/Green empty; the implementer fills them in.
    requires:
      - review

`;
const anchor = '\n  - id: tasks\n';
const i = s.indexOf(anchor);
if (i < 0) { console.error('anchor "- id: tasks" not found; upstream schema changed. Patch schema.yaml by hand using harness/templates/review.md and test-plan.md.'); process.exit(1); }
s = s.slice(0, i + 1) + block + s.slice(i + 1);
const reqOld = /(  - id: tasks[\s\S]*?    requires:\n      - specs\n      - design\n)/;
if (!reqOld.test(s)) { console.error('tasks.requires block not found; patch by hand: add review and test-plan to tasks.requires'); process.exit(1); }
s = s.replace(reqOld, (m) => m + '      - review\n      - test-plan\n');
s = s.replace(/^description: .*$/m, 'description: OpenSpec workflow with independent review and test-plan (proposal, specs, design, review, test-plan, tasks)');
fs.writeFileSync(p, s);
console.log('schema patched');
JS
[ $? -eq 0 ] || exit 1

openspec schema validate harness || exit 1

cfg=openspec/config.yaml
[ -f "$cfg" ] || echo "schema: harness" > "$cfg"
if grep -qE '^schema:' "$cfg"; then sed -i.bak -E 's/^schema:.*/schema: harness/' "$cfg" && rm -f "$cfg.bak"; else printf 'schema: harness\n%s' "$(cat "$cfg")" > "$cfg"; fi
for k in context rules operations; do
  if grep -qE "^$k:" "$cfg"; then echo "config.yaml already has '$k:' - merge harness/openspec-config/$k.yaml by hand"; else printf '\n' >> "$cfg"; cat "harness/openspec-config/$k.yaml" >> "$cfg"; echo "added '$k:' to config.yaml"; fi
done
echo "Done. Verify: openspec schema which harness && openspec schema validate harness"
