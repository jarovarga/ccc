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

Automated tests:

```bash
tests/run.sh
```

> [!note]
> Check `debug.log` for the output of failed tests.

| Test | Checks |
| --- | --- |
| `limit.test.sh` | The always-loaded instructions stay within the size limit. |
| `register.test.sh` | Only registered commands run outside the sandbox or skip the prompt. |
| `settings.test.sh` | The security settings keep their values. |
| `statusline.test.sh` | The status line shows its fields, glyphs and colours. |

## Documentation

- [Agents](docs/agents.md): the subagents, with their purpose and frontmatter keys.
- [Settings](docs/settings.md): every key with its value and effect.
- [Status line](docs/statusline.md): the fields, glyphs and colours of the status line.

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

ISC, see [LICENSE](LICENSE).
