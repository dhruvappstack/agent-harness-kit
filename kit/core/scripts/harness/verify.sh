#!/usr/bin/env bash
# One command for agents and CI.
#   verify.sh --fast   arch-lint, lint, build
#   verify.sh          fast + unit tests
#   verify.sh --e2e    everything including E2E
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
mode="default"
for a in "$@"; do case "$a" in --fast) mode=fast ;; --e2e) mode=e2e ;; -h|--help) sed -n '2,5p' "$0"; exit 0 ;; esac; done
rc=0
step() { "$HARNESS_ROOT/scripts/harness/$1.sh" || rc=1; }
step arch-lint
step lint
step build
[ "$mode" = fast ] || step test
[ "$mode" = e2e ] && step e2e
if [ $rc -ne 0 ]; then echo; echo "VERIFY: FAILED ($mode). Fix the first failure above, then rerun."; else echo; echo "VERIFY: OK ($mode)"; fi
exit $rc
