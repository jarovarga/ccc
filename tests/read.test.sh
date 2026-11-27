#!/usr/bin/env bash
# Checks which Bash calls the read hook blocks.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly BLOCK=2 ALLOW=0

# macOS mktemp ignores TMPDIR without a template, and the sandbox allows
# writes only there.
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/read.test.XXXXXX") || exit 1
readonly WORK_DIR
trap 'rm -rf -- "${WORK_DIR}"' EXIT
HOOK=$(install_hook "${CCC_ROOT}/hooks/read.sh" "${WORK_DIR}") || exit 1
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
assert_hook "${ALLOW}" 'git status --short'
assert_hook "${ALLOW}" 'grep -n foo README.md'
assert_hook "${ALLOW}" 'concat README.md'

begin 'reading a pipe or a heredoc passes'
assert_hook "${ALLOW}" 'git log --oneline | head'
assert_hook "${ALLOW}" 'git log | head -n 5'
assert_hook "${ALLOW}" 'git log | head -5'
assert_hook "${ALLOW}" 'ls | tail -c 100'
assert_hook "${ALLOW}" 'git log | sed -n 1,5p'
assert_hook "${ALLOW}" "git log | sed -e 's/a/b/' -e 's/c/d/'"
assert_hook "${ALLOW}" "git log | sed -ne 's/a/b/p'"
assert_hook "${ALLOW}" "ls -l | awk '{print \$1}'"
assert_hook "${ALLOW}" "ls -l | awk -F: -v x=1 '{print x}'"
assert_hook "${ALLOW}" 'ls | awk -f prog.awk'
assert_hook "${ALLOW}" 'cat'
assert_hook "${ALLOW}" 'cat -'
assert_hook "${ALLOW}" $'cat <<EOF\nsee cat README.md\nEOF'
assert_hook "${ALLOW}" "cat <<<'text'"
assert_hook "${ALLOW}" 'git log | head -n 5 2>/dev/null'
assert_hook "${ALLOW}" 'git log | head 2>&1'
assert_hook "${ALLOW}" 'git log | head -n 5 >> out.log 2>> err.log'
assert_hook "${ALLOW}" $'cat >> notes.md <<EOF\ntext\nEOF'
assert_hook "${ALLOW}" 'cat <(git log)'
assert_hook "${ALLOW}" 'head -n 5 < <(git log)'
assert_hook "${ALLOW}" 'git log | tail +5'
assert_hook "${ALLOW}" 'git log | awk 1 2>&1'

begin 'command text in a message passes'
assert_hook "${ALLOW}" 'git commit -m "Never run cat README.md"'
assert_hook "${ALLOW}" 'echo "sed -n 1p file"'

begin 'tail -f passes'
assert_hook "${ALLOW}" 'tail -f debug.log'
assert_hook "${ALLOW}" 'tail -n 20 -F debug.log'
assert_hook "${ALLOW}" 'tail --follow=name debug.log'

begin 'reading a file blocked'
assert_hook "${BLOCK}" 'cat README.md'
assert_hook "${BLOCK}" 'cat -n README.md'
assert_hook "${BLOCK}" 'cat "my notes.md"'
assert_hook "${BLOCK}" 'cat < README.md'
assert_hook "${BLOCK}" 'cat -- -file'
assert_hook "${BLOCK}" 'head README.md'
assert_hook "${BLOCK}" 'head -n 20 README.md'
assert_hook "${BLOCK}" 'head -20 README.md'
assert_hook "${BLOCK}" 'tail -c 100 README.md'
assert_hook "${BLOCK}" 'sed -n 1,5p README.md'
assert_hook "${BLOCK}" "sed -e 's/a/b/' README.md"
assert_hook "${BLOCK}" "sed -i '' 's/a/b/' README.md"
assert_hook "${BLOCK}" "awk '{print \$1}' README.md"
assert_hook "${BLOCK}" "awk -F: -v x=1 '{print}' n=2 README.md"
assert_hook "${BLOCK}" 'awk -f prog.awk README.md'
assert_hook "${BLOCK}" 'awk 1 README.md'
assert_hook "${BLOCK}" 'tail +5 README.md'
assert_hook "${BLOCK}" 'cat README.md >> notes.md'
assert_hook "${BLOCK}" 'echo x | cat - README.md'

begin 'reading a file behind a wrapper or in a compound command blocked'
assert_hook "${BLOCK}" '/bin/cat README.md'
assert_hook "${BLOCK}" 'rtk cat README.md'
assert_hook "${BLOCK}" 'cd docs && cat README.md'
assert_hook "${BLOCK}" "for f in *.md; do head -n 5 \"\$f\"; done"
assert_hook "${BLOCK}" "echo \"\$(cat README.md)\""
assert_hook "${BLOCK}" 'cat README.md | wc -l'

begin 'missing library fails'
rm -rf -- "${WORK_DIR}/hooks/lib" || exit 1
status=0
"${BASH}" -- "${HOOK}" <<<'{"tool_input": {"command": "cat README.md"}}' \
  >/dev/null 2>&1 || status=$?
[[ "${status}" -eq 1 ]] || fail "exit ${status} without hooks/lib, expected 1"

finish
