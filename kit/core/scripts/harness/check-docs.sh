#!/usr/bin/env bash
# Keeps the knowledge base honest: size limit, required files, working relative links.
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fail=0
err() { echo "DOCS FAIL: $*"; fail=1; }

for f in AGENTS.md ARCHITECTURE.md docs/workflow.md docs/testing.md docs/quality.md docs/security.md docs/qa.md docs/lessons.md harness/harness.conf; do
  [ -f "$f" ] || err "$f is missing. FIX: restore it, or remove it from the list in scripts/harness/check-docs.sh if you deleted it on purpose"
done
if [ -f AGENTS.md ]; then
  n=$(wc -l < AGENTS.md | tr -d ' ')
  if [ "$n" -gt "$MAX_AGENTS_MD_LINES" ]; then err "AGENTS.md has $n lines (limit $MAX_AGENTS_MD_LINES). FIX: move detail into docs/ and link to it"
  elif [ "$n" -gt 100 ]; then echo "DOCS WARN: AGENTS.md has $n lines; aim for about 100"; fi
fi
for s in $(stacks); do
  [ -f "harness/stacks/$s.env" ] || err "harness/stacks/$s.env missing for stack '$s'"
done

: > "$LOG_DIR/docs-links.txt"
find AGENTS.md ARCHITECTURE.md docs -name '*.md' 2>/dev/null | while IFS= read -r md; do
  dir=$(dirname "$md")
  grep -oE '\]\([^)]+\)' "$md" | sed -e 's/^](//' -e 's/)$//' | while IFS= read -r link; do
    case "$link" in http*|mailto:*|\#*) continue ;; esac
    target="${link%%#*}"; [ -n "$target" ] || continue
    [ -e "$dir/$target" ] || [ -e "$target" ] || echo "DOCS FAIL: $md links to missing '$link'"
  done
done | tee -a "$LOG_DIR/docs-links.txt"
grep -q 'DOCS FAIL' "$LOG_DIR/docs-links.txt" && fail=1

if [ $fail -eq 0 ]; then echo "[PASS] check-docs"; else echo "[FAIL] check-docs"; exit 1; fi
