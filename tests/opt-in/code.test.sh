#!/usr/bin/env bash
# Checks the settings and the hooks of the opt-in code topic.
set -o nounset
set -o pipefail

# shellcheck source=../lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/../lib/check.sh" || exit 1

readonly TOPIC="${CCC_ROOT}/opt-in/code"
readonly SETTINGS="${TOPIC}/settings.json"
readonly PATHS_HOOK="${TOPIC}/hooks/code-paths.sh"
readonly SUPPRESSIONS_HOOK="${TOPIC}/hooks/code-suppressions.sh"
readonly BLOCK=2 ALLOW=0
readonly PROJECT=/project

# macOS mktemp ignores TMPDIR without a template, and the sandbox allows
# writes only there.
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/code.test.XXXXXX") || exit 1
readonly WORK_DIR
trap 'rm -rf -- "${WORK_DIR}"' EXIT

# Fails unless the hook exits with the expected code for the tool input.
# Arguments: hook, expected exit code, tool name, tool input as JSON, project
# directory (optional).
assert_hook() {
  local json status=0
  json=$(jq -n --arg tool "$3" --arg cwd "${5:-${PROJECT}}" \
    --argjson input "$4" \
    '{hook_event_name: "PreToolUse", cwd: $cwd, tool_name: $tool,
      tool_input: $input}') || {
    fail "jq failed for $4"
    return
  }
  "${BASH}" -- "$1" <<<"${json}" >/dev/null 2>&1 || status=$?
  [[ "${status}" -eq "$2" ]] \
    || fail "${1##*/}: exit ${status}, expected $2 for $3 $4"
}

# Arguments: expected exit code, file path.
assert_path() {
  assert_hook "${PATHS_HOOK}" "$1" Edit \
    "$(jq -n --arg file "$2" '{file_path: $file, old_string: "a",
      new_string: "b"}')"
}

# Arguments: expected exit code, file path, old text, new text.
assert_edit() {
  assert_hook "${SUPPRESSIONS_HOOK}" "$1" Edit \
    "$(jq -n --arg file "$2" --arg old "$3" --arg new "$4" \
      '{file_path: $file, old_string: $old, new_string: $new}')"
}

# Arguments: expected exit code, file path, content.
assert_write() {
  assert_hook "${SUPPRESSIONS_HOOK}" "$1" Write \
    "$(jq -n --arg file "$2" --arg content "$3" \
      '{file_path: $file, content: $content}')"
}

begin 'only topic keys'
assert_jq "${SETTINGS}" 'keys == ["hooks"]'

begin 'non-blocking hooks on the file tools'
assert_jq "${SETTINGS}" '.hooks == {"PreToolUse": [{
  "matcher": "Edit|Write|NotebookEdit", "hooks": [
    {"command": "~/.claude/hooks/code-paths.sh", "timeout": 10,
      "type": "command"},
    {"command": "~/.claude/hooks/code-suppressions.sh", "timeout": 10,
      "type": "command"}]}]}'

begin 'own code passes'
assert_path "${ALLOW}" "${PROJECT}/src/app.php"
assert_path "${ALLOW}" "${PROJECT}/composer.json"
assert_path "${ALLOW}" "${PROJECT}/src/vendors.php"
assert_path "${ALLOW}" "${PROJECT}/docs/.gitignore"

begin 'vendor below the project root passes'
assert_path "${ALLOW}" "${PROJECT}/resources/views/vendor/mail/a.blade.php"

begin 'project under a dependency directory name passes'
assert_hook "${PATHS_HOOK}" "${ALLOW}" Edit \
  '{"file_path": "/vendor/app/src/a.php", "old_string": "a",
    "new_string": "b"}' /vendor/app

begin 'lock files blocked'
assert_path "${BLOCK}" "${PROJECT}/composer.lock"
assert_path "${BLOCK}" "${PROJECT}/web/package-lock.json"
assert_path "${BLOCK}" "${PROJECT}/Composer.lock"

begin 'dependency and git directories blocked'
assert_path "${BLOCK}" "${PROJECT}/vendor/acme/lib/a.php"
assert_path "${BLOCK}" "${PROJECT}/web/node_modules/x/index.js"
assert_path "${BLOCK}" "${PROJECT}/.git/config"
assert_path "${BLOCK}" "${PROJECT}/.git/hooks/pre-commit"
assert_path "${BLOCK}" "${PROJECT}/Vendor/a.php"
assert_path "${BLOCK}" "${PROJECT}/.GIT/config"
assert_path "${BLOCK}" "${PROJECT}/web/packages/a/node_modules/b/index.js"

