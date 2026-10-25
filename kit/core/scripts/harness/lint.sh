#!/usr/bin/env bash
# Runs LINT_CMD for every configured stack. See harness/stacks/*.env
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_stack_cmd LINT_CMD lint
