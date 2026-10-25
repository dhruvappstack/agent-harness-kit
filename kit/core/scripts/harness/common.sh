#!/usr/bin/env bash
# Shared helpers, sourced by the other harness scripts. Do not run directly.
# Portable to bash 3.2 (macOS default). Requires: bash, grep, sed, awk, find.
set -uo pipefail
HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$HARNESS_ROOT" || exit 2
LOG_DIR=".harness/logs"
mkdir -p "$LOG_DIR"

# ---- configuration (harness/harness.conf) --------------------------------
SPEC_MODE=none; CI_SPEC_GATE=warn; AGENT_TOOLS=""; MAX_AGENTS_MD_LINES=150
# shellcheck disable=SC1091
[ -f harness/harness.conf ] && . harness/harness.conf
case "$SPEC_MODE" in
  openspec) : "${ACTIVE_DIR:=openspec/changes}"; : "${ARCHIVE_DIR:=openspec/changes/archive}" ;;
  native)   : "${ACTIVE_DIR:=specs/changes}";    : "${ARCHIVE_DIR:=specs/archive}" ;;
  none)     : "${ACTIVE_DIR:=harness/work}";     : "${ARCHIVE_DIR:=}" ;;
  *) echo "ERROR: SPEC_MODE='$SPEC_MODE' in harness/harness.conf. FIX: use openspec, native or none" >&2; exit 2 ;;
esac

stacks() {
  [ -f harness/stacks.list ] || { echo "ERROR: harness/stacks.list missing. FIX: add stack names, one per line, each with harness/stacks/<name>.env" >&2; return 1; }
  grep -vE '^[[:space:]]*(#|$)' harness/stacks.list
}

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# run_stack_cmd <VAR_NAME> <label>
# Runs the command stored in $VAR_NAME of every stack env file, from that stack's ROOT.
# Prints one PASS/FAIL/SKIP line per stack; on failure prints the log tail and a NEXT hint.
run_stack_cmd() {
  local var="$1" label="$2" rc=0 s envf log code
  for s in $(stacks); do
    envf="harness/stacks/$s.env"
    if [ ! -f "$envf" ]; then
      echo "[FAIL] $label/$s: $envf not found. FIX: create it or remove '$s' from harness/stacks.list"
      rc=1; continue
    fi
    log="$LOG_DIR/$label-$s.log"
    ( set -a; . "$envf"; set +a
      eval "cmd=\${$var:-}"
      [ -n "$cmd" ] || exit 77
      cd "${ROOT:-.}" || exit 78
      eval "$cmd" ) >"$log" 2>&1
    code=$?
    case $code in
      0)  echo "[PASS] $label/$s" ;;
      77) echo "[SKIP] $label/$s: $var is empty in $envf" ;;
      78) echo "[FAIL] $label/$s: ROOT directory does not exist. FIX: set ROOT in $envf"; rc=1 ;;
      *)  echo "[FAIL] $label/$s (exit $code). Last lines of $log:"
          tail -n 40 "$log" | sed 's/^/    /'
          echo "    NEXT: fix the cause, then rerun scripts/harness/$label.sh"
          rc=1 ;;
    esac
  done
  return $rc
}
