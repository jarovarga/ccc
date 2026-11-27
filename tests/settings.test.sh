#!/usr/bin/env bash
# Checks the keys and the security-relevant values of the root settings.json.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly CORE="${CCC_ROOT}/settings.json"

begin 'only core keys'
assert_jq "${CORE}" 'keys == [
  "attribution", "autoCompactWindow", "autoContinueAtUsageLimit",
  "bashOutputMaxChars", "cleanupPeriodDays",
  "disableClaudeAiConnectors", "disableSkillShellExecution",
  "enableArtifact", "env", "hooks", "includeGitInstructions",
  "minimumVersion", "permissions",
  "remoteControlAtStartup", "respectGitignore", "sandbox", "statusLine",
  "syncClaudeAiSkills"
]'
assert_jq "${CORE}" '.hooks == {"PreToolUse": [{"matcher": "Bash",
  "hooks": [{"command": "~/.claude/hooks/git.sh", "onFailure": "block",
    "timeout": 10, "type": "command"},
    {"command": "~/.claude/hooks/read.sh", "onFailure": "block",
    "timeout": 10, "type": "command"}]}]}'
assert_jq "${CORE}" '.permissions | keys == [
  "additionalDirectories", "allow", "ask",
  "blockReadsOutsideWorkingDirectories",
  "blockWritesOutsideWorkingDirectories", "deny",
  "disableBypassPermissionsMode"
]'
assert_jq "${CORE}" '.sandbox | keys == [
  "allowUnsandboxedCommands", "autoAllowBashIfSandboxed", "credentials",
  "enabled", "excludedCommands", "failIfUnavailable", "filesystem", "network"
]'
assert_jq "${CORE}" '.sandbox.credentials | keys == ["files"]'
assert_jq "${CORE}" '.sandbox.filesystem | keys == ["allowRead", "denyWrite"]'
assert_jq "${CORE}" '.sandbox.network | keys == ["allowedDomains"]'

begin 'strict sandbox'
assert_jq "${CORE}" '.sandbox.enabled == true'
assert_jq "${CORE}" '.sandbox.failIfUnavailable == true'
assert_jq "${CORE}" '.sandbox.allowUnsandboxedCommands == false'
assert_jq "${CORE}" '.sandbox.autoAllowBashIfSandboxed == true'

begin 'git writes denied'
assert_jq "${CORE}" '.sandbox.filesystem.denyWrite | sort
  == ["~/**/.git/config", "~/**/.git/hooks"]'
assert_jq "${CORE}" '[.permissions.deny[] | select(contains("/.git/"))]
  | sort == ["Edit(~/**/.git/config)", "Edit(~/**/.git/hooks/**)"]'

begin 'only git signers readable'
assert_jq "${CORE}" '.sandbox.filesystem.allowRead
  == ["~/.config/git/allowed_signers"]'

begin 'system credentials only'
assert_jq "${CORE}" '.sandbox.credentials.files | sort_by(.path) == [
  {"mode": "deny", "path": "~/.bash_history"},
  {"mode": "deny", "path": "~/.git-credentials"},
  {"mode": "deny", "path": "~/.gnupg"},
  {"mode": "deny", "path": "~/.netrc"},
  {"mode": "deny", "path": "~/.ssh"},
  {"mode": "deny", "path": "~/.zsh_history"},
  {"mode": "deny", "path": "~/.zsh_sessions"}
]'

begin 'environment scrub and limits only'
assert_jq "${CORE}" '.env == {
  "CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS": "5",
  "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "1",
  "CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION": "25",
  "CLAUDE_CODE_SUBPROCESS_ENV_SCRUB": "1",
  "CLAUDE_CODE_WEBFETCH_DEADLINE_MS": "60000",
  "MAX_MCP_OUTPUT_TOKENS": "10000"
}'

begin 'context limits'
assert_jq "${CORE}" '.autoCompactWindow == 250000'
assert_jq "${CORE}" '.bashOutputMaxChars == 10000'
assert_jq "${CORE}" '.includeGitInstructions == false'

begin 'closed network'
assert_jq "${CORE}" '.sandbox.network.allowedDomains == []'

begin 'allow outside Bash'
assert_jq "${CORE}" '[.permissions.allow[] | select(startswith("Bash(") | not)]
  == ["Edit(./.sandbox/**)"]'

begin 'only local rules as an extra working directory'
assert_jq "${CORE}" \
  '.permissions.additionalDirectories == ["~/.claude/rules/local"]'

begin 'permission switches'
assert_jq "${CORE}" '.permissions.disableBypassPermissionsMode == "disable"'
assert_jq "${CORE}" '.permissions.blockReadsOutsideWorkingDirectories == true'
assert_jq "${CORE}" '.permissions.blockWritesOutsideWorkingDirectories == true'

begin 'behaviour switches'
assert_jq "${CORE}" '.disableSkillShellExecution == true'
assert_jq "${CORE}" '.remoteControlAtStartup == false'
assert_jq "${CORE}" \
  '.attribution == {"commit": "", "pr": "", "sessionUrl": false}'
assert_jq "${CORE}" '.disableClaudeAiConnectors == true'
assert_jq "${CORE}" '.enableArtifact == false'
assert_jq "${CORE}" '.respectGitignore == true'
assert_jq "${CORE}" '.autoContinueAtUsageLimit == false'
assert_jq "${CORE}" '.cleanupPeriodDays == 14'
assert_jq "${CORE}" '.syncClaudeAiSkills == false'
assert_jq "${CORE}" '.minimumVersion == "2.1.330"'

begin 'deny rules'
assert_jq "${CORE}" '[.permissions.deny[] | select(startswith("Bash("))]
  | sort == ([
  "Bash(env)", "Bash(printenv*)", "Bash(sudo *)"
] + ([
  "checkout *-- *", "clean*", "filter-repo*", "gc --prune*", "push*",
  "reflog expire*", "reset --hard*", "restore*", "stash clear*",
  "switch *--discard-changes*", "switch *--force*", "switch -f*",
  "worktree remove *--force*", "worktree remove -f*"
] | map("Bash(git " + . + ")", "Bash(git -C * " + . + ")")) | sort)'

begin 'credential files denied'
assert_jq "${CORE}" '[.permissions.deny[]
  | select(startswith("Bash(") or contains("/.git/") | not)]
  | sort == ([
  "**/*.env", "**/*.kdbx", "**/*.key", "**/*.keystore",
  "**/*.p12", "**/*.pem", "**/*.pfx", "**/*.ppk",
  "**/.env", "**/.env.*", "**/.envrc", "**/.git-credentials", "**/.netrc",
  "**/.ssh/**", "**/id_ecdsa*", "**/id_ed25519*", "**/id_rsa*",
  "~/.bash_history", "~/.git-credentials", "~/.gnupg/**", "~/.netrc",
  "~/.ssh/**", "~/.zsh_history", "~/.zsh_sessions/**"
] | map("Read(" + . + ")", "Edit(" + . + ")") | sort)'

begin 'ask rules'
assert_jq "${CORE}" '.permissions.ask | sort == ([
  "Bash(rm *)", "Bash(find *-delete*)", "Bash(rsync *--delete*)",
  "Bash(shred *)", "Bash(truncate *)",
  "Edit(**/.gitignore)", "Edit(**/.mcp.json)"
] | sort)'

finish
