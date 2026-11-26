#!/usr/bin/env bash
# PreToolUse hook for Edit, Write and NotebookEdit. Blocks changes to lock
# files and dependency directories, which belong to a package manager, and to
# the .git directory, whose hooks and configuration change through Git itself.
# Environment files are left to the deny rules in settings.json.
#
# Directories are matched against the path relative to the project (the cwd of
# the session), so a checkout that lives under a directory named "vendor" is
# not blocked as a whole. Composer puts vendor/ only at the project root, so
# a project directory such as resources/views/vendor/ of Laravel stays
# editable; npm nests node_modules/, so it counts at any depth. The path is
# checked as given and again with its symbolic links resolved, so a link into
# .git or to a lock file is caught.
# Names are compared without regard to case, because macOS volumes usually
# ignore it.
#
# It fails open: a fault, such as a missing jq, ends with a non-blocking error
# and lets the edit through.
#
# Limits: only the file tools are checked, so a write through Bash is not seen,
# and a lock file that is not listed below is not protected. The macOS Bash 3.2
# is the target.
set -o nounset
set -o pipefail

readonly LOCK_FILES=('composer.lock' 'package-lock.json')
readonly ROOT_DEPENDENCY_DIRECTORIES=('vendor')
readonly NESTED_DEPENDENCY_DIRECTORIES=('node_modules')
readonly PROTECTED_DIRECTORY='.git'
# A chain of links is followed at most this many times, so a loop ends.
readonly MAX_LINK_DEPTH=10

# Blocks the edit with the reason. Arguments: the reason.
deny() {
  printf 'code-paths: %s\n' "$*" >&2
  exit 2
}

# Prints the path with its symbolic links resolved. The file may not exist yet,
# so the nearest existing ancestor is resolved and the rest is appended. Prints
# nothing when realpath fails, which leaves only the checks of the path as
# given. A link whose target does not exist yet is followed by hand.
# Arguments: the path, then the link depth (optional).
resolve_path() {
  local existing=$1 depth=${2:-0} rest='' resolved target
  while [[ ! -e "${existing}" && "${existing}" == */* ]]; do
    if [[ -L "${existing}" ]] && [[ "${depth}" -lt "${MAX_LINK_DEPTH}" ]] \
      && target=$(readlink -- "${existing}"); then
      [[ "${target}" == /* ]] || target="${existing%/*}/${target}"
      resolve_path "${target}${rest}" "$((depth + 1))"
      return 0
    fi
    rest="/${existing##*/}${rest}"
    existing=${existing%/*}
    [[ -n "${existing}" ]] || existing=/
  done
  resolved=$(realpath -- "${existing}" 2>/dev/null) || return 0
  printf '%s%s' "${resolved%/}" "${rest}"
}

# Blocks an edit in a dependency directory. Arguments: the relative path.
deny_dependency() {
  deny "$1 is in a dependency directory that a package manager manages." \
    "Change the project's own code, or the dependency through the package" \
    "manager."
}

# Checks one spelling of the path. Arguments: the file, the project directory.
check_path() {
  local target=$1 project=$2 relative base name
  relative=${target}
  if [[ -n "${project}" && "${target}" == "${project}"/* ]]; then
    relative=${target#"${project}"/}
  fi
  base=${target##*/}

  shopt -s nocasematch
  for name in "${LOCK_FILES[@]}"; do
    if [[ "${base}" == "${name}" ]]; then
      deny "${base} is generated. Change dependencies through the package" \
        "manager so that the lock file stays consistent."
    fi
  done
  for name in "${ROOT_DEPENDENCY_DIRECTORIES[@]}"; do
    [[ "${relative}/" == "${name}"/* ]] && deny_dependency "${relative}"
  done
  for name in "${NESTED_DEPENDENCY_DIRECTORIES[@]}"; do
    [[ "/${relative}/" == */"${name}"/* ]] && deny_dependency "${relative}"
  done
  if [[ "/${relative}/" == */"${PROTECTED_DIRECTORY}"/* ]]; then
    deny "${relative} is in ${PROTECTED_DIRECTORY}. Change its hooks and" \
      "configuration through Git commands, after asking the user."
  fi
  shopt -u nocasematch
}

input=$(cat) || exit 1
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' \
  <<<"${input}") || exit 1
cwd=$(jq -r '.cwd // empty' <<<"${input}") || exit 1
[[ -n "${file}" ]] || exit 0

# An unnormalised path could hide the real target from the checks below.
if [[ "${file}" == */../* || "${file}" == */.. || "${file}" == ../* \
  || "${file}" == .. ]]; then
  deny "the path ${file} contains '..'. Use a normalised absolute path."
fi

check_path "${file}" "${cwd}"

if [[ "${file}" == /* ]]; then
  resolved_file=$(resolve_path "${file}")
  resolved_cwd=$(resolve_path "${cwd}")
  if [[ -n "${resolved_file}" && "${resolved_file}" != "${file}" ]]; then
    check_path "${resolved_file}" "${resolved_cwd:-${cwd}}"
  fi
fi
exit 0
