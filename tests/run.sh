#!/usr/bin/env bash
# Runs every tests/*.test.sh in its own process
# and exits 0 only when all of them pass.
set -o nounset
set -o pipefail

TESTS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
readonly TESTS_DIR
ROOT_DIR=$(cd -- "${TESTS_DIR}/.." && pwd) || exit 1
readonly ROOT_DIR
# The terminal shows only pass or fail; every detail goes to this log.
readonly DEBUG_LOG="${ROOT_DIR}/debug.log"
readonly ROOT_PREFIX="${ROOT_DIR}/"
readonly RELATIVE='./'
failed=0

# Colours only when both streams are a terminal and NO_COLOR is unset, so
# that piped output and CI logs stay plain text.
if [[ -t 1 && -t 2 && -z "${NO_COLOR:-}" ]]; then
  readonly RED=$'\033[31m' GREEN=$'\033[32m' NC=$'\033[0m'
else
  readonly RED='' GREEN='' NC=''
fi

shopt -s nullglob
test_files=("${TESTS_DIR}"/*.test.sh)
shopt -u nullglob

if [[ "${#test_files[@]}" -eq 0 ]]; then
  printf 'no tests in %s\n' "${TESTS_DIR}" >&2
  exit 1
fi

# A log from an earlier run would describe failures that no longer exist.
rm -f -- "${DEBUG_LOG}" || exit 1

for test_file in "${test_files[@]}"; do
  name=$(basename -- "${test_file}")
  if details=$("${BASH}" -- "${test_file}" 2>&1); then
    printf '%spass%s %s\n' "${GREEN}" "${NC}" "${name}"
  else
    status=$?
    printf '%sfail%s %s\n' "${RED}" "${NC}" "${name}"
    failed=1
    # A test that fails without output still leaves a trace in the log.
    [[ -n "${details}" ]] || details="${name}: exit ${status}"
  fi
  # Paths in the repository are logged relative to its root, as ./path.
  if [[ -n "${details}" ]]; then
    printf '%s\n' "${details//"${ROOT_PREFIX}"/${RELATIVE}}" >>"${DEBUG_LOG}"
  fi
done

if [[ -s "${DEBUG_LOG}" ]]; then
  printf 'details: %s\n' "$(basename -- "${DEBUG_LOG}")"
else
  rm -f -- "${DEBUG_LOG}" || exit 1
fi

exit "${failed}"
