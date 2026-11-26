#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks a call that runs gh together with another
# command or with a redirect, and gh with a host other than github.com.
#
# gh is excluded from the sandbox, but only when every command of the call is gh
# and it redirects nothing but file descriptors, such as 2>&1 (see
# excludedCommands in settings.json). A piped or chained gh, or one that reads
# or writes a file, even /dev/null, stays in the sandbox, where it cannot read
# its configuration or reach the network. Outside the sandbox nothing limits
# where gh sends a request, so only github.com is allowed.
#
# The command is split into simple commands by lib/shell.sh, which drops quoted
# text, so a title that contains "|" is not mistaken for a pipe.
#
# Limits: bash -c, eval, scripts and aliases are not followed, and a host inside
# a variable (gh repo view $REPO) is not seen. This is a safety net for mistakes,
# not a sandbox. The macOS Bash 3.2 is the target, so no associative arrays.
set -o nounset
set -o pipefail

# Without the library the hook exits with 1, which blocks the call through
# onFailure "block" in settings.json.
# shellcheck source=../../../hooks/lib/shell.sh
source "${BASH_SOURCE[0]%/*}/lib/shell.sh" || exit 1

readonly GH_URL_RE='^[A-Za-z][A-Za-z0-9+.-]*://([^/]*)'
# A host is a dotted name, an IPv4 address or localhost. A bare label before two
# path segments (repos/owner/repo) is a path, so it is not taken for a host.
readonly GH_HOST_PATTERN='[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}|[0-9]{1,3}(\.[0-9]{1,3}){3}'
readonly GH_REPO_HOST_RE="^(${GH_HOST_PATTERN}|localhost)/[^/]+/[^/]+"
# The SCP form of a Git remote, git@github.com:owner/repo.git, with the user optional.
readonly GH_SCP_RE="^([A-Za-z0-9._-]+@)?(${GH_HOST_PATTERN}):[^:]*/"
# With a user in front, a single-label host such as git@evil:owner/repo is a host too.
readonly GH_SCP_USER_RE='^[A-Za-z0-9._-]+@([A-Za-z0-9-]+):[^:]*/'

GH_SEEN=0
SEGMENT_COUNT=0

# Blocks the call with a reason for Claude.
deny() {
  printf 'github: %s\n' "$*" >&2
  exit 2
}

# Succeeds when one of the words is a redirect operator left by the awk program.
has_redirect() {
  local word
  for word in "$@"; do
    case ${word} in
      '<' | '>' | '<<<' | '<<H') return 0 ;;
    esac
  done
  return 1
}

# Succeeds for github.com, the only host gh may reach. Argument: a host, with
# an optional user and port.
gh_host_allowed() {
  local host=${1#*@}
  host=$(printf '%s' "${host%%:*}" | tr '[:upper:]' '[:lower:]')
  [[ ${host} == github.com || ${host} == www.github.com ]]
}

# Prints the host that a word of a gh command names, if any: a URL, a
# HOST/OWNER/REPO (also after --repo=) or an SCP-style remote.
gh_word_host() {
  local candidate=$1
  if [[ ${candidate} == --repo=* ]]; then
    candidate=${candidate#*=}
  fi
  if [[ ${candidate} =~ ${GH_URL_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  elif [[ ${candidate} =~ ${GH_REPO_HOST_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  elif [[ ${candidate} =~ ${GH_SCP_RE} ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
  elif [[ ${candidate} =~ ${GH_SCP_USER_RE} ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

# Denies a gh command that names a host other than github.com, also through
# --hostname. Arguments: the words after gh.
check_gh_hosts() {
  local word host expect_host=0
  for word in "$@"; do
    if ((expect_host)); then
      host=${word}
      expect_host=0
    elif [[ ${word} == --hostname ]]; then
      expect_host=1
      continue
    elif [[ ${word} == --hostname=* ]]; then
      host=${word#*=}
    else
      host=$(gh_word_host "${word}")
    fi
    if [[ -n ${host} ]] && ! gh_host_allowed "${host}"; then
      deny "gh with the host ${host}: gh runs outside the sandbox, so nothing limits where the request goes. Only github.com is allowed; ask the user for any other host."
    fi
  done
}

# Checks the words of a simple command that runs gh. Arguments: the index of gh
# in the words, then the words.
check_gh() {
  local index=$1 position word
  shift
  local -a words=("$@")

  for word in "${words[@]}"; do
    if has_ifs_expansion "${word}"; then
      deny "\$IFS in an argument of gh is split into several words after the checks. Write the arguments with plain spaces."
    fi
  done
  if has_redirect "${words[@]}"; then
    deny "gh with a redirect (>, <, a heredoc or a here-string) stays in the sandbox and fails there; only 2>&1 is allowed. Run gh alone and filter with --jq, --json or --limit, and let the output come back to you instead of writing it to a file."
  fi
  for ((position = 0; position < index; position++)); do
    if [[ ${words[position]} == GH_HOST=* ]] && ! gh_host_allowed "${words[position]#*=}"; then
      deny "GH_HOST=${words[position]#*=} points gh at another host, and gh runs outside the sandbox. Only github.com is allowed; ask the user for any other host."
    fi
  done
  check_gh_hosts "${words[@]:index+1}"
}

# Checks one simple command. Argument: the command as a line of words.
check_segment() {
  local -a words=()
  local index command_word

  read -r -a words <<<"$1"
  ((${#words[@]} > 0)) || return 0

  index=$(command_index "${words[@]}")
  command_word=${words[index]:-}
  # gh${IFS}repo is not gh here, but runs gh.
  if [[ ${command_word##*/} == gh?* ]] && has_ifs_expansion "${command_word}"; then
    deny "\$IFS in the command word is split into a command line after the checks, as in gh\${IFS}repo. Write the command with plain spaces."
  fi
  if [[ ${command_word##*/} == gh ]]; then
    GH_SEEN=1
    check_gh "${index}" "${words[@]}"
  fi
}

if ! input=$(cat); then
  deny "could not read the hook input."
fi
if ! command=$(jq -r '.tool_input.command // empty' <<<"${input}"); then
  deny "could not parse the hook input."
fi
[[ ${command} == *gh* ]] || exit 0

if ! code=$(shell_segments "${command}"); then
  deny "could not parse the command."
fi

while IFS= read -r segment; do
  [[ ${segment} == '|' ]] && continue
  # A pattern match, because stripping the blanks is quadratic in Bash 3.2.
  [[ ${segment} == *[![:space:]]* ]] || continue
  SEGMENT_COUNT=$((SEGMENT_COUNT + 1))
  check_segment "${segment}"
done <<<"${code}"

if ((GH_SEEN && SEGMENT_COUNT > 1)); then
  deny "gh shares the call with another command (a pipe, && or ;), so the whole call stays in the sandbox and gh fails there. Run gh alone and filter with --jq, --json or --limit."
fi
exit 0
