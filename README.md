# Claude Code configuration

`ccc` is a user-level [Claude Code](https://code.claude.com) configuration: pinned settings, a sandbox, lean instructions and binding rules.

It has three goals. Sessions cost fewer tokens. Claude cannot read secrets or rewrite Git history. And it behaves the same on every machine, which is why every value in `settings.json` is set explicitly, even where it matches today's default. Defaults change between releases.

Apart from British English (see [Instructions](#instructions)), nothing that loads on its own is tied to a project, a framework or personal taste. Those things belong in the project or in `opt-in/`, which holds the author's own conventions and framework setups and never loads on its own, and [Per-project settings](#per-project-settings) shows the usual additions. JSON has no comments, so this README is where the reasoning lives.

## Contents

| Path | Purpose |
| --- | --- |
| `settings.json` | Model, context, permissions, sandbox, hooks and skills. |
| `CLAUDE.md` | Instructions loaded in every session. |
| `RTK.md` | How to work with the RTK hook; imported by `CLAUDE.md`. |
| `rules/agent.md`, `rules/code.md`, `rules/git.md`, `rules/security.md` | General rules, loaded in every session. |
| `rules/instructions.md` | Rules for writing agent instructions, loaded only for instruction files. |
| `rules/stack/` | One file per language or tool, loaded only for matching files. |
| `opt-in/` | Optional rules and settings to copy into a project; never installed into `~/.claude/`. |

## Requirements

- Claude Code 2.1.290 or later. Older versions have holes in `blockReadsOutsideWorkingDirectories` (see [Permissions](#permissions)), and `minimumVersion` stops auto-updates from going below it.
- macOS. The sandbox uses Seatbelt and `network.allowLocalBinding` only does something there. Linux is untested.
- [RTK](https://rtk-ai.app) on `PATH` (`brew install rtk`). The settings register a hook that calls `rtk hook claude`, and without RTK that hook fails on every Bash call.
- [ripgrep](https://github.com/BurntSushi/ripgrep), because `CLAUDE.md` tells Claude to search with `rg`.
- The [GitHub CLI](https://cli.github.com) and [ShellCheck](https://shellcheck.net) are optional. They get used if they are there.

## After installation

Everything except `opt-in/` goes into `~/.claude/`, as user configuration. A few keys are ignored in project settings (`defaultMode: "auto"`, `autoContinueAtUsageLimit`, `syncClaudeAiSkills`), and a hook should not arrive through a repository anyway.

Create `~/.claude/LOCAL.md`, even an empty one, because `CLAUDE.md` imports it (see [Personal instructions](#personal-instructions)). Then start a new session and check three things:

1. Run `/skills` and compare the names with `skillOverrides`. They change between versions.
2. Ask Claude to read a `.env` file and to run `git push`. It must refuse both.
3. Ask Claude to run `printenv`. It must refuse that too, which also shows that the `deny` rules still match after the RTK hook has rewritten the command.

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
| `effortLevel` | `medium` | Enough thinking for everyday work. Raise it for a hard task with `/effort`. |
| `fastMode` | `false` | Fast mode costs more per token, so it stays an explicit choice. |
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
| `enableArtifact` | `false` | Turns the Artifact tool off, so a session cannot publish anything to claude.ai. |
| `remoteControlAtStartup` | `false` | A session is never exposed remotely by default. Left unset, the organisation default applies. |
| `syncClaudeAiSkills` | `false` | A new machine gets the skills from this configuration and nothing from the account. A repository cannot switch this off, so it has to be in user settings. |

### Git

| Key | Value | Why |
| --- | --- | --- |
| `attribution.commit`, `attribution.pr` | `""` | No trailers or credit lines in commits and pull requests. This only empties the default text, so `rules/git.md` forbids them as well. |
| `attribution.sessionUrl` | `false` | No link to a private claude.ai session. |
| `includeGitInstructions` | `false` | Removes the built-in commit and pull request instructions from the system prompt. `rules/git.md` replaces them, and it is shorter. |

### Maintenance

| Key | Value | Why |
| --- | --- | --- |
| `autoUpdatesChannel` | `stable` | About a week behind, and it skips releases with serious regressions. Homebrew installs ignore this key. |
| `cleanupPeriodDays` | `14` | Transcripts contain tool output and everything pasted into a session, mistakes included, so they are kept for two weeks instead of the default 30 days. `/resume` and checkpoints expire with them. |
| `fileCheckpointingEnabled` | `true` | `/rewind` can restore a file to what it was before an edit. |
| `minimumVersion` | `2.1.290` | Auto-updates never install anything older than the baseline needs. |

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

There is one hook, `rtk hook claude`, on `PreToolUse` for `Bash`. RTK cuts the boilerplate out of command output and keeps errors and failures. The 10-second timeout is there because a hung hook would otherwise block Bash for 600 seconds.

A command hook runs with full user permissions. Read a hook before adding it.

### Permissions

`defaultMode: "auto"` lets a classifier look at commands and network requests before they run, so ordinary work is not interrupted by prompts. It only works from user settings. `disableBypassPermissionsMode: "disable"` makes `--dangerously-skip-permissions` do nothing.

`blockReadsOutsideWorkingDirectories: true` makes the file tools refuse reads outside the working directories in every permission mode, and the sandbox applies the same block to commands, so a session in one project cannot read another project or anything else in the home directory. The JSON schema at schemastore.org does not list the key yet and an editor flags it as not allowed; Claude Code has read it since 2.1.257. Before 2.1.290, some Bash commands in auto mode and `@`-mentions could still read outside the working directories, so that is the minimum version. To work on files elsewhere, such as `~/.claude/` itself, start the session there or add the directory with `/add-dir`. A directory that every session needs, such as a notes vault, goes into `permissions.additionalDirectories` in `~/.claude/settings.local.json`, so that the path stays out of this repository.

Rules are checked in the order `deny`, `ask`, `allow`, and the first match wins.

`allow` is almost empty. With the sandbox and `autoAllowBashIfSandboxed`, sandboxed commands run without a prompt already. It only lists two documentation hosts for `WebFetch`, which the sandbox does not cover. When adding more, avoid hosts that serve content written by users.

`ask` is for things that should not happen silently:

- `gh`, because it runs outside the sandbox (see [Sandbox](#sandbox)).
- Broad staging (`git add --all`, `-A`, `--update`, `-u`, `.`), `git checkout`, `git commit`, `git rm`, `git stash clear` and `git stash drop`.
- `rm`.
- Edits to Claude's own configuration: `.claude/`, `.mcp.json` and `.gitignore` in the project, and in `~/.claude/` the Markdown files, settings, `agents`, `commands`, `hooks`, `rules` and `skills`, plus `~/.claude.json`.
- `WebSearch`, because the query leaves the machine.

`deny` cannot be approved at all:

- A shell without a command (`bash`, `sh`, `zsh`, with or without `-s`), which is what `curl … | sh` ends in.
- `env` and `printenv`, so secrets in the environment do not end up in the context.
- `sudo`.
- Skipping Git hooks (`--no-verify` and its abbreviations, `commit -n`, `core.*` configuration, `git -c`) and Git that rewrites or destroys history (`push`, `reset`, `restore`, `rebase`, `filter-branch`, `clean`, `checkout --`, `branch -D`, forced `branch`, `switch` and `tag`, `commit --amend`, `reflog expire` and `delete`, `tag -d`, `update-ref`), each also as `git -C <path>`. Pushing is left to the user, for example with `! git push`.
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
| `excludedCommands` | `["gh *"]` | Lets the GitHub CLI run outside the sandbox. The `ask` rule still asks every time. |
| `failIfUnavailable` | `true` | If the sandbox cannot start, Claude Code exits instead of running without it. |
| `network.allowLocalBinding` | `true` | Development servers and tests can listen on ports. Set it to `false` where that is not needed. macOS only. |

### Worktrees

| Key | Value | Why |
| --- | --- | --- |
| `baseRef` | `head` | A worktree branches from local `HEAD`, so unpushed commits come along. The default, `fresh`, branches from `origin`. |
| `bgIsolation` | `worktree` | A background session cannot edit the main checkout until it is in a worktree. |

## Instructions

`CLAUDE.md` is loaded at the start of every session, so it is kept short. Imports do not make it cheaper, because an imported file loads together with the one that imports it.

Most of it is about context: search the narrowest path first, keep command output small, batch calls, and suggest a new conversation when a request has nothing to do with the current one. All of that keeps the context small, and the context is resent on every turn.

It also makes the files in `~/.claude/rules/` binding, so a task or a project cannot talk Claude out of the security and Git rules. There are two exceptions. A rule can defer to the project, as the rules do for commit conventions, formatter settings and the command runner. And a project's framework or coding standard wins over a rule in `rules/stack/`.

It asks Claude to read files with the Read tool instead of `cat`, because that is what loads the path-scoped rules.

The rest is working conventions: read the README and the configuration before editing, answer in the user's language, and write new documentation, comments and commit messages in British English. That last one is a preference, so change it to taste.

The final section tells Claude what to keep when a long conversation is summarised.

`RTK.md` is imported by `CLAUDE.md`. It tells Claude that RTK's filtered output is complete, how to get an elided part back with `rtk recall <hash>`, and when to bypass the filter. The RTK commands meant for the user are not in it, because they would cost tokens in every session:

- `rtk gain` and `rtk gain --history` show how many tokens RTK saved, in total and per command. Run them outside Claude Code; they fail in the sandbox.
- `rtk discover` finds past commands RTK could have shortened.
- `rtk telemetry status` shows whether RTK's optional telemetry is on.

### Personal instructions

`CLAUDE.md` also imports `LOCAL.md`, which is not in this repository. Put anything personal into `~/.claude/LOCAL.md`: a GitHub account, local paths, personal conventions. Imports in user-level files load without an approval dialog. The `.gitignore` here ignores everything it does not list, so a `LOCAL.md` in a checkout is never committed.

## Rules

Every rule is one imperative line in one file. A stack rule can narrow a general rule for its language, such as the pinned images of `docker.md`, and a framework rule can replace a stack rule.

### General rules

These four load in every session.

| File | Holds |
| --- | --- |
| `rules/agent.md` | How the agent works: what it needs permission for, planning, the working tree, debugging, verifying and reporting, review, evidence, communication. |
| `rules/code.md` | How code is written in any language: formatting, the scope of a change, design, comments, robustness, input and output, accessibility, testing. |
| `rules/git.md` | Commit only when asked and after approval, stage only what belongs to the task, no attribution, no skipped hooks, remote operations left to the user. |
| `rules/security.md` | Principles, credentials, dependencies, services and files. The principles follow the OWASP Secure Product Design Cheat Sheet. |

`rules/instructions.md` only loads for instruction files: `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `LOCAL.md`, `RTK.md`, anything in `.claude/` and the Markdown files in `rules/`. It asks for imperative wording and for every requirement to survive when instructions are revised.

### Stack rules

The files in `rules/stack/` have `paths` frontmatter, so they cost nothing until Claude touches a matching file.

| File | Loads for | Holds |
| --- | --- | --- |
| `bash.md` | `**/*.{bash,sh}` | Shell options, quoting, temporary files, secrets, confirmations, ShellCheck. |
| `css.md` | `**/*.css` | Cascade layers, tokens, layout, states and accessibility, hidden content, forced colours, motion, quality. |
| `docker.md` | `**/Dockerfile*`, `**/*.dockerfile`, `**/.dockerignore`, `**/compose*.{yml,yaml}`, `**/docker-compose*.{yml,yaml}` | Pinned images, build steps, Compose services, health checks, tool services. |
| `html.md` | `**/*.{html,twig}` | Semantics, attributes, links and buttons, forms, native widgets, accessibility, media, resources. |
| `javascript.md` | `**/*.{js,mjs}` | Modules, DOM, events, focus, motion, observers, timing, network. Written for the browser. |
| `markdown.md` | `**/*.{markdown,md}` | One line per paragraph, headings, inline code, placeholders, code blocks. |
| `php.md` | `**/*.php` | Types, classes, syntax, the standard library, strings and regular expressions, errors, deprecated forms, security. |
| `postgresql.md` | `**/*.sql` | Types and schema, constraints, indexes, migrations on live tables, queries. |

A few things to know about them:

- A rule that needs a minimum version says so, such as (8.4+) in `php.md` or (18+) in `postgresql.md`, and only applies when the project targets that version.
- `css.md`, `html.md` and `javascript.md` assume features that are [Baseline](https://developer.mozilla.org/docs/Glossary/Baseline/Compatibility) Widely available, unless the project declares other browser support.
- A stack rule loads when Claude reads a matching file with the Read tool, not when a command such as `cat` reads it (see [Instructions](#instructions)).
- The patterns match file names and extensions, not the directories of some project layout. So `html.md` does not load for templates written in PHP, and `postgresql.md` does not load for migrations written in another language. If a project needs that, widen `paths`, for example with `templates/**/*.php` or `**/migrations/**`.

Naming methodologies, formatting taste and library choices are left out of the stack rules. The author's own, such as BEM naming of classes, are in `opt-in/conventions/`; keep yours in `LOCAL.md` or in the project.

### Opt-in rules

`opt-in/` holds rules and settings that fit only some projects: conventions and framework setups. A project copies what it needs into its own `.claude/`, so they apply to that project alone. They are not under `rules/` and `CLAUDE.md` does not import them, so nothing in them loads on its own. Only `settings.json`, `CLAUDE.md`, `RTK.md` and `rules/` are installed into `~/.claude/`; `opt-in/` never is.

| Path | Holds |
| --- | --- |
| `opt-in/conventions/` | One rule file per convention. |
| `opt-in/frameworks/<framework>/` | `settings.json`, `rules/<framework>.md` and a `README.md` for each framework. |

Everything in `opt-in/` is the author's own rules, kept as a template for writing project rules. See `opt-in/README.md` for how to use them.

## Per-project settings

These go into the project's `.claude/settings.json`. Settings for a framework, and the rules that go with them, are in [Opt-in rules](#opt-in-rules).

```json
{
  "claudeMdExcludes": ["**/node_modules/**", "**/vendor/**"],
  "worktree": { "symlinkDirectories": ["node_modules", "vendor"] }
}
```

`claudeMdExcludes` keeps the `CLAUDE.md` files and rules of dependencies from loading, and `symlinkDirectories` saves copying large directories into every worktree.

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
- The environment can still be printed without `env` or `printenv`, for example with `export -p`.
- Not every combination of short Git flags is caught, for example `-amn` for `commit -n`.
- With `includeGitInstructions` off, commit and pull request behaviour depends entirely on `rules/git.md`. Replace it with an equivalent before removing it.
- Untested: what happens when `rtk` is missing, and a signed commit with `~/.gnupg` denied in the sandbox.

## Licence

ISC, see [LICENSE](LICENSE).

[Buy me a coffee](https://ko-fi.com/jarovarga/tip)
