#!/usr/bin/env bash
# Checks which Bash calls the hook of the opt-in github topic blocks.
set -o nounset
set -o pipefail

# shellcheck source=../lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/check.sh" || exit 1

readonly HOOK="${CCC_ROOT}/opt-in/github/hooks/github.sh"
readonly BLOCK=2 ALLOW=0

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
assert_hook "${ALLOW}" 'echo gh | cat'

begin 'gh alone passes'
assert_hook "${ALLOW}" 'gh api repos/owner/repo/issues'
assert_hook "${ALLOW}" 'gh issue create --title "a > b" --body "x < y"'
assert_hook "${ALLOW}" 'gh issue create --title "a | b && c; d" --body "x"'
assert_hook "${ALLOW}" 'gh pr create --head octocat:fix --base main'
assert_hook "${ALLOW}" 'gh pr diff 12 --name-only 2>&1'
assert_hook "${ALLOW}" 'gh pr list --limit 5 2>&1'
assert_hook "${ALLOW}" 'gh repo view owner/repo --json description --jq .description'

begin 'gh with another command'
assert_hook "${BLOCK}" 'cd repo; gh pr list'
assert_hook "${BLOCK}" "echo \"\$(gh api user)\""
assert_hook "${BLOCK}" 'gh pr list && gh issue list'
assert_hook "${BLOCK}" 'gh pr view 1 --json title | jq .title'
assert_hook "${BLOCK}" 'gh repo view owner/repo | head -5'

begin 'gh with a redirect'
assert_hook "${BLOCK}" 'gh api graphql --input - < query.json'
assert_hook "${BLOCK}" 'gh api user 2>/dev/null'
assert_hook "${BLOCK}" 'gh issue create --body-file - <<<"text"'
assert_hook "${BLOCK}" $'gh issue create --body-file - <<EOF\ntext\nEOF'
assert_hook "${BLOCK}" 'gh pr diff 12 > "tmp dir/pr.diff"'
assert_hook "${BLOCK}" 'gh pr diff 12 >&pr.diff'
assert_hook "${BLOCK}" 'gh pr diff 12 >> pr.diff'

begin 'github.com allowed'
assert_hook "${ALLOW}" 'GH_HOST=github.com gh pr list'
assert_hook "${ALLOW}" 'gh issue create --title "see example.invalid/a/b" --body x'
assert_hook "${ALLOW}" 'gh issue list --repo owner/repo'
assert_hook "${ALLOW}" 'gh issue view https://github.com/owner/repo/issues/1'
assert_hook "${ALLOW}" 'gh repo clone git@github.com:octocat/hello.git'
assert_hook "${ALLOW}" 'gh repo clone ssh://git@github.com/octocat/hello.git'
assert_hook "${ALLOW}" 'gh repo view github.com/octocat/hello'

begin 'other hosts blocked'
assert_hook "${BLOCK}" 'GH_HOST=example.invalid gh pr list'
assert_hook "${BLOCK}" 'gh api user --hostname example.invalid'
assert_hook "${BLOCK}" 'gh api user --hostname=example.invalid'
assert_hook "${BLOCK}" 'gh issue list --repo=example.invalid/o/r'
assert_hook "${BLOCK}" 'gh issue list -R example.invalid/o/r'
assert_hook "${BLOCK}" 'gh issue view https://example.invalid/o/r/issues/1'
assert_hook "${BLOCK}" 'gh repo clone example.invalid:o/r.git'
assert_hook "${BLOCK}" 'gh repo clone git@example.invalid:o/r.git'
assert_hook "${BLOCK}" 'gh repo clone git@evil:o/r'
assert_hook "${BLOCK}" 'gh repo clone 10.0.0.1:o/r'
assert_hook "${BLOCK}" 'gh repo view "example.invalid/o/r"'
assert_hook "${BLOCK}" 'gh repo view example.invalid/o/r'
assert_hook "${BLOCK}" 'gh repo view https://github.com.example.invalid/o/r'
assert_hook "${BLOCK}" 'gh repo view https://user@example.invalid:8443/o/r'
assert_hook "${BLOCK}" 'gh repo view 10.0.0.1/o/r'
assert_hook "${BLOCK}" 'gh repo view localhost/o/r'

begin 'IFS expansion blocked'
assert_hook "${BLOCK}" "gh repo view\${IFS}example.invalid/o/r"

finish
