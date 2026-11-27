#!/usr/bin/env bash
# Checks which Bash calls the Git hook blocks.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly BLOCK=2 ALLOW=0

# macOS mktemp ignores TMPDIR without a template, and the sandbox allows
# writes only there.
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git.test.XXXXXX") || exit 1
readonly WORK_DIR
trap 'rm -rf -- "${WORK_DIR}"' EXIT
HOOK=$(install_hook "${CCC_ROOT}/hooks/git.sh" "${WORK_DIR}") || exit 1
readonly HOOK

# Fails unless the hook exits with the expected code for the command.
# Arguments: expected exit code, command.
assert_hook() {
  local json status=0
  json=$(jq -n --arg command "$2" \
    '{hook_event_name: "PreToolUse", tool_name: "Bash",
      tool_input: {command: $command}}') || {
    fail "jq failed for $2"
    return
  }
  "${BASH}" -- "${HOOK}" <<<"${json}" >/dev/null 2>&1 || status=$?
  [[ "${status}" -eq "$1" ]] \
    || fail "exit ${status}, expected $1 for $2"
}

begin 'other commands pass'
assert_hook "${ALLOW}" 'ls -la'
assert_hook "${ALLOW}" 'echo git; npm test --no-verify'

begin 'ordinary git passes'
assert_hook "${ALLOW}" 'git status --short'
assert_hook "${ALLOW}" 'git commit -m "x"'
assert_hook "${ALLOW}" 'git commit -am "fix" --amend'
assert_hook "${ALLOW}" 'git commit -uno -m "x"'
assert_hook "${ALLOW}" 'git commit -c HEAD'
assert_hook "${ALLOW}" 'git -C repo log -n 5'
assert_hook "${ALLOW}" 'git push -n'
assert_hook "${ALLOW}" 'git revert -n HEAD'
assert_hook "${ALLOW}" 'git merge --no-verify-signatures main'
assert_hook "${ALLOW}" 'git log -- --no-verify'
assert_hook "${ALLOW}" 'git -C -c status'
assert_hook "${ALLOW}" 'git --attr-source HEAD log -n 1'

begin 'option text in a message passes'
assert_hook "${ALLOW}" 'git commit -m "Never use --no-verify here"'
assert_hook "${ALLOW}" 'git commit -m "Drop git -c and commit -n"'
assert_hook "${ALLOW}" $'git commit -F - <<EOF\nskip --no-verify\nEOF'
assert_hook "${ALLOW}" 'git commit -m "GIT_CONFIG_COUNT=1 is risky"'

begin 'hooks skipped'
assert_hook "${BLOCK}" 'git commit --no-verify -m "x"'
assert_hook "${BLOCK}" 'git commit -m "x" --no-verify'
assert_hook "${BLOCK}" 'git commit --no-v -m "x"'
assert_hook "${BLOCK}" 'git push --no-verify'
assert_hook "${BLOCK}" 'git merge --no-verify main'
assert_hook "${BLOCK}" 'git commit -n -m "x"'
assert_hook "${BLOCK}" 'git commit -an -m "x"'
assert_hook "${BLOCK}" 'git am -n patch.mbox'
assert_hook "${BLOCK}" 'git -C repo --no-pager commit -n'
assert_hook "${BLOCK}" 'git --attr-source HEAD commit -n'
assert_hook "${BLOCK}" '/usr/bin/git commit --no-verify'
assert_hook "${BLOCK}" 'rtk git commit --no-verify -m "x"'
assert_hook "${BLOCK}" 'cd repo && git commit --no-verify'
assert_hook "${BLOCK}" "cd 'repo' && git commit --no-verify"
assert_hook "${BLOCK}" "echo \"\$(git commit --no-verify)\""

begin 'configuration for one command'
assert_hook "${BLOCK}" 'git -c core.hooksPath=/dev/null commit -m "x"'
assert_hook "${BLOCK}" 'git -ccore.pager=cat log'
assert_hook "${BLOCK}" 'git --no-pager -c core.fsmonitor=x status'
assert_hook "${BLOCK}" 'git -C . -c alias.x=!sh log'
assert_hook "${BLOCK}" 'git --config-env=core.pager=PAGER log'
assert_hook "${BLOCK}" 'git --config-env core.pager=PAGER log'

begin 'configuration through the environment'
assert_hook "${BLOCK}" 'GIT_CONFIG_COUNT=1 git log'
assert_hook "${BLOCK}" 'GIT_CONFIG_GLOBAL=/tmp/x git commit -m "x"'
assert_hook "${BLOCK}" 'export GIT_CONFIG_KEY_0=core.hooksPath'
assert_hook "${BLOCK}" 'env GIT_CONFIG_PARAMETERS=x git log'
assert_hook "${BLOCK}" 'declare -x GIT_CONFIG_SYSTEM=/tmp/x'

begin 'IFS expansion blocked'
assert_hook "${BLOCK}" "git\${IFS}commit\${IFS}--no-verify"

begin 'missing library fails'
rm -rf -- "${WORK_DIR}/hooks/lib" || exit 1
status=0
"${BASH}" -- "${HOOK}" <<<'{"tool_input": {"command": "ls"}}' \
  >/dev/null 2>&1 || status=$?
[[ "${status}" -eq 1 ]] || fail "exit ${status} without hooks/lib, expected 1"

finish
