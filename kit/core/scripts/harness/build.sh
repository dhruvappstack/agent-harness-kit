#!/usr/bin/env bash
# Runs BUILD_CMD for every configured stack. See harness/stacks/*.env
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_stack_cmd BUILD_CMD build
