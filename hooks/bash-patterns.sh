#!/usr/bin/env bash
# Prints the most frequent command patterns from the Bash log, so repeated
# habits (python3 -c, heredocs, long one-off pipelines) become visible and can be
# turned into a rule, a script or a permission.
#
# A pattern is the first two words of the first line of a command, plus a marker
# for heredocs and multi-line commands.
#
# Usage: bash-patterns.sh [count] [log file]   (default: 20 patterns from
# ~/.claude/logs/bash.jsonl)
set -euo pipefail

count=${1:-20}
log_file=${2:-${HOME}/.claude/logs/bash.jsonl}

if [[ ! ${count} =~ ^[0-9]+$ ]]; then
  printf 'bash-patterns: the count must be a number, got "%s".\n' "${count}" >&2
  exit 1
fi

if [[ ! -r ${log_file} ]]; then
  printf 'bash-patterns: cannot read %s. Nothing has been logged yet.\n' "${log_file}" >&2
  exit 1
fi

jq -r '
  (.command // "")
  | . as $command
  | ((split("\n")[0] // "") | split(" ") | map(select(. != "")) | .[0:2] | join(" ")) as $head
  | $head
    + (if ($command | test("<<")) then " <<heredoc" else "" end)
    + (if ($command | contains("\n")) then " (multi-line)" else "" end)
' "${log_file}" | sort | uniq -c | sort -rn | sed -n "1,${count}p"