begin 'unnormalised paths blocked'
assert_path "${BLOCK}" "${PROJECT}/src/../a.php"
assert_path "${BLOCK}" "${PROJECT}/src/.."
assert_path "${BLOCK}" "../composer.json"
assert_path "${BLOCK}" ".."

begin 'faults fail open'
for hook in "${PATHS_HOOK}" "${SUPPRESSIONS_HOOK}"; do
  status=0
  "${BASH}" -- "${hook}" <<<'not json' >/dev/null 2>&1 || status=$?
  [[ "${status}" -eq 1 ]] || fail "${hook##*/}: exit ${status} for invalid JSON"
done

begin 'symbolic links followed'
mkdir -p -- "${WORK_DIR}/repo/.git" "${WORK_DIR}/repo/src" || exit 1
ln -s -- ../.git "${WORK_DIR}/repo/src/meta" || exit 1
ln -s -- ../composer.lock "${WORK_DIR}/repo/src/deps.txt" || exit 1
assert_hook "${PATHS_HOOK}" "${BLOCK}" Write \
  "$(jq -n --arg file "${WORK_DIR}/repo/src/meta/config" \
    '{file_path: $file, content: "x"}')"
assert_hook "${PATHS_HOOK}" "${BLOCK}" Write \
  "$(jq -n --arg file "${WORK_DIR}/repo/src/deps.txt" \
    '{file_path: $file, content: "x"}')"
assert_hook "${PATHS_HOOK}" "${ALLOW}" Write \
  "$(jq -n --arg file "${WORK_DIR}/repo/src/new.php" \
    '{file_path: $file, content: "x"}')"

begin 'project reached through a symbolic link'
ln -s -- repo "${WORK_DIR}/link" || exit 1
mkdir -p -- "${WORK_DIR}/repo/resources/vendor" || exit 1
assert_hook "${PATHS_HOOK}" "${ALLOW}" Write \
  "$(jq -n --arg file "${WORK_DIR}/link/resources/vendor/a.php" \
    '{file_path: $file, content: "x"}')" "${WORK_DIR}/link"
assert_hook "${PATHS_HOOK}" "${BLOCK}" Write \
  "$(jq -n --arg file "${WORK_DIR}/link/.git/config" \
    '{file_path: $file, content: "x"}')" "${WORK_DIR}/link"

begin 'code without suppressions passes'
assert_edit "${ALLOW}" "${PROJECT}/a.js" 'let a = 1;' 'const a = 1;'
assert_write "${ALLOW}" "${PROJECT}/a.sh" $'#!/usr/bin/env bash\necho ok'
assert_write "${ALLOW}" "${PROJECT}/a.js" 'const note = "eslint-disable";'

begin 'suppressions in Markdown pass'
assert_write "${ALLOW}" "${PROJECT}/README.md" '<!-- eslint-disable -->'
assert_write "${ALLOW}" "${PROJECT}/docs/A.MARKDOWN" '# shellcheck disable'

begin 'existing suppressions kept'
assert_edit "${ALLOW}" "${PROJECT}/a.js" \
  $'// eslint-disable-next-line\nfoo()' $'// eslint-disable-next-line\nbar()'

begin 'notebook cells without suppressions pass'
assert_hook "${SUPPRESSIONS_HOOK}" "${ALLOW}" NotebookEdit \
  '{"notebook_path": "/project/a.ipynb", "new_source": "x = 1"}'

begin 'new suppressions blocked'
assert_edit "${BLOCK}" "${PROJECT}/a.js" 'foo()' \
  $'// eslint-disable-next-line\nfoo()'
assert_edit "${BLOCK}" "${PROJECT}/a.ts" 'x' '// @ts-ignore'
assert_edit "${BLOCK}" "${PROJECT}/a.php" 'x' '/** @phpstan-ignore-next-line */'
assert_edit "${BLOCK}" "${PROJECT}/a.php" 'x' '// phpcs:ignore'
assert_edit "${BLOCK}" "${PROJECT}/a.css" 'x' '/* stylelint-disable */'
assert_edit "${BLOCK}" "${PROJECT}/a.html" 'x' '<!-- [html-validate-disable -->'
assert_edit "${BLOCK}" "${PROJECT}/a.sh" 'x' '# shellcheck disable=SC2086'
assert_edit "${BLOCK}" "${PROJECT}/a.py" 'x' 'x = f()  # type: ignore'
assert_edit "${BLOCK}" "${PROJECT}/a.py" 'x' '# PyLint: disable=foo'
assert_write "${BLOCK}" "${PROJECT}/a.js" '/* eslint-disable */'
assert_hook "${SUPPRESSIONS_HOOK}" "${BLOCK}" NotebookEdit \
  '{"notebook_path": "/project/a.ipynb", "new_source": "x = 1  # type: ignore"}'

finish
