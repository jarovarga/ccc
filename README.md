# Claude Code Config (CCC)

```text
 ██████╗ ██████╗ ██████╗
██╔════╝██╔════╝██╔════╝
██║     ██║     ██║
██║     ██║     ██║
╚██████╗╚██████╗╚██████╗
 ╚═════╝ ╚═════╝ ╚═════╝
```

[![CI](https://github.com/jarovarga/ccc/actions/workflows/ci.yml/badge.svg)](https://github.com/jarovarga/ccc/actions/workflows/ci.yml)

A personal, user-level [Claude Code](https://code.claude.com) configuration.

> [!note]
> Built for the CLI. The desktop app loads the instructions and rules, but not the settings, skills or agents.

## Features

- A strict sandbox with a closed network and blocked credential files; it is the security boundary.
- Permission rules that deny credential reads and operations that cannot be undone, and ask before deletions and before commands run through a shell wrapper.
- Hooks that block Git commands which skip the Git hooks or set configuration for one command, and reading files through Bash, because only the Read tool loads path-scoped rules.
- Lower limits for compaction, tool output, web searches and subagents, so that the context and the cost of a session stay bounded.
- No features that act without a request, such as recaps, prompt suggestions, continuing after a usage limit, or Code Mode, whose scripts run outside the sandbox.
- Nothing synced from or published to the claude.ai account, and no attribution in commits and pull requests.
- Session transcripts kept for 14 days, as they can hold sensitive data.
- The built-in Git instructions turned off, as they conflict with the Git rules.
- Replies in the user's language; documentation, comments and commit messages in British English.
- Rules for agent workflow, Git, security and writing instructions.
- A status line with the model, the effort, the context and rate limit usage, and the session cost.
- A read-only `Explore` agent on Haiku that follows these rules.
- A `/session` command that saves the state of the work and resumes it in a new session.
- A `/remember` command that turns an instruction into a rule and adds it to the local rules after approval.

The [settings reference](https://code.claude.com/docs/en/settings-reference) describes each setting.

## Limitations

- Permission rules match the text of a command, so another form of it, such as an absolute path or `bash -lc`, gets past them; only the sandbox holds.
- An allow rule for a WebFetch domain also opens that domain to sandboxed commands.

## Contents

| Path | Purpose |
| --- | --- |
| `agents/` | Subagents that replace or extend the built-in ones. |
| `docs/` | Documentation of the configuration. |
| `hooks/` | Scripts that Claude Code runs itself, outside the conversation, and in `hooks/lib/` the library that the Bash hooks share. |
| `opt-in/` | Optional topics to add as needed, each with its own `README.md`. |
| `rules/` | Rules that Claude follows in every project, such as for workflow, Git and security. |
| `skills/` | Skills and slash commands that the user or Claude can start. |
| `tests/` | A quality assurance script for a live session and automated tests for the configuration. |
| `CLAUDE.md` | Instructions that Claude loads at the start of every session. |
| `settings.json` | User settings for permissions, the sandbox and the interface. |

## Local rules

`rules/local/` holds rules of your own, such as personal preferences or settings of one machine.

- `local.md` starts empty and loads in every session.
- A rule for some files only goes into its own file with `paths`.
- Claude can edit the directory, but every edit prompts first.
- `/remember` writes new rules there.

> [!warning]
> When updating `~/.claude/rules/` from the repository, do not overwrite your own `local/` with the empty one.

## Compatibility

Requires Claude Code 2.1.332 or later and at least macOS 15 (Sequoia). Updates install no older version, but an older one still starts.

## Tests

Quality assurance in Claude Code with this configuration instead of `~/.claude`:

```bash
tests/qa.sh
```

Automated tests (each named after what it checks):

```bash
tests/run.sh
```

> [!note]
> Check `debug.log` for the output of failed tests.

## Documentation

| Path | Purpose |
| --- | --- |
| [docs/opt-in.md](docs/opt-in.md) | The layout of the optional topics. |
| [docs/ssh.md](docs/ssh.md) | A persistent SSH agent on macOS and SSH commit signing that work in the sandbox. |
| [docs/statusline.md](docs/statusline.md) | The fields, glyphs and colours of the status line. |

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

ISC, see [LICENSE](LICENSE).
