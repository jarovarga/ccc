#!/usr/bin/env bash
# PreToolUse hook for Edit, Write and NotebookEdit. Blocks new content that
# silences a linter or static analyser instead of fixing the cause, which
# security.md forbids ("adding inline exceptions").
#
# A suppression counts only after a comment marker, so prose that names a tool
# does not trigger it, and Markdown files are skipped. For Edit the count is
# compared with the replaced text, so an edit next to an existing suppression
# passes but one that adds a suppression does not. Write and NotebookEdit carry
# no old text, so every suppression in their content counts, also one that the
# file already had.
#
# It fails open: a fault, such as a missing jq, ends with a non-blocking error
# and lets the edit through, so the rule stays in the rules as well.
#
# Limits: only the file tools are checked, so a write through Bash is not seen,
# and a suppression of a tool that is not listed below is not detected. The
# macOS Bash 3.2 is the target.
set -o nounset
set -o pipefail

# Extended regular expressions, matched without regard to case.
readonly MARKERS=('//' '#' '/\*' '\*' '--' '<!--')
readonly TOOLS=(
  # PHP
  '@phpstan-ignore' '@psalm-suppress' '@phan-suppress'
  'phpcs:(ignore|disable)' '@codingStandardsIgnore'
  # JavaScript, TypeScript and CSS
  'eslint-disable' 'stylelint-disable' '@ts-(ignore|nocheck|expect-error)'
  'prettier-ignore'
  # HTML
  '\[?html-validate-disable'
  # Shell and Python
  'shellcheck[[:space:]]+disable' 'type:[[:space:]]*ignore'
  'pylint:[[:space:]]*disable'
)

# Prints the arguments joined with |.
join_alternatives() {
  local IFS='|'
  printf '%s' "$*"
}

SUPPRESSION="($(join_alternatives "${MARKERS[@]}"))[[:space:]]*"
SUPPRESSION+="($(join_alternatives "${TOOLS[@]}"))"
readonly SUPPRESSION

# Prints the number of suppressions in the text. Argument: the text.
count_suppressions() {
  local matches status=0
  matches=$(grep -Eio -- "${SUPPRESSION}" <<<"$1") || status=$?
  if [[ "${status}" -gt 1 ]]; then
    return 1
  fi
  if [[ -z "${matches}" ]]; then
    printf '0\n'
    return 0
  fi
  grep -c '' <<<"${matches}"
}

input=$(cat) || exit 1
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' \
  <<<"${input}") || exit 1

shopt -s nocasematch
if [[ "${file}" == *.md || "${file}" == *.markdown ]]; then
  exit 0
fi
shopt -u nocasematch

new_text=$(jq -r '.tool_input.new_string // .tool_input.content
  // .tool_input.new_source // empty' <<<"${input}") || exit 1
old_text=$(jq -r '.tool_input.old_string // empty' <<<"${input}") || exit 1

new_count=$(count_suppressions "${new_text}") || exit 1
old_count=$(count_suppressions "${old_text}") || exit 1

if [[ "${new_count}" -gt "${old_count}" ]]; then
  found=$(grep -Eio -m 1 -- "${SUPPRESSION}" <<<"${new_text}")
  printf 'code-suppressions: the change adds a suppression (%s). ' \
    "${found}" >&2
  printf 'Fix the underlying problem instead of silencing the check; ' >&2
  printf 'if it truly cannot be fixed, ask the user first.\n' >&2
  exit 2
fi
exit 0
