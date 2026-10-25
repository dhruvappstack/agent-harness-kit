#!/usr/bin/env bash
# Reports how complete and healthy your harness setup is. Exit 1 only on FAIL.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fails=0; warns=0
ok()   { echo "[ OK ] $*"; }
warn() { echo "[WARN] $*"; warns=$((warns+1)); }
bad()  { echo "[FAIL] $*"; fails=$((fails+1)); }

echo "Spec mode: $SPEC_MODE   CI spec gate: $CI_SPEC_GATE   Agent tools: ${AGENT_TOOLS:-none}"
case "$SPEC_MODE" in
  openspec)
    [ -d openspec ] && ok "openspec/ present" || bad "openspec/ missing. FIX: openspec init"
    command -v openspec >/dev/null && ok "openspec CLI $(openspec --version 2>/dev/null)" || warn "openspec CLI not on PATH (npm i -g @fission-ai/openspec)"
    [ -d openspec/schemas/harness ] && ok "harness schema installed" || warn "harness schema missing. FIX: scripts/harness/setup-openspec.sh" ;;
  native) [ -d specs/changes ] && ok "specs/changes present" || bad "specs/changes missing"
          [ -x scripts/harness/change.sh ] && ok "change.sh present" || bad "scripts/harness/change.sh missing or not executable" ;;
  none)   ok "no spec tooling required" ;;
esac

n=$(wc -l < AGENTS.md 2>/dev/null | tr -d ' ')
[ -n "$n" ] && { [ "$n" -le "$MAX_AGENTS_MD_LINES" ] && ok "AGENTS.md is $n lines" || bad "AGENTS.md is $n lines (limit $MAX_AGENTS_MD_LINES)"; } || bad "AGENTS.md missing"
for t in $AGENT_TOOLS; do
  case "$t" in
    claude)  [ -d .claude/agents ] && ok "claude wrappers present" || warn "claude listed in AGENT_TOOLS but .claude/agents missing" ;;
    copilot) [ -d .github/agents ] && ok "copilot wrappers present" || warn "copilot listed in AGENT_TOOLS but .github/agents missing" ;;
  esac
done

for s in $(stacks); do
  envf="harness/stacks/$s.env"
  [ -f "$envf" ] || { bad "stack '$s': $envf missing"; continue; }
  grep -qiE '#[[:space:]]*TODO' "$envf" && warn "stack '$s': $envf still has TODO markers"
  for var in BUILD_CMD TEST_CMD LINT_CMD E2E_CMD; do
    res=$( set -a; . "$envf"; set +a; eval "cmd=\${$var:-}"
      if [ -z "$cmd" ]; then echo "EMPTY"; exit 0; fi
      [ -d "${ROOT:-.}" ] || { echo "NOROOT"; exit 0; }
      cd "${ROOT:-.}"
      first=$(printf '%s' "$cmd" | awk '{for(i=1;i<=NF;i++) if ($i !~ /^[A-Za-z_][A-Za-z0-9_]*=/) {print $i; exit}}')
      first=$(eval "echo $first" 2>/dev/null)
      case "$first" in ./*|/*) [ -x "$first" ] && echo "OK" || echo "MISSING:$first" ;; *) command -v "$first" >/dev/null 2>&1 && echo "OK" || echo "MISSING:$first" ;; esac )
    case "$res" in
      OK) ok "$s $var runnable" ;;
      EMPTY) [ "$var" = E2E_CMD ] && warn "$s: E2E_CMD empty (no E2E gate yet)" || warn "$s: $var empty (gate skipped)" ;;
      NOROOT) bad "$s: ROOT does not exist"; break ;;
      MISSING:*) warn "$s: $var uses '${res#MISSING:}' which is not installed here (fine if only CI has it; otherwise install it or fix the command)" ;;
    esac
  done
done
echo; echo "doctor: $fails failure(s), $warns warning(s)"
[ $fails -eq 0 ]
