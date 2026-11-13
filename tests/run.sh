#!/usr/bin/env bash
# Runs every hook against sample input and compares the exit code.
#
# Usage: tests/run.sh
# Exit code: 0 when every case passes, 1 otherwise. A hook blocks with exit 2
# and allows with exit 0.
set -euo pipefail

HOOKS_DIR=$(cd -- "$(dirname -- "$0")/../hooks" && pwd)
readonly HOOKS_DIR

readonly BLOCK=2
readonly ALLOW=0
readonly PROJECT=/work/project

# The suppression markers are assembled so that this file does not contain them
# in one piece, which block-suppressions.sh would reject.
readonly TS_IGNORE='@ts-''ignore'
readonly ESLINT_OFF='eslint-''disable'
readonly STYLELINT_OFF='stylelint-''disable'
readonly PHPSTAN_IGNORE='@phpstan-''ignore'
readonly PHPCS_IGNORE='phpcs:''ignore'
readonly PHPCS_OFF='phpcs:''disable'
readonly NOQA='no''qa'
readonly NOQA_UPPER='NO''QA'
readonly SHELLCHECK_OFF='shellcheck ''disable'
readonly TYPE_IGNORE='type: ''ignore'
readonly PYLINT_OFF='pylint: ''disable'

passed=0
failed=0
tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/ccc-hooks.XXXXXX")
trap 'rm -rf -- "${tmp_home}"' EXIT

# Arguments: expected exit code, hook file, description, stdin JSON, then any
# environment assignments for the hook.
expect() {
  local want=$1 hook=$2 name=$3 json=$4 got=0
  shift 4
  printf '%s' "${json}" | env "$@" "${HOOKS_DIR}/${hook}" >/dev/null 2>&1 || got=$?
  if ((got == want)); then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    printf 'FAIL %s: %s (want %s, got %s)\n' "${hook}" "${name}" "${want}" "${got}" >&2
  fi
}

# Arguments: expected exit code, command.
bash_case() {
  local json
  json=$(jq -n --arg command "$2" --arg cwd "${PROJECT}" \
    '{hook_event_name: "PreToolUse", tool_name: "Bash", cwd: $cwd, tool_input: {command: $command}}')
  expect "$1" guard-bash.sh "$2" "${json}" "HOME=/Users/tester"
}

# Arguments: expected exit code, file path.
path_case() {
  local json
  json=$(jq -n --arg file "$2" --arg cwd "${PROJECT}" \
    '{hook_event_name: "PreToolUse", tool_name: "Write", cwd: $cwd, tool_input: {file_path: $file, content: "x"}}')
  expect "$1" protect-paths.sh "$2" "${json}"
}

# Arguments: expected exit code, file path, old text, new text.
edit_case() {
  local json
  json=$(jq -n --arg file "$2" --arg old "$3" --arg new "$4" \
    '{hook_event_name: "PreToolUse", tool_name: "Edit", tool_input: {file_path: $file, old_string: $old, new_string: $new}}')
  expect "$1" block-suppressions.sh "Edit $2: $4" "${json}"
}

# Arguments: expected exit code, file path, content.
write_case() {
  local json
  json=$(jq -n --arg file "$2" --arg content "$3" \
    '{hook_event_name: "PreToolUse", tool_name: "Write", tool_input: {file_path: $file, content: $content}}')
  expect "$1" block-suppressions.sh "Write $2: $3" "${json}"
}

