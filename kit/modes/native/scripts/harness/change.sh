#!/usr/bin/env bash
# Minimal spec-driven workflow without external tooling (SPEC_MODE=native).
#   change.sh new <kebab-name> [--no-spec]   scaffold specs/changes/<name>/ from harness/templates
#   change.sh list                           active changes and their gate state
#   change.sh status <name>                  show artifacts and run the gate
#   change.sh archive <name>                 gate must pass; moves to specs/archive/<date>-<name>
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ "$SPEC_MODE" = native ] || { echo "change.sh is for SPEC_MODE=native (current: $SPEC_MODE)"; exit 2; }
cmd="${1:-}"; name="${2:-}"
valid() { printf '%s' "$1" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; }
T=harness/templates; N=harness/templates/native

case "$cmd" in
  new)
    valid "$name" || { echo "usage: change.sh new <kebab-case-name> [--no-spec]"; exit 2; }
    d="$ACTIVE_DIR/$name"; [ -e "$d" ] && { echo "$d already exists"; exit 1; }
    mkdir -p "$d/evidence"
    cp "$N/proposal.md" "$N/design.md" "$N/tasks.md" "$T/review.md" "$T/test-plan.md" "$T/notes.md" "$d/"
    if [ "${3:-}" = "--no-spec" ]; then : > "$d/.skip-spec"; else cp "$N/spec.md" "$d/"; fi
    sed -i.bak "s/<change-name>/$name/g" "$d"/*.md && rm -f "$d"/*.bak
    echo "Created $d"; echo "Next: planner fills proposal, spec, design; plan-reviewer fills review; then test-plan and tasks. See docs/workflow.md." ;;
  list)
    for d in "$ACTIVE_DIR"/*/; do [ -d "$d" ] || continue; n=$(basename "$d"); "$HARNESS_ROOT/scripts/harness/check-change.sh" "$n" 2>&1 | head -1; done ;;
  status)
    valid "$name" || { echo "usage: change.sh status <name>"; exit 2; }
    d="$ACTIVE_DIR/$name"; [ -d "$d" ] || { echo "no such change"; exit 1; }
    ls -1 "$d"; echo; "$HARNESS_ROOT/scripts/harness/check-change.sh" "$name" ;;
  archive)
    valid "$name" || { echo "usage: change.sh archive <name>"; exit 2; }
    "$HARNESS_ROOT/scripts/harness/check-change.sh" "$name" --stage done || exit 1
    dest="$ARCHIVE_DIR/$(date +%Y-%m-%d)-$name"; mkdir -p "$ARCHIVE_DIR"
    mv "$ACTIVE_DIR/$name" "$dest" && echo "Archived to $dest"
    echo "Reminder: merge the accepted requirements from $dest/spec.md into specs/current/<capability>.md" ;;
  *) sed -n '2,7p' "$0"; exit 2 ;;
esac
