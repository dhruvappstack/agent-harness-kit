#!/usr/bin/env bash
# Runs E2E_CMD for every configured stack. See harness/stacks/*.env
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_stack_cmd E2E_CMD e2e
