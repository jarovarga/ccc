# shellcheck shell=bash
# Shared helpers for tests/*.test.sh. Sourced by each test file, not run.

CCC_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd) || exit 1
readonly CCC_ROOT
TEST_NAME=$(basename -- "$0")
readonly TEST_NAME

failures=0
case_name=

# Starts a named case; failures are reported under this name.
begin() {
  case_name=$1
}

# Reports a failure on stderr, which run.sh sends to debug.log. Paths in the
# repository are shown as ./path; variables, because Bash 3.2 mangles a
# literal replacement.
fail() {
  local root_prefix="${CCC_ROOT}/" relative='./' message
  message="${TEST_NAME}: ${case_name}: $1"
  printf '%s\n' "${message//"${root_prefix}"/${relative}}" >&2
  failures=$((failures + 1))
}

assert_jq() {
  local error
  if error=$(jq -e "$2" "$1" 2>&1 >/dev/null); then
    return 0
  fi
  if [[ -n "${error}" ]]; then
    fail "jq failed on $1: ${error}"
    return
  fi
  fail "$1 does not match $2"
}

# Copies a hook and the shared hooks/lib into a directory, laid out as in
# ~/.claude/hooks, so that the hook finds its library as it does when
# installed. Prints the path of the copied hook.
# Arguments: the hook, the directory.
install_hook() {
  mkdir -p -- "$2/hooks" || return 1
  cp -p -- "$1" "$2/hooks/" || return 1
  cp -pR -- "${CCC_ROOT}/hooks/lib" "$2/hooks/" || return 1
  printf '%s\n' "$2/hooks/${1##*/}"
}

# Ends the test file: exit 0 when no check failed.
finish() {
  if [[ "${failures}" -eq 0 ]]; then
    exit 0
  fi
  exit 1
}
