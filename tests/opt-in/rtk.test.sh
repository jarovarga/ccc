#!/usr/bin/env bash
# Checks the settings of the opt-in rtk topic.
set -o nounset
set -o pipefail

# shellcheck source=../lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/check.sh" || exit 1

readonly SETTINGS="${CCC_ROOT}/opt-in/rtk/settings.json"

begin 'only topic keys'
assert_jq "${SETTINGS}" 'keys == ["hooks", "sandbox"]'
assert_jq "${SETTINGS}" '.sandbox == {"filesystem":
  {"allowRead": ["~/.claude/settings.json"]}}'

begin 'non-blocking hook'
assert_jq "${SETTINGS}" '.hooks == {"PreToolUse": [{"matcher": "Bash",
  "hooks": [{"command": "rtk hook claude", "timeout": 10,
    "type": "command"}]}]}'

finish
