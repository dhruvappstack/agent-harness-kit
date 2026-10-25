#!/usr/bin/env bash
# Runs TEST_CMD for every configured stack. See harness/stacks/*.env
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
run_stack_cmd TEST_CMD test
