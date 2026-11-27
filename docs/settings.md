# Settings

The keys of `settings.json`, in alphabetical order inside each block. The [settings reference](https://code.claude.com/docs/en/settings-reference) describes every key in full.

> [!note]
> Opt-in topics add keys of their own, such as `hooks`, `sandbox.excludedCommands` and `sandbox.filesystem.allowRead`; the `README.md` of each topic describes them, see [docs/opt-in.md](opt-in.md).

## General

| Key | Value | Effect |
| --- | --- | --- |
| `attribution.commit`, `attribution.pr` | `""` | No attribution text in commits and pull requests. |
| `attribution.sessionUrl` | `false` | No session link in commits and pull requests. |
| `disableClaudeAiConnectors` | `true` | No MCP connectors from the claude.ai account. |
| `disableSkillShellExecution` | `true` | Skills cannot run shell commands on load; bundled ones are unaffected. |
| `enableArtifact` | `false` | No publishing of artifacts to claude.ai. |
| `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | `1` | No credentials in the environment of subprocesses. |
| `hooks.PreToolUse` | `hooks/git.sh` and `hooks/read.sh` for Bash | `git.sh` blocks Git commands that skip the Git hooks (`--no-verify`, `commit -n`, `am -n`) or set configuration for one command (`git -c`, `--config-env`, `GIT_CONFIG_*`); `read.sh` blocks `cat`, `head`, `tail`, `sed` and `awk` when they read a file instead of a pipe, because only the Read tool loads path-scoped rules for every read; `tail -f` passes. With `onFailure: "block"`, a fault in a hook blocks the call too. |
| `remoteControlAtStartup` | `false` | A session does not start with Remote Control. |
| `respectGitignore` | `true` | Files that Git ignores stay out of the `@` picker. |
| `statusLine` | object | The status line described in [docs/statusline.md](statusline.md). |

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
