#!/usr/bin/env bash
# Starts Claude Code in the repository with its CLAUDE.md, rules and settings
# as the user configuration, isolated from the real one in ~/.claude.
set -o nounset
set -o pipefail

TESTS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
readonly TESTS_DIR
ROOT_DIR=$(cd -- "${TESTS_DIR}/.." && pwd) || exit 1
readonly ROOT_DIR
# Claude Code rewrites the settings file in its config directory, so it gets
# copies; login and sessions stay there between runs.
readonly CONFIG_DIR="${ROOT_DIR}/.sandbox/qa"

mkdir -p -- "${CONFIG_DIR}" || exit 1
cp -- "${ROOT_DIR}/CLAUDE.md" "${CONFIG_DIR}/" || exit 1
# A rule removed from the repository must not linger in the copy.
rm -rf -- "${CONFIG_DIR}/rules" || exit 1
cp -R -- "${ROOT_DIR}/rules" "${CONFIG_DIR}/" || exit 1

# Claude Code also loads CLAUDE.md and rules from every parent of the working
# directory, which reaches the real ~/.claude; the root CLAUDE.md is already
# loaded as the user file and would otherwise load again as the project one.
jq --arg home "${HOME}" --arg root "${ROOT_DIR}" \
  '. + {claudeMdExcludes: [
    $home + "/.claude/CLAUDE.md",
    $home + "/.claude/rules/**",
    $root + "/CLAUDE.md"
  ]}' "${ROOT_DIR}/settings.json" >"${CONFIG_DIR}/settings.json" || exit 1

cd -- "${ROOT_DIR}" || exit 1
CLAUDE_CONFIG_DIR="${CONFIG_DIR}" exec claude "$@"
