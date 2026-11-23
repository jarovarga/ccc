#!/usr/bin/env bash
# Checks that only register entries run outside the sandbox or skip the
# prompt: excludedCommands and Bash allow rules in the root settings.json.
# The register is empty for now.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly CORE="${CCC_ROOT}/settings.json"
readonly REGISTER_EXCLUDED='[]'
readonly REGISTER_BASH_ALLOW='[]'

begin 'excludedCommands from the register only'
assert_jq "${CORE}" '(.sandbox.excludedCommands // [])
  - '"${REGISTER_EXCLUDED}"' == []'

begin 'Bash allow from the register only'
assert_jq "${CORE}" '[(.permissions.allow // [])[]
  | select(startswith("Bash("))] - '"${REGISTER_BASH_ALLOW}"' == []'

finish
