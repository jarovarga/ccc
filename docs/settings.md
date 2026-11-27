# Settings

The keys of `settings.json`, in alphabetical order inside each block. The [settings reference](https://code.claude.com/docs/en/settings-reference) describes every key in full.

> [!note]
> Opt-in topics add keys of their own, such as `hooks`, `sandbox.excludedCommands` and `sandbox.filesystem.allowRead`; the `README.md` of each topic describes them, see [docs/opt-in.md](opt-in.md).

## General

| Key | Value | Effect |
| --- | --- | --- |
| `attribution.commit`, `attribution.pr` | `""` | No attribution text in commits and pull requests. |
| `attribution.sessionUrl` | `false` | No session link in commits and pull requests. |
| `autoCompactWindow` | `250000` | The conversation compacts once the context holds about 250,000 tokens instead of at the window tuned for the model, which costs less per turn but compacts more often; `/autocompact`, `--autocompact` or `CLAUDE_CODE_AUTO_COMPACT_WINDOW` change it for a model or a session. |
| `autoContinueAtUsageLimit` | `false` | A session stopped by a claude.ai usage limit does not continue on its own after the reset; a wait can still be started from the usage-limit menu. |
| `awaySummaryEnabled` | `false` | No one-line session recap on returning to the terminal after a few minutes away; `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` overrides the key for one session. |
| `bashOutputMaxChars` | `10000` | Claude receives up to 10,000 characters of a successful Bash command's output inline instead of 30,000; longer output goes to a file, and Claude receives a preview and its path. |
| `cleanupPeriodDays` | `14` | Session transcripts, which can hold sensitive data, are deleted after 14 days instead of 30; sessions of Claude Desktop or Cowork are kept longer. |
| `disableClaudeAiConnectors` | `true` | No MCP connectors from the claude.ai account. |
| `disableSkillShellExecution` | `true` | Skills cannot run shell commands on load; bundled ones are unaffected. |
| `enableArtifact` | `false` | No publishing of artifacts to claude.ai. |
| `env.CLAUDE_CODE_EXPERIMENTAL_CODE_MODE` | `0` | Code Mode stays off, even when another source sets it to `1`; its scripts run outside the sandbox, and only the shell commands they start run inside it. |
| `env.CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` | `5` | At most 5 subagents run at once instead of 20; the Agent tool refuses another until one finishes. |
| `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | `1` | Subagents cannot start subagents of their own; the default allows three layers. |
| `env.CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` | `25` | At most 25 web searches per session instead of 200; after that, Claude continues with what it has found and says so. |
| `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | `1` | No credentials in the environment of subprocesses. |
| `env.CLAUDE_CODE_WEBFETCH_DEADLINE_MS` | `60000` | A WebFetch download, including its redirects, fails after one minute instead of five. |
| `env.MAX_MCP_OUTPUT_TOKENS` | `10000` | An MCP tool result over 10,000 tokens instead of 25,000 goes to a file, and Claude receives its path; tools that declare their own limit keep it for text. |
| `hooks.PreToolUse` | `hooks/git.sh` and `hooks/read.sh` for Bash | `git.sh` blocks Git commands that skip the Git hooks (`--no-verify`, `commit -n`, `am -n`) or set configuration for one command (`git -c`, `--config-env`, `GIT_CONFIG_*`); `read.sh` blocks `cat`, `head`, `tail`, `sed` and `awk` when they read a file instead of a pipe, because only the Read tool loads path-scoped rules for every read; `tail -f` passes. With `onFailure: "block"`, a fault in a hook blocks the call too. |
| `includeGitInstructions` | `false` | The built-in commit and pull request instructions and the Git status snapshot at the start of a session stay out of the context; `rules/git.md` sets the Git workflow, and Claude runs `git status` when it needs it. `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` overrides the key for one session. |
| `minimumVersion` | `"2.1.332"` | Auto-updates and `claude update` install no version below the one in [Compatibility](../README.md#compatibility); an older version still starts. |
| `promptSuggestionEnabled` | `false` | No greyed-out prompt suggestions in the input box; `CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION` overrides the key for one session. |
| `remoteControlAtStartup` | `false` | A session does not start with Remote Control. |
| `respectGitignore` | `true` | Files that Git ignores stay out of the `@` picker. |
| `skillListingMaxDescChars` | `512` | The skill listing in the context shows at most 512 characters of each skill's `description` and `when_to_use` instead of 1,536; every skill name stays listed, so a skill with a cut description can still be invoked. |
| `statusLine` | object | The status line described in [docs/statusline.md](statusline.md). |
| `syncClaudeAiSkills` | `false` | No skills from the claude.ai account are downloaded or loaded; ones already synced move to `~/.claude/skills/.trash/`. |
| `workflowKeywordTriggerEnabled` | `false` | The word `ultracode` in a prompt does not start a workflow; the `ultracode` effort setting, `/workflows` and saved workflow commands still work. |

## Permissions

| Key | Value | Effect |
| --- | --- | --- |
| `additionalDirectories` | `["~/.claude/rules/local"]` | The local rules are a working directory, so Claude can edit them; every edit under `.claude` still prompts. |
| `allow` | array | Actions that run without a prompt. |
| `ask` | array | Actions that prompt first, such as deletions. |
| `deny` | array | Actions that are refused: reading or editing credentials and the shell history, `env`, `printenv` and `sudo`, pushes, irreversible Git operations, Git commands that discard uncommitted work (`checkout -- <path>`, `restore`, `switch --discard-changes` or `--force`, `worktree remove --force`), and edits of Git configuration and hooks under `~`. |
| `blockReadsOutsideWorkingDirectories` | `true` | No reads outside the working directories. |
| `blockWritesOutsideWorkingDirectories` | `true` | No edits outside the working directories. |
| `disableBypassPermissionsMode` | `"disable"` | `--dangerously-skip-permissions` has no effect. |

> [!important]
> The sandbox is the security boundary. A `deny` rule matches the text of a command, so a form such as `bash -c '…'` or an absolute path to the program gets past it.

> [!tip]
> To work on files outside the project, add their directory with `/add-dir`.

## Sandbox

| Key | Value | Effect |
| --- | --- | --- |
| `allowUnsandboxedCommands` | `false` | A command that fails in the sandbox is not retried outside it. |
| `autoAllowBashIfSandboxed` | `true` | Sandboxed commands run without a prompt; `ask` and `deny` still apply. |
| `credentials.files` | array | Sandboxed commands cannot read credentials or the shell history. |
| `enabled` | `true` | Bash commands run in the sandbox. |
| `excludedCommands` | `[]` | No command runs outside the sandbox. |
| `failIfUnavailable` | `true` | Claude Code exits when the sandbox cannot start. |
| `filesystem.allowRead` | array | Sandboxed commands can read `~/.config/git/allowed_signers`, so that Git can verify SSH signatures of commits; to sign them, see [docs/ssh.md](ssh.md). |
| `filesystem.denyWrite` | array | Sandboxed commands cannot change Git configuration or hooks under `~`. |
| `network.allowedDomains` | `[]` | Sandboxed commands have no network access. |
