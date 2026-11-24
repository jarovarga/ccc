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

- A strict sandbox with a closed network and blocked credential files.
- Permission rules that deny credential reads and destructive commands, and ask before deletions.
- No attribution in commits and pull requests.
- Rules for agent workflow, Git, security and writing instructions.
- A status line with the model, the effort, the context and rate limit usage, and the session cost.
- A read-only `Explore` agent on Haiku that follows these rules.
- A `/session` command that saves the state of the work and resumes it in a new session.

## Contents

| Path | Purpose |
| --- | --- |
| `agents/` | Subagents that replace or extend the built-in ones. |
| `docs/` | Documentation of the configuration. |
| `hooks/` | Scripts that Claude Code runs itself, outside the conversation. |
| `opt-in/` | Optional topics, disabled by default, each with its own `README.md`. |
| `rules/` | Rules that Claude follows in every project, such as for workflow, Git and security. |
| `skills/` | Skills and slash commands that the user or Claude can start. |
| `tests/` | A quality assurance script for a live session and automated tests for the configuration. |
| `CLAUDE.md` | Instructions that Claude loads at the start of every session. |
| `settings.json` | User settings for permissions, the sandbox and the interface. |

## Compatibility

Requires Claude Code 2.1.330 or later and at least macOS 15 (Sequoia).

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
| [docs/agents.md](docs/agents.md) | The subagents, with their purpose and frontmatter keys. |
| [docs/opt-in.md](docs/opt-in.md) | The layout of the optional topics. |
| [docs/settings.md](docs/settings.md) | Every key with its value and effect. |
| [docs/statusline.md](docs/statusline.md) | The fields, glyphs and colours of the status line. |

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

ISC, see [LICENSE](LICENSE).
