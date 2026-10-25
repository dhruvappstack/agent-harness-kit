#!/usr/bin/env bash
# Change gate for spec-driven projects (SPEC_MODE in harness/harness.conf: openspec | native | none).
#   check-change.sh <change> [--stage plan|done|auto]
#   check-change.sh --changed <base-ref>      (CI) check every change touched since <base-ref>
# plan: required artifacts exist, review.md ends with "VERDICT: APPROVE", test-plan has no placeholders.
# done: plan checks + every task ticked + verification.md ends with "RESULT: PASS".
# SPEC_MODE=none: no plan artifacts exist; only a verification.md, if present, is checked.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

find_dir() { # <name> -> echoes dir
  local n="$1" a
  if [ -d "$ACTIVE_DIR/$n" ]; then echo "$ACTIVE_DIR/$n"; return 0; fi
  if [ -n "$ARCHIVE_DIR" ]; then
    a=$(ls -d "$ARCHIVE_DIR"/*-"$n" 2>/dev/null | tail -1)
    [ -n "$a" ] && { echo "$a"; return 0; }
  fi
  return 1
}

last_line() { grep -E "^$2" "$1" 2>/dev/null | tail -1 | trim; }

count_tasks() { # <tasks.md> -> "done open"
  awk 'match($0,/^[ \t]*- \[[^]]*\]/){s=substr($0,RSTART,RLENGTH);sub(/^[ \t]*- \[/,"",s);sub(/\]$/,"",s);gsub(/[ \t]/,"",s);if(s=="x"||s=="X")d++;else u++}END{print d+0,u+0}' "$1"
}

check_one() { # <name> <stage>
  local name="$1" stage="$2" d bad=0 f done_n open_n required
  d=$(find_dir "$name") || { echo "CHANGE FAIL [$name]: not found under $ACTIVE_DIR. FIX: check the name"; return 1; }
  e() { echo "CHANGE FAIL [$name]: $*"; bad=1; }

  if [ "$SPEC_MODE" != none ]; then
    case "$SPEC_MODE" in
      openspec) required="proposal.md design.md review.md test-plan.md tasks.md" ;;
      native)   required="proposal.md design.md review.md test-plan.md tasks.md" ;;
    esac
    for f in $required; do [ -f "$d/$f" ] || e "$f missing. FIX: create it (templates: harness/templates/)"; done
    if [ "$SPEC_MODE" = native ]; then
      [ -f "$d/spec.md" ] || [ -f "$d/.skip-spec" ] || e "spec.md missing. FIX: write it, or create an empty .skip-spec file for behaviour-neutral work"
    else
      if [ -z "$(find "$d/specs" -name '*.md' 2>/dev/null | head -1)" ] && ! grep -qs 'skip_specs: *true' "$d/.openspec.yaml"; then
        e "no delta specs and skip_specs is not set. FIX: write specs or set skip_specs: true for behaviour-neutral work"
      fi
    fi
    if [ -f "$d/review.md" ]; then
      [ "$(last_line "$d/review.md" 'VERDICT:')" = "VERDICT: APPROVE" ] || e "review.md is not approved (last VERDICT line: '$(last_line "$d/review.md" 'VERDICT:')'). FIX: run the plan-reviewer role, address findings, re-review"
    fi
    if [ -f "$d/test-plan.md" ]; then
      grep -qE '<!--|TBD|TODO' "$d/test-plan.md" && e "test-plan.md still has template comments or TBD/TODO. FIX: map every scenario"
    fi
  fi

  if [ "$stage" = done ]; then
    if [ "$SPEC_MODE" != none ] && [ -f "$d/tasks.md" ]; then
      read -r done_n open_n < <(count_tasks "$d/tasks.md")
      [ "$open_n" -eq 0 ] || e "$open_n unfinished task(s) in tasks.md"
    fi
    if [ -f "$d/verification.md" ]; then
      [ "$(last_line "$d/verification.md" 'RESULT:')" = "RESULT: PASS" ] || e "verification.md is not PASS (last RESULT line: '$(last_line "$d/verification.md" 'RESULT:')')"
    else
      e "verification.md missing. FIX: run the evaluator role (template: harness/templates/verification.md)"
    fi
  fi
  [ $bad -eq 0 ] && echo "[PASS] change/$name ($stage)"
  return $bad
}

auto_stage() { # plan until every task is ticked, then done
  local d u; d=$(find_dir "$1") || { echo plan; return; }
  [ "$SPEC_MODE" = none ] && { echo done; return; }
  [ -f "$d/tasks.md" ] || { echo plan; return; }
  u=$(count_tasks "$d/tasks.md" | awk '{print $2}')
  [ "$u" -eq 0 ] && echo done || echo plan
}

if [ "${1:-}" = "--changed" ]; then
  base="${2:?usage: check-change.sh --changed <base-ref>}"
  if [ "$SPEC_MODE" = none ]; then echo "[PASS] SPEC_MODE=none: no change gate"; exit 0; fi
  if [ "$CI_SPEC_GATE" = off ]; then echo "[SKIP] CI_SPEC_GATE=off"; exit 0; fi
  mb=$(git merge-base HEAD "$base" 2>/dev/null || echo "$base")
  files=$(git diff --name-only "$mb" HEAD)
  names=$(printf '%s\n' "$files" | awk -v act="$ACTIVE_DIR/" -v arc="$ARCHIVE_DIR/" '
    index($0,arc)==1 && arc!="/" { r=substr($0,length(arc)+1); split(r,a,"/"); n=a[1]; sub(/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-/,"",n); print n; next }
    index($0,act)==1 { r=substr($0,length(act)+1); split(r,a,"/"); if (a[1]!="archive" && a[2]!="") print a[1] }' | sort -u)
  src=$(printf '%s\n' "$files" | grep -vE '^(openspec/|specs/|docs/|harness/|scripts/harness/|\.github/|\.claude/)|\.md$' || true)
  rc=0
  if [ -z "$names" ]; then
    if [ -n "$src" ]; then
      echo "CHANGE FAIL: source files changed but no change folder was touched. FIX: add a change under $ACTIVE_DIR (see docs/workflow.md tiers) or label the PR 'no-spec' for Tier 0 work."
      printf '%s\n' "$src" | head -10 | sed 's/^/    /'
      rc=1
    else echo "[PASS] no change required (no source changes)"; fi
  else
    for n in $names; do check_one "$n" "$(auto_stage "$n")" || rc=1; done
  fi
  if [ $rc -ne 0 ] && [ "$CI_SPEC_GATE" = warn ]; then echo "(CI_SPEC_GATE=warn: reported as a warning, not failing the build. Set CI_SPEC_GATE=fail in harness/harness.conf to enforce.)"; exit 0; fi
  exit $rc
fi

name="${1:?usage: check-change.sh <change> [--stage plan|done|auto]}"; stage="auto"
[ "${2:-}" = "--stage" ] && stage="${3:-auto}"
[ "$stage" = auto ] && stage=$(auto_stage "$name")
check_one "$name" "$stage"
