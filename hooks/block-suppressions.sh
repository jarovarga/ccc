#!/usr/bin/env bash
# PreToolUse hook for Edit and Write. Blocks new content that silences a linter
# or static analyser instead of fixing the cause.
#
# A suppression only counts after a comment marker, so prose that merely names a
# tool does not trigger it, and Markdown files are skipped. For Edit the count
# is compared with the text being replaced, so touching a line next to an
# existing suppression is allowed but adding one is not. Write is not compared
# with the file on disk, because reading arbitrary files from a hook could open
# a credential; every suppression in written content therefore counts.
set -euo pipefail

readonly SUPPRESSION='(//|#|/\*|\*|--|<!--)[[:space:]]*(@phpstan-ignore|phpcs:(ignore|disable)|@codingStandardsIgnore|stylelint-disable|eslint-disable|@ts-ignore|noqa|shellcheck[[:space:]]+disable|type:[[:space:]]*ignore|pylint:[[:space:]]*disable)'

# Prints the number of suppressions in the text on stdin.
count_suppressions() {
  { grep -Eio -- "${SUPPRESSION}" || true; } | wc -l | tr -d ' '
}

input=$(cat)

file=$(jq -r '.tool_input.file_path // empty' <<<"${input}")
case ${file} in
  *.md | *.markdown) exit 0 ;;
esac

new_text=$(jq -r '.tool_input.new_string // .tool_input.content // empty' <<<"${input}")
old_text=$(jq -r '.tool_input.old_string // empty' <<<"${input}")

new_count=$(count_suppressions <<<"${new_text}")
old_count=$(count_suppressions <<<"${old_text}")

if ((new_count > old_count)); then
  found=$(grep -Eio -- "${SUPPRESSION}" <<<"${new_text}" | head -n 1)
  printf 'block-suppressions: the change adds a suppression (%s). Fix the underlying problem instead of silencing the check; if it truly cannot be fixed, ask the user first.\n' "${found}" >&2
  exit 2
fi
