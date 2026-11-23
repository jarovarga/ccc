#!/usr/bin/env bash
# Checks that the always-loaded core rules stay within the byte ceiling:
# CLAUDE.md and every rule without paths in its frontmatter.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly LIMIT_BYTES=8192

# Succeeds when the file opens with frontmatter that has a paths key, which
# makes Claude Code load the rule only for matching files.
has_paths() {
  local line
  {
    IFS= read -r line || return 1
    [[ "${line}" == '---' ]] || return 1
    while IFS= read -r line; do
      [[ "${line}" == '---' ]] && return 1
      [[ "${line}" == paths:* ]] && return 0
    done
  } <"$1"
  return 1
}

begin 'always-loaded core rules within the ceiling'
total=0
for file in "${CCC_ROOT}/CLAUDE.md" "${CCC_ROOT}"/rules/*.md; do
  if [[ ! -f "${file}" ]]; then
    fail "${file} is missing"
    continue
  fi
  has_paths "${file}" && continue
  size=$(wc -c <"${file}") || exit 1
  total=$((total + size))
done
[[ "${total}" -le "${LIMIT_BYTES}" ]] \
  || fail "${total} B, limit ${LIMIT_BYTES} B"

finish
