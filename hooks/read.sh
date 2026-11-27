#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks cat, head, tail, sed and awk when they read
# a file, which CLAUDE.md forbids: sed, awk, tail and loops do not load the
# path-scoped rules, while Read does. A single-file cat or head loads them but
# is blocked too, because Edit needs an earlier Read of the file. The same
# commands pass when they read a pipe or a heredoc, as in git log | head, and
# tail -f passes, because it follows a growing file, which Read cannot.
#
# A file is the target of < or an operand that is not an option, not -, not a
# number, not the program of sed or awk, not an awk assignment such as x=1,
# and not the +5 of tail. The words after >, >> and <<< are not read.
#
# The command is split into simple commands by lib/shell.sh, which drops quoted
# text with spaces and heredoc bodies, so a commit message that mentions
# cat file is not mistaken for the command.
#
# Limits: bash -c, eval, scripts, aliases, xargs and file names inside a
# variable are not followed; other commands that read files, such as less,
# grep, wc or the GNU names gsed and gawk, are not checked; a file named only
# by digits counts as a descriptor; and the GNU order tail README.md -f is
# blocked. This is a safety net for mistakes, not a
# sandbox. The macOS Bash 3.2 is the target.
set -o nounset
set -o pipefail

# Without the library the hook exits with 1, which blocks the call through
# onFailure "block" in settings.json.
# shellcheck source=lib/shell.sh
source "${BASH_SOURCE[0]%/*}/lib/shell.sh" || exit 1

readonly READERS_RE='(^|[^[:alnum:]_])(cat|head|tail|sed|awk)([^[:alnum:]_]|$)'

# Blocks the call with a reason for Claude.
deny() {
  printf 'read: %s\n' "$*" >&2
  exit 2
}

# Succeeds for an option of the command that takes the next word as its value.
# Arguments: the command, the option.
takes_value() {
  case "$1:$2" in
    head:-n | head:-c | tail:-n | tail:-c | tail:-b) return 0 ;;
    head:--lines | head:--bytes | tail:--lines | tail:--bytes) return 0 ;;
    sed:--expression | sed:--file) return 0 ;;
    awk:-F | awk:-v | awk:-f) return 0 ;;
  esac
  # A short option cluster that ends in the program option, such as sed -ne,
  # takes the program as the next word.
  [[ "$1" == sed && "$2" == -[!-]* && "$2" == *[ef] ]]
}

# Succeeds for an option that gives sed or awk its program, so that the first
# operand is a file and not the program.
gives_program() {
  case "$1" in
    sed)
      [[ ("$2" == -[!-]* && "$2" == *[ef]*) || "$2" == --expression* \
        || "$2" == --file* ]]
      ;;
    awk) [[ "$2" == -f* ]] ;;
    *) return 1 ;;
  esac
}

# Succeeds for tail -f, -F and --follow.
is_follow() {
  [[ "$1" == tail \
    && (("$2" == -[!-]* && "$2" == *[fF]*) || "$2" == --follow*) ]]
}

# Succeeds when the command reads a file. Arguments: the command name, then
# the words after it.
reads_file() {
  local name=$1 program=0 options_done=0 index=1 word next
  local -a words=("$@")
  local count=${#words[@]}

  [[ "${name}" == sed || "${name}" == awk ]] || program=1
  while ((index < count)); do
    word=${words[index]}
    next=${words[index + 1]:-}
    index=$((index + 1))
    case "${word}" in
      # A < before another < is the process substitution of < <(…), whose
      # command lib/shell.sh puts on a line of its own.
      '<')
        [[ -n "${next}" && "${next}" != '<' ]] && return 0
        continue
        ;;
      # lib/shell.sh splits >> into two words >.
      '>')
        while [[ "${words[index]:-}" == '>' ]]; do
          index=$((index + 1))
        done
        index=$((index + 1))
        continue
        ;;
      '<<<')
        index=$((index + 1))
        continue
        ;;
      '<<H') continue ;;
    esac
    # The legacy tail +5 counts from the start.
    [[ "${name}" == tail && "${word}" =~ ^\+[0-9]+$ ]] && continue
    if ((!options_done)) && [[ "${word}" == -?* ]]; then
      if [[ "${word}" == -- ]]; then
        options_done=1
        continue
      fi
      is_follow "${name}" "${word}" && return 1
      gives_program "${name}" "${word}" && program=1
      takes_value "${name}" "${word}" && index=$((index + 1))
      continue
    fi
    [[ "${word}" == - ]] && continue
    if ((!program)); then
      program=1
      continue
    fi
    # A number is the descriptor of a redirect, as lib/shell.sh leaves 2>&1 as
    # the words 2 and 1, and 2>/dev/null as 2, > and the target. It is checked
    # after the program, so awk 1 README.md still reads a file.
    [[ "${word}" =~ ^[0-9]+$ ]] && continue
    [[ "${name}" == awk && "${word}" =~ ${ASSIGNMENT_RE} ]] && continue
    return 0
  done
  return 1
}

# Checks one simple command. Argument: the command as a line of words.
check_segment() {
  local -a words=()
  local index name

  read -r -a words <<<"$1"
  [[ "${#words[@]}" -gt 0 ]] || return 0
  index=$(command_index "${words[@]}")
  name=${words[index]:-}
  name=${name##*/}
  case "${name}" in
    cat | head | tail | sed | awk) ;;
    *) return 0 ;;
  esac
  if reads_file "${name}" "${words[@]:index+1}"; then
    deny "${name} reads a file in Bash, which may skip the path-scoped" \
      "rules. Read files with the Read tool and search them with Grep and" \
      "Glob; change them with Edit."
  fi
}

if ! input=$(cat); then
  deny "could not read the hook input."
fi
if ! command=$(jq -r '.tool_input.command // empty' <<<"${input}"); then
  deny "could not parse the hook input."
fi
[[ "${command}" =~ ${READERS_RE} ]] || exit 0

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