# --- block-suppressions.sh ---------------------------------------------------
edit_case "${BLOCK}" /p/a.ts "const a = 1;" $'// '"${TS_IGNORE}"$'\nconst a = 1;'
edit_case "${BLOCK}" /p/a.js "x" "/* ${ESLINT_OFF} no-console */"
edit_case "${BLOCK}" /p/a.js "x" "x // ${ESLINT_OFF}-next-line"
edit_case "${BLOCK}" /p/a.css "x" "/* ${STYLELINT_OFF} */"
edit_case "${BLOCK}" /p/a.php "x" "// ${PHPSTAN_IGNORE} argument.type"
edit_case "${BLOCK}" /p/a.php "x" "/** ${PHPSTAN_IGNORE}-next-line */"
edit_case "${BLOCK}" /p/a.php "x" "// ${PHPCS_IGNORE}"
edit_case "${BLOCK}" /p/a.php "x" "/* ${PHPCS_OFF} */"
edit_case "${BLOCK}" /p/a.py "x" "import os  # ${NOQA}: F401"
edit_case "${BLOCK}" /p/a.py "x" "import os  # ${NOQA_UPPER}: F401"
edit_case "${BLOCK}" /p/a.sh "x" "# ${SHELLCHECK_OFF}=SC2086"
edit_case "${BLOCK}" /p/a.py "x" "x = 1  # ${TYPE_IGNORE}"
edit_case "${BLOCK}" /p/a.py "x" "# ${PYLINT_OFF}=unused-import"
edit_case "${ALLOW}" /p/a.ts "// ${TS_IGNORE}"$'\nfoo()' "// ${TS_IGNORE}"$'\nbar()'
edit_case "${ALLOW}" /p/a.ts "// ${TS_IGNORE}" "const fixed = true;"
edit_case "${ALLOW}" /p/a.php "x" "echo 1;"
edit_case "${ALLOW}" /p/a.py "x" "# this is explained in ${NOQA} docs"
edit_case "${ALLOW}" /p/a.php "x" "\$name = 'phpcs';"
edit_case "${ALLOW}" /p/README.md "x" "Avoid // ${TS_IGNORE} in code."
write_case "${BLOCK}" /p/a.ts "// ${TS_IGNORE}"$'\nfoo()'
write_case "${BLOCK}" /p/a.py "x = 1  # ${NOQA}"
write_case "${ALLOW}" /p/a.ts "foo()"
write_case "${ALLOW}" /p/docs.md "Do not use ${ESLINT_OFF} comments."

# --- protect-paths.sh --------------------------------------------------------
path_case "${BLOCK}" "${PROJECT}/composer.lock"
path_case "${BLOCK}" "${PROJECT}/package-lock.json"
path_case "${BLOCK}" "${PROJECT}/vendor/cakephp/cakephp/src/Core/App.php"
path_case "${BLOCK}" "${PROJECT}/node_modules/left-pad/index.js"
path_case "${BLOCK}" "${PROJECT}/src/../composer.json"
path_case "${BLOCK}" "${PROJECT}/Composer.LOCK"
path_case "${BLOCK}" "${PROJECT}/Vendor/a/b.php"
path_case "${ALLOW}" "${PROJECT}/src/Application.php"
path_case "${ALLOW}" "${PROJECT}/src/vendor.php"
path_case "${ALLOW}" "${PROJECT}/composer.json"
path_case "${ALLOW}" "${PROJECT}/docs/environment.md"
expect "${ALLOW}" protect-paths.sh "project below a directory named vendor" \
  '{"cwd":"/home/u/vendor/app","tool_input":{"file_path":"/home/u/vendor/app/src/A.php"}}'
expect "${ALLOW}" protect-paths.sh "no file path" '{"cwd":"/p","tool_input":{}}'

# --- guard-bash.sh: blocked --------------------------------------------------
bash_case "${BLOCK}" 'rm -rf /'
bash_case "${BLOCK}" 'rm -rf /*'
bash_case "${BLOCK}" 'rm -rf ~'
bash_case "${BLOCK}" 'rm -rf ~/'
bash_case "${BLOCK}" 'rm -rf ~/*'
bash_case "${BLOCK}" "rm -rf \$HOME"
bash_case "${BLOCK}" "rm -rf \"\${HOME}\""
bash_case "${BLOCK}" 'rm -rf /Users/tester'
bash_case "${BLOCK}" 'rm -rf /usr'
bash_case "${BLOCK}" 'rm -fr .'
bash_case "${BLOCK}" 'rm -rf ./*'
bash_case "${BLOCK}" 'rm -rf ..'
bash_case "${BLOCK}" 'rm -rf *'
bash_case "${BLOCK}" 'rm -r -f /'
bash_case "${BLOCK}" 'rm --recursive --force /'
bash_case "${BLOCK}" 'rm -rf --no-preserve-root /tmp/x'
bash_case "${BLOCK}" "rm -rf \"\$dir\"/"
bash_case "${BLOCK}" "rm -rf \$dir/*"
bash_case "${BLOCK}" 'cd build && rm -rf /'
bash_case "${BLOCK}" 'ls; rm -rf ~'
bash_case "${BLOCK}" 'sudo rm -rf /usr'
bash_case "${BLOCK}" 'FOO=1 /bin/rm -rf /'
bash_case "${BLOCK}" 'find . -name x | xargs rm -rf /'
bash_case "${BLOCK}" "echo \$(rm -rf /)"
bash_case "${BLOCK}" "echo \"\$(rm -rf /)\""
bash_case "${BLOCK}" "echo \`rm -rf /\`"
bash_case "${BLOCK}" 'git push'
bash_case "${BLOCK}" 'git push origin main'
bash_case "${BLOCK}" 'git push --force'
bash_case "${BLOCK}" 'git push --force-with-lease'
bash_case "${BLOCK}" 'git --no-pager push origin main'
bash_case "${BLOCK}" 'GIT_DIR=.git /usr/bin/git push'
bash_case "${BLOCK}" 'git push -f origin main'
bash_case "${BLOCK}" 'git push origin main --force'
bash_case "${BLOCK}" 'git push -uf origin topic'
bash_case "${BLOCK}" 'git -C ../repo push origin +main'
bash_case "${BLOCK}" 'git -c user.name=x push --force'
bash_case "${BLOCK}" 'git status && git push -f'
bash_case "${BLOCK}" 'docker compose down -v'
bash_case "${BLOCK}" 'docker compose -f compose.yml down --volumes'
bash_case "${BLOCK}" 'docker-compose down -v'
bash_case "${BLOCK}" 'docker volume rm pgdata'
bash_case "${BLOCK}" 'docker volume prune'
bash_case "${BLOCK}" 'psql -c "DROP DATABASE app"'
bash_case "${BLOCK}" 'psql -c "drop table users"'
bash_case "${BLOCK}" 'docker compose exec db psql -U app -c "DROP TABLE users;"'
bash_case "${BLOCK}" 'echo "DROP TABLE users" | psql'
bash_case "${BLOCK}" $'psql <<SQL\nDROP TABLE users;\nSQL'
bash_case "${BLOCK}" $'mysql -e "DROP\nDATABASE app"'

