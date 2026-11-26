#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks Git commands that skip the Git hooks or set
# configuration for one command, which git.md forbids: --no-verify and its
# abbreviations, commit -n and am -n, git -c and --config-env before the
# subcommand, GIT_CONFIG_* variables, which give configuration through the
# environment, and git${IFS}…, which hides the options from the checks.
# Configuration such as core.hooksPath or core.pager can run a program; the
# sandbox already keeps Git from writing it to .git/config or ~/.gitconfig.
#
# The command is split into simple commands by lib/shell.sh, which drops quoted
# text with spaces and heredoc bodies, so a commit message that mentions
# --no-verify is not mistaken for the option.
#
# Limits: bash -c, eval, scripts, aliases and options inside a variable are not
# followed, and GIT_CONFIG_* counts in any word, also as an argument of echo.
# A quoted value without spaces stays a word, so git commit -m -n is blocked.
# This is a safety net for mistakes, not a sandbox. The macOS Bash 3.2 is the
# target.
set -o nounset
set -o pipefail

# Without the library the hook exits with 1, which blocks the call through
# onFailure "block" in settings.json.
# shellcheck source=lib/shell.sh
source "${BASH_SOURCE[0]%/*}/lib/shell.sh" || exit 1

GIT_CONFIG_RE='^GIT_CONFIG_(COUNT|KEY_[0-9]+|VALUE_[0-9]+|PARAMETERS'
GIT_CONFIG_RE+='|GLOBAL|SYSTEM)='
readonly GIT_CONFIG_RE
readonly NO_VERIFY=--no-verify

# Blocks the call with a reason for Claude.
deny() {
  printf 'git: %s\n' "$*" >&2
  exit 2
}

# Succeeds for --no-verify and for its abbreviations from --no-v on, which Git
# accepts when they are unambiguous.
is_no_verify() {
  [[ "$1" == --no-v* && "${NO_VERIFY}" == "$1"* ]]
}

# Succeeds for a short option cluster that includes -n, which skips the hooks
# like --no-verify in git commit and git am. An option that takes a value
# (-m, -F, -C, -c, -t, -U, and the optional -u and -S of commit) ends the
# cluster, because the rest of the word is its value: -amn is -a -m n, and
# -uno is -u no.
is_short_no_verify() {
  local cluster=${1#-} char index
  [[ "$1" == -[!-]* ]] || return 1
  for ((index = 0; index < ${#cluster}; index++)); do
    char=${cluster:index:1}
    case ${char} in
      n) return 0 ;;
      m | F | C | c | t | U | u | S) return 1 ;;
    esac
  done
  return 1
}

# Checks the words after git. Options before the subcommand are global: -c and
# --config-env set configuration, and -C, --git-dir, --work-tree, --namespace
# and --attr-source take a separate value. Everything after -- is a path.
check_git() {
  local arg subcommand='' skip_next=0
  for arg in "$@"; do
    if [[ "${skip_next}" -eq 1 ]]; then
      skip_next=0
      continue
    fi
    [[ "${arg}" == -- ]] && return 0
    if [[ -z "${subcommand}" ]]; then
      case ${arg} in
        -c | -c?* | --config-env | --config-env=*)
          deny "git -c and --config-env set configuration that can run a" \
            "program (core.hooksPath, core.pager, an alias). Leave the" \
            "configuration as it is, or ask the user."
          ;;
        -C | --git-dir | --work-tree | --namespace | --attr-source)
          skip_next=1
          ;;
        -*) ;;
        *) subcommand=${arg} ;;
      esac
      continue
    fi
    if is_no_verify "${arg}"; then
      deny "${arg} skips the Git hooks. Fix what the hook reports instead."
    fi
    if [[ "${subcommand}" == commit || "${subcommand}" == am ]] \
      && is_short_no_verify "${arg}"; then
      deny "${subcommand} ${arg} includes -n, which skips the Git hooks." \
        "Fix what the hook reports instead."
    fi
  done
}

# Checks one simple command. Argument: the command as a line of words.
check_segment() {
  local -a words=()
  local index word command_word

  read -r -a words <<<"$1"
  [[ "${#words[@]}" -gt 0 ]] || return 0

  for word in "${words[@]}"; do
    if [[ "${word}" =~ ${GIT_CONFIG_RE} ]]; then
      deny "${word%%=*} gives Git configuration through the environment," \
        "which can run a program. Leave the configuration as it is, or ask" \
        "the user."
    fi
  done

  index=$(command_index "${words[@]}")
  command_word=${words[index]:-}
  # git${IFS}commit is not git here, but runs git.
  if [[ "${command_word##*/}" == git?* ]] \
    && has_ifs_expansion "${command_word}"; then
    deny "\$IFS in the command word is split into a command line after the" \
      "checks, as in git\${IFS}commit. Write the command with plain spaces."
  fi
  if [[ "${command_word##*/}" == git ]]; then
    check_git "${words[@]:index+1}"
  fi
}

if ! input=$(cat); then
  deny "could not read the hook input."
fi
if ! command=$(jq -r '.tool_input.command // empty' <<<"${input}"); then
  deny "could not parse the hook input."
fi
[[ "${command}" == *git* || "${command}" == *GIT_CONFIG* ]] || exit 0

if ! code=$(shell_segments "${command}"); then
  deny "could not parse the command."
fi

while IFS= read -r segment; do
  [[ "${segment}" == '|' ]] && continue
  # A pattern match, because stripping the blanks is quadratic in Bash 3.2.
  [[ "${segment}" == *[![:space:]]* ]] || continue
  check_segment "${segment}"
done <<<"${code}"
exit 0
