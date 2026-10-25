#!/usr/bin/env bash
# Mechanical architecture rules: harness/arch-rules/_common.rules and harness/arch-rules/<stack>.rules
# Rule line (fields separated by ::):
#   dirs :: file-globs(comma separated) :: forbidden-regex(ERE) :: message (WHAT. FIX. REF.)
# dirs: space or comma separated, relative to the stack ROOT (repo root for _common). A "*" matches any
# characters including "/". Paths that do not exist are skipped, so aspirational rules are harmless.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
violations=0

apply_rules() { # <rules-file> <label> <root>
  local file="$1" label="$2" root="$3" line p g re msg rest f hits loc h pat d
  [ -f "$file" ] || return 0
  if [ ! -d "$root" ]; then echo "[FAIL] arch-lint/$label: ROOT '$root' does not exist. FIX: set ROOT in harness/stacks/$label.env"; violations=$((violations+1)); return 0; fi
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    p=$(printf '%s' "${line%%::*}" | trim);   rest="${line#*::}"
    g=$(printf '%s' "${rest%%::*}" | trim);   rest="${rest#*::}"
    re=$(printf '%s' "${rest%%::*}" | trim);  msg=$(printf '%s' "${rest#*::}" | trim)
    p="${p//,/ }"; [ -n "$g" ] || g="*"
    hits=$( cd "$root" || exit 0
      for pat in $p; do
        pat="${pat#./}"
        if [ "$pat" = "." ]; then dirs="."; else
          dirs=$(find . \( -name node_modules -o -name .git -o -name build -o -name dist -o -name Pods -o -name .gradle -o -name .harness -o -name openspec \) -prune -o -type d -path "./$pat" -print 2>/dev/null)
        fi
        for d in $dirs; do
          IFS=',' read -ra gl <<<"$g"
          set --
          for f in "${gl[@]}"; do set -- "$@" "--include=$(printf '%s' "$f" | trim)"; done
          grep -rEn "$@" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=build --exclude-dir=dist \
            --exclude-dir=Pods --exclude-dir=.gradle --exclude-dir=.harness --exclude-dir=openspec \
            -e "$re" -- "$d" 2>/dev/null
        done
      done | sort -u )
    if [ -n "$hits" ]; then
      while IFS= read -r h; do
        loc="${h#./}"; [ "$root" = "." ] || loc="${root#./}/$loc"
        echo "ARCH VIOLATION [$label] $loc :: $msg"; violations=$((violations+1))
      done <<<"$hits"
    fi
  done < "$file"
}

apply_rules harness/arch-rules/_common.rules common .
for s in $(stacks); do
  root=$( set -a; . "harness/stacks/$s.env" 2>/dev/null; echo "${ROOT:-.}" )
  apply_rules "harness/arch-rules/$s.rules" "$s" "$root"
done

if [ "$violations" -gt 0 ]; then
  echo "[FAIL] arch-lint: $violations violation(s). NEXT: fix the code, not the rule. If the rule is wrong, change it in a reviewed PR and update ARCHITECTURE.md."
  exit 1
fi
echo "[PASS] arch-lint"