bash_case "${BLOCK}" 'sudo -u root rm -rf /'
bash_case "${BLOCK}" 'nice -n 5 rm -rf ~'
bash_case "${BLOCK}" 'timeout 5 git push'
bash_case "${BLOCK}" 'watch -n 1 git push'
bash_case "${BLOCK}" 'find . -exec git push {} \;'
bash_case "${BLOCK}" 'git push</dev/null'
bash_case "${BLOCK}" 'git push>/dev/null'
bash_case "${BLOCK}" "git \$'push'"
bash_case "${BLOCK}" 'git --namespace foo push'
bash_case "${BLOCK}" "echo \$((1<<2)); git push"
bash_case "${BLOCK}" 'docker system prune --volumes'
bash_case "${BLOCK}" 'cat <<EOF | psql
drop table users;
EOF'
bash_case "${BLOCK}" 'docker exec db psql -c "DROP DATABASE app"'

# --- guard-bash.sh: allowed --------------------------------------------------
bash_case "${ALLOW}" 'rm -rf node_modules'
bash_case "${ALLOW}" 'rm -rf build/ dist/'
bash_case "${ALLOW}" 'rm -rf ./build'
bash_case "${ALLOW}" 'rm -rf /tmp/cache/app'
bash_case "${ALLOW}" 'rm -rf /Users/tester/.cache/app'
bash_case "${ALLOW}" "rm -rf \"\$TMPDIR/work\""
bash_case "${ALLOW}" 'rm -rf build > /tmp'
bash_case "${ALLOW}" 'rm notes.txt'
bash_case "${ALLOW}" 'rm -f /etc'
bash_case "${ALLOW}" 'git pull'
bash_case "${ALLOW}" 'git -C ../repo log'
bash_case "${ALLOW}" 'git commit -m "push the button"'
bash_case "${ALLOW}" 'git log --oneline -n 5'
bash_case "${ALLOW}" 'git commit -m "never run rm -rf / or git push --force"'
bash_case "${ALLOW}" "git commit -m 'drop table and psql notes'"
bash_case "${ALLOW}" $'git commit -m "$(cat <<\'EOF\'\nExplain rm -rf / and git push -f\nDROP TABLE users\nEOF\n)"'
bash_case "${ALLOW}" $'cat <<\'EOF\' > notes.txt\nrm -rf /\nEOF'
bash_case "${ALLOW}" $'cat <<-EOF\n\tgit push --force\n\tEOF\nls'
bash_case "${ALLOW}" 'echo "rm -rf /"'
bash_case "${ALLOW}" 'echo rm -rf / # a comment'
bash_case "${ALLOW}" '# rm -rf /'
bash_case "${ALLOW}" 'grep -r "docker compose down -v" docs'
bash_case "${ALLOW}" 'echo "DROP TABLE users"'
bash_case "${ALLOW}" 'docker compose down'
bash_case "${ALLOW}" 'docker compose up -d'
bash_case "${ALLOW}" 'docker volume ls'
bash_case "${ALLOW}" 'psql -c "SELECT 1"'
bash_case "${ALLOW}" 'ls -la'
bash_case "${ALLOW}" ''

