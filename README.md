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

## Features

- A strict sandbox with a closed network and blocked credential files.
- Permission rules that deny credential reads and destructive Git and file commands, and ask before deletions and configuration edits.
- No attribution in commits and pull requests.
- Rules for agent workflow, Git, security and writing instructions.
- A status line with the model, the effort, the context and rate limit usage, and the session cost (requires `jq`).

## Tests

Quality assurance in Claude Code with this configuration instead of `~/.claude` (requires `jq`):

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

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## License

ISC, see [LICENSE](LICENSE).
