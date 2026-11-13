# Claude Code configuration

```text
 ██████╗ ██████╗ ██████╗
██╔════╝██╔════╝██╔════╝
██║     ██║     ██║
██║     ██║     ██║
╚██████╗╚██████╗╚██████╗
 ╚═════╝ ╚═════╝ ╚═════╝
```

A user-level [Claude Code](https://code.claude.com) config: pinned settings, a required sandbox, lean instructions.

- Fewer tokens per session
- Secrets and Git history out of Claude's reach
- Same behaviour on every machine

Nothing project-specific loads by default.

Pinned means that every value in `settings.json` is set explicitly, even where it matches today's default, because defaults change between releases, and that `minimumVersion` sets a floor on the `stable` channel. Claude Code still updates; the version is not frozen. The sandbox is the boundary; [Known limits](#known-limits) lists what the configuration does not cover.

Project and framework conventions belong in the project or in `opt-in/`, which holds templates and never loads on its own. [Per-project settings](#per-project-settings) shows the usual additions. JSON has no comments, so this README is where the reasoning lives.

## Contents

| Path | Purpose |
| --- | --- |
| `settings.json` | Model, context, permissions, sandbox, hooks and skills. |
| `hooks/` | The scripts that the hooks in `settings.json` run. |
| `tests/run.sh` | Runs every hook against sample input and checks its exit code. |
| `CLAUDE.md` | Instructions loaded in every session. |
| `RTK.md` | How to work with the RTK hook; imported by `CLAUDE.md`. |
| `rules/agent.md`, `rules/code.md`, `rules/git.md`, `rules/security.md` | General rules, loaded in every session. |
| `rules/instructions.md` | Rules for writing agent instructions, loaded only for instruction files. |
| `rules/stack/` | One file per language or tool, loaded only for matching files. |
| `opt-in/` | Optional rules and settings to copy into a project; never installed into `~/.claude/`. |

## Requirements

- Claude Code 2.1.290 or later. Older versions have holes in `blockReadsOutsideWorkingDirectories` (see [Permissions](#permissions)), and `minimumVersion` stops auto-updates from going below it.
- macOS. The sandbox uses Seatbelt and `network.allowLocalBinding` only does something there. Linux is untested.
- [RTK](https://rtk-ai.app) on `PATH` (`brew install rtk`). The settings register a hook that calls `rtk hook claude`. Without RTK the hook fails on every Bash call with a non-blocking error, and commands run unfiltered. The hook has no `onFailure: "block"`, because that would stop every Bash call whenever RTK is missing.
- RTK must leave `gh` alone. It rewrites `gh …` to `rtk gh …`, which no longer matches `excludedCommands`, so `gh` would run in the sandbox without its configuration or the network. Set `exclude_commands = ["gh"]` under `[hooks]` in RTK's `config.toml`. On a machine without that file yet, run this outside Claude Code (or with `!`), because the sandbox blocks writes there; the last command must print `exclude_commands = ["gh"]`:

  ```bash
  rtk config --create
  sed -i '' 's/^exclude_commands = \[\]$/exclude_commands = ["gh"]/' "$HOME/Library/Application Support/rtk/config.toml"
  rtk config | grep -A1 '^\[hooks\]'
  ```
- `jq`, which every hook script uses to read its input. The scripts run under the Bash 3.2 that macOS ships.
- [ripgrep](https://github.com/BurntSushi/ripgrep), because `CLAUDE.md` tells Claude to search with `rg`.
- The [GitHub CLI](https://cli.github.com) and [ShellCheck](https://shellcheck.net) are optional. They get used if they are there.

## After installation

`settings.json`, `CLAUDE.md`, `RTK.md`, `hooks/` and `rules/` go into `~/.claude/`, as user configuration. The hooks are called as `~/.claude/hooks/<name>.sh`, so keep the scripts executable. Some commands write to `~/.claude/settings.json` (`/effort`, `/fast`, `/autocompact`), so if it is a symlink to a checkout, those writes end up in the repository. A few keys are ignored in project settings (`defaultMode: "auto"`, `autoContinueAtUsageLimit`, `syncClaudeAiSkills`), and a hook should not arrive through a repository anyway.

Create `~/.claude/LOCAL.md`, even an empty one, because `CLAUDE.md` imports it (see [Personal instructions](#personal-instructions)). Then start a new session and check four things:

1. Run `/skills` and compare the names with `skillOverrides`. They change between versions.
2. Ask Claude to read a `.env` file and to run `git push`. It must refuse both.
3. Ask Claude to run `printenv`. It must refuse that too, which also shows that the `deny` rules still match after the RTK hook has rewritten the command.
4. Ask Claude to run `gh auth status`. It must ask first and then report a logged-in account, not `operation not permitted`.

### Settings outside `settings.json`

Two keys look like they belong in `settings.json` but are ignored there. They live in `~/.claude.json`, so set them through `/config`:

- `autoConnectIde`
- `diffTool`

### Optional interface preferences

These are taste, so they are not in the baseline. Add any of them to the user settings:

```json
{
  "editorMode": "normal",
  "prefersReducedMotion": false,
  "preferredNotifChannel": "auto",
  "showTurnDuration": true,
  "spinnerTipsEnabled": false,
  "theme": "auto"
}
```

## What the settings do

The tables follow the blocks of `settings.json`, with keys in alphabetical order inside each block. The official [settings reference](https://code.claude.com/docs/en/settings-reference) has the full description of every key; the last column here only gives the reason for the value.

### Model and effort

| Key | Value | Why |
| --- | --- | --- |
| `effortLevel` | `medium` | Enough thinking for everyday work. Raise it for one session with `claude --effort high`. Saving a level with `/effort` writes it to `modelSettings`, which then wins over this key for that model. |
| `fastMode` | `false` | Fast mode costs more per token, so it stays an explicit choice. `/fast` writes `fastMode: true` to the user settings. |
| `model` | `opusplan` | Opus plans, a cheaper model writes the code. |
| `switchModelsOnFlag` | `false` | If a safety classifier flags a request, stop and ask instead of quietly switching models. |

### Context and tokens

| Key | Value | Why |
| --- | --- | --- |
| `autoCompactEnabled` | `true` | Summarise instead of running into the context limit in the middle of a task. |
| `autoCompactWindow` | `250000` | Every turn resends the whole context, so compact before it gets to the maximum. |
| `bashOutputMaxChars` | `10000` | Longer output is saved to a file and Claude gets a preview and the path, so nothing is lost. Wins over `BASH_MAX_OUTPUT_LENGTH`. |
| `respectGitignore` | `true` | Keeps build output and other ignored files out of the `@` picker. |
| `env.CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` | `4` | Every subagent has a context of its own. The default is 20. |
| `env.CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | `1` | Subagents cannot spawn subagents. The default is 3. |
| `env.CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` | `30` | The default is 200. At the cap Claude is told to carry on with what it has. |
| `env.CLAUDE_CODE_SUBAGENT_MODEL` | `sonnet` | Subagents run on the cheaper model unless their definition says otherwise. |
| `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` | `1` | Removes credentials, recognised by variable name or value, from the environment of Bash commands, hooks and stdio MCP servers, so `export -p` and similar have less to show. GitHub tokens and proxy settings stay. A tool that needs a removed variable, such as `DATABASE_URL` with a password, does not get it. |
| `env.MAX_MCP_OUTPUT_TOKENS` | `10000` | Limit for one MCP tool response. The default is 25,000 tokens. |

### Features that spend tokens or act unattended

| Key | Value | Why |
| --- | --- | --- |
| `autoContinueAtUsageLimit` | `false` | Do not carry on alone once a usage limit resets. User settings only. |
| `awaySummaryEnabled` | `false` | The recap is one more model call. |
| `promptSuggestionEnabled` | `false` | No background suggestions for the next prompt. |
| `workflowKeywordTriggerEnabled` | `false` | Otherwise the word "ultracode", even inside a quote, starts an expensive workflow. |

### Account integrations

| Key | Value | Why |
| --- | --- | --- |
| `disableClaudeAiConnectors` | `true` | No MCP connectors pulled in from claude.ai. They are unreviewed, and their tool definitions take up context. |
| `enableArtifact` | `false` | Turns the Artifact tool off, so a session cannot publish artifacts to claude.ai. |
| `remoteControlAtStartup` | `false` | A session is never exposed remotely by default. Left unset, the organisation default applies. |
| `syncClaudeAiSkills` | `false` | A new machine gets the skills from this configuration and nothing from the account. A repository cannot switch this off, so it has to be in user settings. |

### Git

| Key | Value | Why |
| --- | --- | --- |
| `attribution.commit`, `attribution.pr` | `""` | No trailers or credit lines in commits and pull requests. This only empties the default text, so `rules/git.md` forbids them as well. |
| `attribution.sessionUrl` | `false` | No link to a private claude.ai session. |
| `includeGitInstructions` | `false` | Removes the built-in commit and pull request instructions from the system prompt. `rules/git.md` replaces them, and it is shorter. It also removes the Git status snapshot (branch, `git status`, recent commits) taken at the start of a session, so Claude runs `git status` when it needs it. |

### Maintenance

| Key | Value | Why |
| --- | --- | --- |
| `autoUpdatesChannel` | `stable` | About a week behind, and it skips releases with serious regressions. Homebrew installs ignore this key. |
| `cleanupPeriodDays` | `14` | Transcripts contain tool output and everything pasted into a session, mistakes included, so they are kept for two weeks instead of the default 30 days. `/resume` and checkpoints expire with them. |
| `fileCheckpointingEnabled` | `true` | `/rewind` can restore a file to what it was before an edit. |
| `minimumVersion` | `2.1.290` | Auto-updates do not go below the version the baseline needs; newer versions still install. |

### Skills

Claude gets the description of every bundled skill on every turn. `skillOverrides` cuts that down, and it also keeps the model from starting skills that have side effects.

| Tier | Skills | Reason |
| --- | --- | --- |
| `on` | `claude-api`, `security-review`, `update-config` | Worth letting Claude pick them by itself. |
| `name-only` | `code-review` | Claude knows it exists but does not carry its description around. |
| `user-invocable-only` | `batch`, `claude-in-chrome`, `debug`, `doctor`, `fewer-permission-prompts`, `init`, `keybindings-help`, `loop`, `run`, `run-skill-generator`, `schedule`, `simplify`, `verify` | They cost tokens or change things, so only the user starts them. `claude-in-chrome` drives a browser with logged-in accounts. |
| `off` | `artifact-capabilities`, `artifact-design`, `artifact-diagramming`, `dataviz`, `design`, `design-sync`, `plugin-authoring`, `slides`, `workflow-authoring` | Not needed for programming. |

The setting does not touch plugin skills or skills in `.claude/skills/`.

### Hooks

Hooks are scripts that Claude Code runs at fixed points. They run outside the sandbox with full user permissions, so read a script before adding it. A hook that exits with 2 blocks the action and its message on stderr goes to Claude, so each message says what to do instead. Any other failure is non-blocking. The scripts are in `hooks/`, need only Bash and `jq`, and cost no context unless they block something.

| Hook | Runs | Does |
| --- | --- | --- |
| `rtk hook claude` | `PreToolUse` for `Bash` | RTK cuts the boilerplate out of command output and keeps errors and failures. |
| `guard-bash.sh` | `PreToolUse` for `Bash` | Blocks `rm -r` on broad paths (the root, a home directory, `.`, `..`, a bare `*`, a system directory, `$VAR/`), every `git push`, `docker compose down -v`, `docker volume rm` and `prune`, `docker system prune --volumes`, and `DROP DATABASE` or `DROP TABLE` sent to `psql`, `mysql`, `mariadb` or `sqlite3`. |
| `block-suppressions.sh` | `PreToolUse` for `Edit` and `Write` | Blocks new comments that silence a checker (PHPStan, PHP_CodeSniffer, Stylelint, ESLint, TypeScript, `noqa`) so that Claude fixes the cause. Markdown files are skipped. |
| `protect-paths.sh` | `PreToolUse` for `Edit` and `Write` | Blocks `vendor/`, `node_modules/`, `composer.lock` and `package-lock.json`. Lock files change through the package manager. Environment files are left to the `deny` rules. |
| `log-bash.sh` | `PostToolUse` for `Bash` | Appends the time (UTC), working directory and command to `~/.claude/logs/bash.jsonl`. The file is private and common secret forms are redacted on a best-effort basis (assignments, password and token options, URL credentials, authorisation headers, well-known token prefixes), but other forms are not recognised, so the log is not safe to share. It is never rotated. |
| `bash-patterns.sh` | by hand | `~/.claude/hooks/bash-patterns.sh [count]` lists the most frequent command patterns in the log, so repeated habits such as `python3 -c` or heredocs show up and can become a rule or a permission. |

`guard-bash.sh` reads the structure of the command, not the raw text. Quoted text and heredoc bodies are ignored, so a commit message that mentions `rm -rf` passes, while `$(…)` and backticks are inspected because the shell runs them. It looks through wrappers such as `sudo`, `nice`, `timeout`, `xargs` and `find -exec`, but does not follow `bash -c`, `eval`, scripts or aliases, and an empty pair of quotes inside a word (`g""it`) hides it. The body of an unquoted heredoc is not inspected, `DROP SCHEMA`, `TRUNCATE` and `psql -f` are not recognised, and `block-suppressions.sh` cannot see a suppression swapped for another one in an `Edit`. A hook that cannot run (for example an unwritable `HOME` for the log) fails without blocking. For `rm`, `git push` and Docker it backs up the `deny` rules, which match the text of a command and miss forms such as `/bin/rm`, `xargs rm` or `git --no-pager push`. For SQL and the checks on files it is the only layer. The `deny` rules stay, because a hook that fails does not block.

The 10-second timeouts are there because a hung hook would otherwise block the tool for 600 seconds.

To turn a hook off, delete its entry from `hooks` in `settings.json`, or set `"disableAllHooks": true` (pinned to `false` here) to turn off all of them, `rtk hook claude` included. Deleting the script instead makes the hook fail without blocking, and Claude Code reports a non-blocking error on every call.

Run `tests/run.sh` after changing a script. It feeds each hook sample JSON and compares the exit code (2 blocks, 0 allows).

There is no notification hook. Claude Code already sends desktop notifications in iTerm2, Ghostty and Kitty (`preferredNotifChannel`, see [Optional interface preferences](#optional-interface-preferences)), and a hook that calls `osascript display notification` is attributed to Script Editor, so a click on it opens that app instead of the session.

### Permissions

`defaultMode: "auto"` lets a classifier look at commands and network requests before they run, so ordinary work is not interrupted by prompts. It only works from user settings. `disableBypassPermissionsMode: "disable"` makes `--dangerously-skip-permissions` do nothing.

`blockReadsOutsideWorkingDirectories: true` makes the file tools refuse reads outside the working directories in every permission mode, and the sandbox applies the same block to commands, so a session in one project does not read another project or the rest of the home directory, apart from directories added with `/add-dir` or `additionalDirectories` and commands excluded from the sandbox, such as `gh`. The JSON schema at schemastore.org does not list the key yet and an editor flags it as not allowed; Claude Code has read it since 2.1.257. Before 2.1.290, some Bash commands in auto mode and `@`-mentions could still read outside the working directories, so that is the minimum version. To work on files elsewhere, such as `~/.claude/` itself, start the session there or add the directory with `/add-dir`. A directory that every session needs, such as a notes vault, goes into `permissions.additionalDirectories` in `~/.claude/settings.local.json`, so that the path stays out of this repository.

Rules are checked in the order `deny`, `ask`, `allow`, and the first match wins.

`allow` is almost empty. With the sandbox and `autoAllowBashIfSandboxed`, sandboxed commands run without a prompt already. It only lists two documentation hosts for `WebFetch`, which the sandbox does not cover. When adding more, avoid hosts that serve content written by users.

`ask` is for things that should not happen silently:

- `gh`, because it runs outside the sandbox (see [Sandbox](#sandbox)).
- Broad staging (`git add --all`, `-A`, `--update`, `-u`, `.`), `git checkout`, `git commit`, `git rm`, `git stash clear` and `git stash drop`, each also as `git -C <path>`.
- `rm`.
- Edits to Claude's own configuration: `.claude/`, `.mcp.json` and `.gitignore` in the project, and in `~/.claude/` the Markdown files, settings, `agents`, `commands`, `hooks`, `rules` and `skills`, plus `~/.claude.json`.
- `WebSearch`, because the query leaves the machine.

`deny` cannot be approved at all:

- A shell without a command (`bash`, `sh`, `zsh`, with or without `-s`), which is what `curl … | sh` ends in.
- Docker commands that delete volumes: `docker volume rm` and `prune`, `docker system prune`, and `docker compose down -v` or `--volumes`. `guard-bash.sh` covers the other spellings.
- `env` and `printenv`, so secrets in the environment do not end up in the context by the usual route. `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` removes most of them from the environment in the first place (see [Known limits](#known-limits)).
- `sudo`.
- Skipping Git hooks (`--no-verify` and its abbreviations, `commit -n`, `core.*` configuration, `git -c`) and Git that rewrites or destroys history (`push`, `reset`, `restore`, `rebase`, `filter-branch`, `clean`, `checkout --`, `branch -D`, forced `branch`, `switch` and `tag`, `commit --amend`, `reflog expire` and `delete`, `gc --prune`, `prune`, `tag -d`, `update-ref`, forced `worktree remove`), each also as `git -C <path>`. Pushing is left to the user, for example with `! git push`.
- Recursive `rm`.
- Reading or editing secrets: certificates and keys (`.crt`, `.key`, `.p12`, `.pem`, `.pfx`), environment files (`.env`, `.env.*`, `*.env`, `.envrc`, but not `.env.example`), `.git-credentials`, `.netrc`, `.ssh`, `id_ecdsa*`, `id_ed25519*` and `id_rsa*` keys, `~/.aws` and `~/.gnupg`. Every path has a `Read` and an `Edit` rule; add both for a new path.

`Edit(!**/.env.example)` and `Read(!**/.env.example)` are negations in the gitignore style. They have to stay below the `.env.*` rule they make an exception to, or they do nothing.

Do not mistake these rules for a security boundary. A `deny` rule matches the form Claude normally writes, and `bash -c '…'` or an absolute path to the binary gets past it. The sandbox is the boundary.

### Sandbox

| Key | Value | Why |
| --- | --- | --- |
| `allowUnsandboxedCommands` | `false` | A command that fails in the sandbox is not retried outside it. |
| `autoAllowBashIfSandboxed` | `true` | The operating system contains the command, so there is no need to ask. `deny` and `ask` rules still apply. |
| `credentials.files` | `~/.aws`, `~/.git-credentials`, `~/.gnupg`, `~/.netrc`, `~/.ssh`, each with `"mode": "deny"` | Sandboxed commands cannot read these. The `Read` deny rules for the same paths are merged into the sandbox already, so this repeats them on purpose: the protection stays if the `Read` rules are ever edited. |
| `enabled` | `true` | Off by default. Writes stay inside the working directory and there is no direct network access. |
| `excludedCommands` | `["gh *"]` | Lets the GitHub CLI run outside the sandbox. The `ask` rule still asks every time. Only works with `gh` excluded from RTK (see [Requirements](#requirements)), because the entry is matched against the text of the command. Every command in a call has to match, so `gh … | jq …` stays in the sandbox and fails. |
| `failIfUnavailable` | `true` | If the sandbox cannot start, Claude Code exits instead of running without it. |
| `network.allowLocalBinding` | `false` | `true` lets development servers and tests listen on ports, but it also lets sandboxed commands connect to any port on localhost, so every local service without authentication (a database, the Docker API, a debugger) is within reach. Enable it per project (see [Per-project settings](#per-project-settings)). macOS only. |

### Worktrees

| Key | Value | Why |
| --- | --- | --- |
| `baseRef` | `head` | A worktree branches from local `HEAD`, so unpushed commits come along. The default, `fresh`, branches from `origin`. |
| `bgIsolation` | `worktree` | A background session cannot edit the main checkout until it is in a worktree. |

## Instructions

`CLAUDE.md` is loaded at the start of every session, so it is kept short. Imports do not make it cheaper, because an imported file loads together with the one that imports it.

Most of it is about context: search the narrowest path first, keep command output small, batch calls, and suggest a new conversation when a request has nothing to do with the current one. All of that keeps the context small, and the context is resent on every turn.

It also makes the files in `~/.claude/rules/` binding and tells Claude that a task or a project does not override or weaken any of them. There are two exceptions. A rule can defer to the project, as the rules do for commit conventions, formatter settings and the command runner. And a project's framework or coding standard wins over a rule in `rules/stack/`.

It asks Claude to read files with the Read tool instead of `cat`, because that is what loads the path-scoped rules.

The rest is working conventions: read the README and the configuration before editing, answer in the user's language, and write new documentation, comments and commit messages in British English.

The final section tells Claude what to keep when a long conversation is summarised.

`RTK.md` is imported by `CLAUDE.md`. It tells Claude that RTK's filtered output is complete, how to get an elided part back with `rtk recall <hash>`, and when to bypass the filter. The RTK commands meant for the user are not in it, because they would cost tokens in every session:

- `rtk gain` and `rtk gain --history` show how many tokens RTK saved, in total and per command. Run them outside Claude Code; they fail in the sandbox.
- `rtk discover` finds past commands RTK could have shortened.
- `rtk telemetry status` shows whether RTK's optional telemetry is on.

### Personal instructions

`CLAUDE.md` also imports `LOCAL.md`, which is not in this repository. Put anything personal into `~/.claude/LOCAL.md`: a GitHub account, local paths, personal conventions. Imports in user-level files load without an approval dialog. The `.gitignore` here ignores everything it does not list, so a `LOCAL.md` in a checkout stays untracked.

A template for `~/.claude/LOCAL.md`. Keep only the sections that apply and replace every `<placeholder>`. The linter configurations are the author's public gists; replace them with your own sources:

```markdown
# Local

## GitHub

- Use the account `github.com/<account>` and look for local checkouts in `<checkout_path>/<repo>`.
- Read GitHub (issues, pull requests, gists, the API) with the `gh` CLI, which runs outside the sandbox.
- Write remote addresses in the SSH form (`git@github.com:<account>/<repo>.git`).

## Linter configurations

When a task or the project instructions ask to add a linter or formatter, start from these public gists, read with `gh gist view <id>`, and adapt their paths to the project; never overwrite a configuration the project already has.

- EditorConfig: `010dbb8f4c0f2252bf794f0ddd226ff3`
- Prettier: `7a5c1695ec8eeaf78b6e01e3a8dc95e1`
- HTML-validate: `eaff14156f7ffd1d5a5e9bb86be3c8c7`
- Stylelint: `454c5a7ae672f7405b23d0e3905c6639`
- ESLint: `fd9e481fcbd3a31aef8bab713ce7a796`
```

## Rules

Every rule is one imperative line in one file. A stack rule can narrow a general rule for its language, such as the pinned images of `docker.md`, and a framework rule can replace a stack rule.

### General rules

These four load in every session.

| File | Holds |
| --- | --- |
| `rules/agent.md` | How the agent works: what it needs permission for, planning, the working tree, debugging, verifying and reporting, review, evidence, communication. |
| `rules/code.md` | How code is written in any language: formatting, the scope of a change, design, comments, robustness, input and output, accessibility, testing. |
| `rules/git.md` | Commit only when asked and after approval, stage only what belongs to the task without interactive commands, pull request descriptions, no attribution, no skipped hooks, remote operations left to the user. |
| `rules/security.md` | Principles, requests, credentials, dependencies, services and files. The principles follow the OWASP Secure Product Design Cheat Sheet. |

`rules/instructions.md` only loads for instruction files: `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `LOCAL.md`, `RTK.md`, anything in `.claude/` and the Markdown files in `rules/`. It asks for imperative wording and for every requirement to survive when instructions are revised.

### Stack rules

The files in `rules/stack/` have `paths` frontmatter, so they cost nothing until Claude touches a matching file.

| File | Loads for | Holds |
| --- | --- | --- |
| `bash.md` | `**/*.{bash,sh}` | Shell options, quoting, syntax, temporary files, secrets, confirmations, ShellCheck. |
| `css.md` | `**/*.css` | Cascade layers, tokens, layout, states and accessibility, hidden content, forced colours, motion, quality. |
| `docker.md` | `**/Dockerfile*`, `**/*.dockerfile`, `**/.dockerignore`, `**/compose*.{yml,yaml}`, `**/docker-compose*.{yml,yaml}` | Pinned images, build steps, build secrets, non-root users, Compose services, published ports, health checks, tool services. || `html.md` | `**/*.{html,twig}` | Semantics, attributes, links and buttons, forms, native widgets, accessibility, media, resources. |
| `javascript.md` | `**/*.{js,mjs}` | Modules, DOM, events, focus, motion, observers, timing, network, docblocks. Written for the browser. |
| `markdown.md` | `**/*.{markdown,md}` | One line per paragraph, headings, inline code, placeholders, code blocks. |
| `php.md` | `**/*.php` | The fallback coding standard (PER-CS 3.0), types, classes, syntax, the standard library, strings and regular expressions, errors, deprecated forms, security, docblocks. |
| `postgresql.md` | `**/*.sql` | Types and schema, constraints, indexes, migrations on live tables, queries. |

A few things to know about them:

- A rule that needs a minimum version says so, such as (8.4+) in `php.md` or (18+) in `postgresql.md`, and only applies when the project targets that version.
- `css.md`, `html.md` and `javascript.md` assume features that are [Baseline](https://developer.mozilla.org/docs/Glossary/Baseline/Compatibility) Widely available, unless the project declares other browser support.
- A stack rule loads when Claude reads a matching file with the Read tool, not when a command such as `cat` reads it (see [Instructions](#instructions)).
- The patterns match file names and extensions, not the directories of some project layout. So `html.md` does not load for templates written in PHP, `postgresql.md` does not load for migrations written in another language, and `bash.md` does not load for scripts without an extension, such as `bin/deploy`. If a project needs that, widen `paths`, for example with `templates/**/*.php` or `**/migrations/**`.

Naming methodologies, formatting styles and library choices are left out of the stack rules. Templates for them, such as BEM naming of classes, are in `opt-in/conventions/`; keep yours in `LOCAL.md` or in the project.

### Opt-in rules

`opt-in/` holds rules and settings that fit only some projects: conventions and framework setups. A project copies what it needs into its own `.claude/`, so they apply to that project alone. They are not under `rules/` and `CLAUDE.md` does not import them, so nothing in them loads on its own. Only `settings.json`, `CLAUDE.md`, `RTK.md` and `rules/` are installed into `~/.claude/`; `opt-in/` never is.

| Path | Holds |
| --- | --- |
| `opt-in/conventions/` | One rule file per convention. |
| `opt-in/frameworks/<framework>/` | `settings.json`, `rules/<framework>.md` and a `README.md` for each framework. |

Everything in `opt-in/`, conventions and frameworks alike, is a template for writing project rules; adapt it before use. See `opt-in/README.md` for how to use them.

## Per-project settings

These go into the project's `.claude/settings.json`. Settings for a framework, and the rules that go with them, are in [Opt-in rules](#opt-in-rules).

```json
{
  "claudeMdExcludes": ["**/node_modules/**", "**/vendor/**"],
  "worktree": { "symlinkDirectories": ["node_modules", "vendor"] }
}
```

`claudeMdExcludes` keeps the `CLAUDE.md` files and rules of dependencies from loading, and `symlinkDirectories` saves copying large directories into every worktree.

A project whose development server or tests listen on a port needs `"sandbox": { "network": { "allowLocalBinding": true } }`, which also opens every other port on localhost to sandboxed commands.

Add `ask` rules for dependency changes (`npm install`, `composer require` and so on) and `allow` rules for the linter and test commands.

The baseline only protects credentials whose location does not depend on a tool. Add the ones the project's tools use to `permissions.deny`, for both `Read` and `Edit`, and to `sandbox.credentials.files`: `.npmrc`, Composer's `auth.json`, `~/.kube/config`, `~/.docker/config.json`, `~/.config/gh/**`, `~/.config/gcloud/**`, `.pgpass`. Secret environment variables go under `sandbox.credentials.envVars`, which unsets them before each sandboxed command.

Add `WebFetch(domain:…)` rules for the documentation the project relies on. `github.com`, `raw.githubusercontent.com` and `api.github.com` are left out because anyone can publish content there.

Docker needs a socket that the sandbox blocks. Exclude a wrapper script of the project (here `<wrapper>`, a script that calls `docker compose`) and not `docker` itself, because an excluded `docker` can run `docker run -v /:/host`:

```json
{
  "sandbox": { "excludedCommands": ["<wrapper> *"] },
  "permissions": {
    "allow": ["Bash(<wrapper> composer test*)"],
    "ask": ["Bash(<wrapper> cake migrations *)", "Bash(<wrapper> psql *)"]
  }
}
```

Never allow the wrapper with a bare `*`, since an excluded command runs outside the sandbox. And do not commit `excludedCommands` to a repository under someone else's control.

Some Compose commands print secrets. `docker compose config` shows the values taken from the env file, and `docker compose exec <service> env` shows the environment of a container. The `deny` rules for `.env` files do not cover either, so deny them where a project uses Compose (in the wrapper's form, if there is one):

```json
{
  "permissions": {
    "deny": [
      "Bash(docker compose * config*)",
      "Bash(docker compose config*)",
      "Bash(docker compose exec * env)",
      "Bash(docker compose exec * printenv*)"
    ]
  }
}
```

## Known limits

- Checkpoints only track edits made with Claude's file tools. A file changed by a Bash command alone (`sed -i`, a script) is not tracked, so use Git for that. Only the 100 most recent checkpoints of a session keep snapshots.
- `Read` deny rules apply to the Read tool, to commands that name a file, such as `cat`, and to redirects. They do not apply to `grep -r` or to a script that opens files itself. The sandbox handles those.
- The `**/` credential patterns in `deny` are relative to the project. Files in other projects are protected only by the sandbox and by the `~/` patterns.
- The environment can still be printed without `env` or `printenv`, for example with `export -p`. The scrub only removes variables whose name or value looks like a credential, and it keeps GitHub tokens.
- Not every combination of short Git flags is caught, for example `-amn` for `commit -n`.
- With `includeGitInstructions` off, commit and pull request behaviour depends entirely on `rules/git.md`. Replace it with an equivalent before removing it.
- A project can set `disableAllHooks` in its own settings, which would also switch off the hooks from the user settings. This follows from the order in which Claude Code resolves the key and is not confirmed. Do not trust the hooks in a repository under someone else's control.
- Untested: a signed commit with `~/.gnupg` denied in the sandbox.

## Licence

ISC, see [LICENSE](LICENSE).

[Buy me a coffee](https://ko-fi.com/jarovarga/tip)