bash_case "${ALLOW}" "echo \$((1<<2))"
bash_case "${ALLOW}" 'docker system prune'
bash_case "${ALLOW}" 'psql -c "SELECT 1"; git commit -m "drop table"'
bash_case "${ALLOW}" "echo \$'git push'"
bash_case "${ALLOW}" 'timeout 5 ls -la'

# --- log-bash.sh and bash-patterns.sh ----------------------------------------
log_json=$(jq -n --arg command 'API_TOKEN=abc123 curl -H "Authorization: Bearer xyz" https://example.test' \
  '{hook_event_name: "PostToolUse", tool_name: "Bash", cwd: "/work/project", tool_input: {command: $command}}')
expect "${ALLOW}" log-bash.sh "writes a log entry" "${log_json}" "HOME=${tmp_home}"
expect "${ALLOW}" log-bash.sh "writes a second entry" "${log_json}" "HOME=${tmp_home}"
escaped_json=$(jq -n --arg command 'cat &lt;&lt;EOF &amp;&amp; ls 2&gt;&amp;1' \
  '{hook_event_name: "PostToolUse", tool_name: "Bash", cwd: "/work/project", tool_input: {command: $command}}')
expect "${ALLOW}" log-bash.sh "writes an escaped command" "${escaped_json}" "HOME=${tmp_home}/escaped"
expect "${ALLOW}" log-bash.sh "ignores a call without a command" '{"tool_input":{}}' "HOME=${tmp_home}"

log_file=${tmp_home}/.claude/logs/bash.jsonl

# Arguments: description, then a command that must succeed.
check() {
  local name=$1
  shift
  if "$@"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    printf 'FAIL %s\n' "${name}" >&2
  fi
}
log_has() { grep -q -- "$1" "${log_file}"; }
log_lacks() { ! grep -q -- "$1" "${log_file}"; }
log_mode() { [[ $(stat -f %Lp "${log_file}") == 600 ]]; }
log_lines() { [[ $(wc -l <"${log_file}" | tr -d ' ') == 2 ]]; }
log_fields() { jq -e 'select(.time and .cwd and .command)' "${log_file}" >/dev/null; }

check "log has two entries" log_lines
check "log lines are JSON with time, cwd and command" log_fields
check "log keeps the command" log_has 'curl'
check "log redacts the token assignment" log_lacks 'abc123'
check "log redacts the bearer token" log_lacks 'xyz'
check "log file is private" log_mode
escaped_restored() { [[ $(jq -r .command "${tmp_home}/escaped/.claude/logs/bash.jsonl") == 'cat <<EOF && ls 2>&1' ]]; }
check "log restores HTML-escaped characters" escaped_restored

secrets_json=$(jq -n --arg command 'API_KEY="my secret value" mysql -phunter2 --password s3cr3t git clone https://user:pw0rd@host/r.git; curl -H "X-Api-Key: k3y" -u x ghp_abcdefghijklmnop' \
  '{hook_event_name: "PostToolUse", tool_name: "Bash", cwd: "/work/project", tool_input: {command: $command}}')
expect "${ALLOW}" log-bash.sh "writes a command with secrets" "${secrets_json}" "HOME=${tmp_home}/secrets"
secrets_log=${tmp_home}/secrets/.claude/logs/bash.jsonl
for secret in 'my secret' hunter2 s3cr3t pw0rd k3y ghp_abc; do
  secret_absent() { ! grep -q -- "${secret}" "${secrets_log}"; }
  check "log redacts ${secret}" secret_absent
done
printf '%s\n' '{"time":"t","cwd":"/","command":null}' >"${tmp_home}/null.jsonl"
null_ok() { "${HOOKS_DIR}/bash-patterns.sh" 5 "${tmp_home}/null.jsonl" >/dev/null; }
check "patterns tolerate a null command" null_ok

patterns=$("${HOOKS_DIR}/bash-patterns.sh" 5 "${log_file}")
check "patterns count the commands" test "${patterns}" = "$(printf '   2 API_TOKEN=<redacted> curl')"
expect 1 bash-patterns.sh "fails on a missing log" '' "HOME=${tmp_home}/none"
bad_count() { ! "${HOOKS_DIR}/bash-patterns.sh" abc "${log_file}" 2>/dev/null; }
check "patterns reject a non-numeric count" bad_count

printf '%s passed, %s failed\n' "${passed}" "${failed}"
((failed == 0))
