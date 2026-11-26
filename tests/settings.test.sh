#!/usr/bin/env bash
# Checks the keys and the security-relevant values of the root settings.json.
set -o nounset
set -o pipefail

# shellcheck source=lib/check.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/check.sh" || exit 1

readonly CORE="${CCC_ROOT}/settings.json"

begin 'only core keys'
assert_jq "${CORE}" 'keys == [
  "attribution", "disableClaudeAiConnectors", "disableSkillShellExecution",
  "enableArtifact", "env", "permissions",
  "remoteControlAtStartup", "respectGitignore", "sandbox", "statusLine"
]'
assert_jq "${CORE}" '.permissions | keys == [
  "allow", "ask", "blockReadsOutsideWorkingDirectories",
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

begin 'environment scrub only'
assert_jq "${CORE}" '.env == {"CLAUDE_CODE_SUBPROCESS_ENV_SCRUB": "1"}'

begin 'closed network'
assert_jq "${CORE}" '.sandbox.network.allowedDomains == []'

begin 'allow outside Bash'
assert_jq "${CORE}" '[.permissions.allow[] | select(startswith("Bash(") | not)]
  | sort == [
    "Edit(./.sandbox/**)",
    "WebFetch(domain:code.claude.com)",
    "WebFetch(domain:developer.mozilla.org)"
  ]'

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

begin 'deny rules'
assert_jq "${CORE}" '[.permissions.deny[] | select(startswith("Bash("))]
  | sort == ([
  "Bash(env)", "Bash(printenv*)", "Bash(sudo *)"
] + ([
  "clean*", "filter-repo*", "gc --prune*", "push*", "reflog expire*",
  "reset --hard*", "stash clear*"
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
